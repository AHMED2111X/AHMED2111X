#!/system/bin/sh
MODDIR=${0%/*}

# --- Auxiliary Functions for Safe Property Spoofing ---
resetprop_if_diff() {
    local PROP="$1"
    local EXPECTED="$2"
    local CURRENT=$(getprop "$PROP")
    if [ -n "$CURRENT" ] && [ "$CURRENT" != "$EXPECTED" ]; then
        resetprop -n "$PROP" "$EXPECTED"
    fi
}

resetprop_if_match() {
    local PROP="$1"
    local MATCH="$2"
    local TARGET="$3"
    local CURRENT=$(getprop "$PROP")
    if [ "$CURRENT" = "$MATCH" ]; then
        resetprop -n "$PROP" "$TARGET"
    fi
}

# --- Security Patches & Sensitive Props (Early Stage) ---
novo_patch="2026-03-05"
resetprop -n ro.build.version.security_patch "$novo_patch"
resetprop -n ro.vendor.build.security_patch "$novo_patch"

# Magisk Recovery Mode Protection
resetprop_if_match ro.boot.mode recovery unknown
resetprop_if_match ro.bootmode recovery unknown
resetprop_if_match vendor.boot.mode recovery unknown

# SELinux Protection
resetprop_if_diff ro.boot.selinux enforcing
if [ -f /sys/fs/selinux/enforce ] && [ "$(toybox cat /sys/fs/selinux/enforce 2>/dev/null)" = "0" ]; then
    chmod 640 /sys/fs/selinux/enforce
    chmod 440 /sys/fs/selinux/policy
fi

# --- 1. Enable Injection Engine ---
if [ -f "$MODDIR/inject" ]; then
    chmod 755 "$MODDIR/inject"
    "$MODDIR/inject" &
fi

# Create base security path
mkdir -p /data/adb/tricky_store
chmod 755 /data/adb/tricky_store
chown root:root /data/adb/tricky_store

# --- 2. Manage and Clean Keybox Files ---
rm -f /data/adb/tricky_store/keybox.xml.bak
rm -f /data/adb/tricky_store/*.bak
rm -f /data/adb/tricky_store/*.tmp

if [ -f "$MODDIR/keybox.xml" ]; then
    cp "$MODDIR/keybox.xml" /data/adb/tricky_store/keybox.xml
    chmod 644 /data/adb/tricky_store/keybox.xml
    chown root:root /data/adb/tricky_store/keybox.xml
    chcon u:object_r:system_file:s0 /data/adb/tricky_store/keybox.xml 2>/dev/null
fi

# --- 3. Enable Performance Options ---
settings put system min_refresh_rate 165.0
settings put system peak_refresh_rate 165.0
setprop windowsmgr.max_events_per_sec 300

# --- 4. Auto-Hide Newly Installed Packages & Clean Backup Files ---
(
    while [ "$(getprop sys.boot_completed)" != "1" ]; do 
        sleep 3
    done

    TARGET_FILE="/data/adb/tricky_store/target.txt"
    touch "$TARGET_FILE"

    # Cache current package list
    KNOWN_PACKAGES_FILE="/data/adb/falcon_known_packages.txt"
    pm list packages | cut -d':' -f2 | sort -u > "$KNOWN_PACKAGES_FILE"

    # Add all current packages to target.txt once at boot if missing
    cat "$KNOWN_PACKAGES_FILE" >> "$TARGET_FILE"
    sort -u "$TARGET_FILE" -o "$TARGET_FILE"

    while true; do
        sleep 5

        # Cleanup any .bak or .tmp files created by TrickyStore automatically
        rm -f /data/adb/tricky_store/*.bak 2>/dev/null
        rm -f /data/adb/tricky_store/*.tmp 2>/dev/null

        # Fetch latest packages
        CURRENT_PACKAGES=$(pm list packages | cut -d':' -f2 | sort -u)
        
        # Check for new packages installed
        NEW_PACKAGES=$(comm -13 "$KNOWN_PACKAGES_FILE" <(echo "$CURRENT_PACKAGES"))

        if [ -n "$NEW_PACKAGES" ]; then
            for pkg in $NEW_PACKAGES; do
                if ! grep -q "^$pkg$" "$TARGET_FILE"; then
                    echo "$pkg" >> "$TARGET_FILE"
                fi
            done
            # Refresh known packages list
            echo "$CURRENT_PACKAGES" > "$KNOWN_PACKAGES_FILE"
            chmod 644 "$TARGET_FILE"
        fi
    done
) &

# --- 5. Real-time Status, Bootloader & Online Users Checker ---
SERVER_URL="https://falcon-counter-server.onrender.com"

DEVICE_ID_FILE="/data/adb/falcon_device_id"
if [ ! -f "$DEVICE_ID_FILE" ]; then
    cat /proc/sys/kernel/random/uuid > "$DEVICE_ID_FILE" 2>/dev/null || echo "dev_$RANDOM" > "$DEVICE_ID_FILE"
fi
DEVICE_ID=$(cat "$DEVICE_ID_FILE")

(
    # Wait for full system boot
    while [ "$(getprop sys.boot_completed)" != "1" ]; do 
        sleep 2
    done

    # --- OEM Specific Fixes (SafetyNet / Play Integrity / Fingerprint Fixes) ---
    resetprop_if_diff ro.secureboot.lockstate locked
    resetprop_if_diff ro.boot.flash.locked 1
    resetprop_if_diff ro.boot.realme.lockstate 1
    resetprop_if_diff ro.boot.vbmeta.device_state locked
    resetprop_if_diff vendor.boot.verifiedbootstate green
    resetprop_if_diff ro.boot.verifiedbootstate green
    resetprop_if_diff ro.boot.veritymode enforcing
    resetprop_if_diff sys.oem_unlock_allowed 0

    while true; do
        # Check Zygisk Injection Status (🟢 مفعل - 🔴 غير مفعل)
        if [ -p /dev/socket/zygisk ] || [ -d "/data/adb/modules/zygisk_next" ] || pgrep -f "zygisk" >/dev/null 2>&1; then
            ZYGISK_STATUS="🟢 Zygisk Injecting"
        else
            ZYGISK_STATUS="🔴 Zygisk Not Injecting"
        fi

        # Check Bootloader Status (🟢 موهّم/آمن - 🔴 غير موهّم/غير آمن)
        if [ -f "/data/adb/tricky_store/keybox.xml" ] && [ -s "/data/adb/tricky_store/keybox.xml" ]; then
            BL_STATUS="🟢 BL Spoofed"
        else
            BL_STATUS="🔴 BL Unspoofed"
        fi

        # Get Online Users Count
        ONLINE_USERS="1"
        if command -v curl >/dev/null 2>&1; then
            RESPONSE=$(curl -s --connect-timeout 1 -X POST -H "Content-Type: application/json" -d "{\"deviceId\":\"$DEVICE_ID\"}" "$SERVER_URL/ping")
        elif command -v wget >/dev/null 2>&1; then
            RESPONSE=$(wget -qO- --timeout=1 --post-data="{\"deviceId\":\"$DEVICE_ID\"}" --header="Content-Type: application/json" "$SERVER_URL/ping")
        fi

        FETCHED_COUNT=$(echo "$RESPONSE" | grep -o '"onlineUsers":[0-9]*' | cut -d':' -f2)
        if [ -n "$FETCHED_COUNT" ]; then
            ONLINE_USERS="$FETCHED_COUNT"
        fi

        # Update description dynamically using User Logo 👤
        NEW_DESC="$ZYGISK_STATUS | $BL_STATUS | 👤 Online: $ONLINE_USERS"

        TARGET_PROP="/data/adb/modules/falcon_integrity_fix/module.prop"
        if [ -f "$TARGET_PROP" ]; then
            sed -i "s/^description=.*/description=$NEW_DESC/g" "$TARGET_PROP"
        fi
        
        if [ -f "$MODDIR/module.prop" ]; then
            sed -i "s/^description=.*/description=$NEW_DESC/g" "$MODDIR/module.prop"
        fi

        sleep 1
    done
) &