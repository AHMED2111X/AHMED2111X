#!/system/bin/sh

# ==============================================================================
# FALCON INTEGRITY FIX - SERVICE SCRIPT
# Developer: ABUFARID | Telegram: @FALCON_KERNEL
# ==============================================================================

MODPATH="${0%/*}"
MODDIR="$MODPATH"

# --- SELinux Policy Rules Application ---
if [ -f "$MODPATH/sepolicy.rule" ]; then
    magisk policy --live --file "$MODPATH/sepolicy.rule" 2>/dev/null || true
fi

chcon u:object_r:system_file:s0 "$MODPATH/service.sh" 2>/dev/null || true
chmod 755 "$MODPATH/service.sh" 2>/dev/null || true

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

delprop_if_exist() {
    local NAME="$1"
    [ -n "$(getprop "$NAME")" ] && resetprop --delete "$NAME" 2>/dev/null
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
if [ "$SKIPDELPROP" != "true" ]; then
    delprop_if_exist ro.build.selinux
fi

if [ -f /sys/fs/selinux/enforce ] && [ "$(toybox cat /sys/fs/selinux/enforce 2>/dev/null)" = "0" ]; then
    chmod 640 /sys/fs/selinux/enforce 2>/dev/null
    chmod 440 /sys/fs/selinux/policy 2>/dev/null
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
rm -f /data/adb/tricky_store/keybox.xml.bak 2>/dev/null
rm -f /data/adb/tricky_store/*.bak 2>/dev/null
rm -f /data/adb/tricky_store/*.tmp 2>/dev/null

KEYBOX_SRC=""
if [ -f "$MODDIR/keybox.xml" ]; then
    KEYBOX_SRC="$MODDIR/keybox.xml"
elif [ -f "$MODDIR/zygisk/keybox.xml" ]; then
    KEYBOX_SRC="$MODDIR/zygisk/keybox.xml"
fi

if [ -n "$KEYBOX_SRC" ]; then
    cp -f "$KEYBOX_SRC" /data/adb/tricky_store/keybox.xml
    chmod 644 /data/adb/tricky_store/keybox.xml
    chown root:root /data/adb/tricky_store/keybox.xml
    chcon u:object_r:system_file:s0 /data/adb/tricky_store/keybox.xml 2>/dev/null
fi

# --- 3. Enable Performance Options ---
settings put system min_refresh_rate 165.0 2>/dev/null
settings put system peak_refresh_rate 165.0 2>/dev/null
setprop windowsmgr.max_events_per_sec 300 2>/dev/null

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

    # Add all current packages to target.txt once at boot if missing safely
    cat "$KNOWN_PACKAGES_FILE" >> "$TARGET_FILE"
    sort -u "$TARGET_FILE" > "$TARGET_FILE.tmp" 2>/dev/null
    if [ -s "$TARGET_FILE.tmp" ]; then
        mv -f "$TARGET_FILE.tmp" "$TARGET_FILE"
    else
        rm -f "$TARGET_FILE.tmp" 2>/dev/null
    fi

    while true; do
        sleep 10

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
            chmod 644 "$TARGET_FILE" 2>/dev/null
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
    resetprop_if_diff vendor.boot.vbmeta.device_state locked
    resetprop_if_diff vendor.boot.verifiedbootstate green
    resetprop_if_diff ro.boot.verifiedbootstate green
    resetprop_if_diff ro.boot.veritymode enforcing
    resetprop_if_diff sys.oem_unlock_allowed 0

    LOOP_COUNTER=0
    ONLINE_USERS="1"

    while true; do
        # 🔍 فحص دقيق وحقيقي لحالة حقن الزيجسك (Zygisk Injection Status)
        if [ -p /dev/socket/zygisk ] || [ -S /dev/socket/zygiskd ] || pgrep -f "zygiskd" >/dev/null 2>&1 || pgrep -f "zygisk_next" >/dev/null 2>&1 || ([ -d "/data/adb/modules/zygisk_next" ] && [ ! -f "/data/adb/modules/zygisk_next/disable" ]); then
            ZYGISK_STATUS="🟢 Zygisk Injected"
        else
            ZYGISK_STATUS="🔴 Zygisk Not Injecting"
        fi

        # 🔍 فحص دقيق وحقيقي لحالة تمويه البوت لودر (Bootloader Spoofing Status)
        KEYBOX_FILE="/data/adb/tricky_store/keybox.xml"
        if [ -s "$KEYBOX_FILE" ] && grep -qi "Keybox" "$KEYBOX_FILE" 2>/dev/null; then
            BL_STATUS="🟢 BL Spoofed"
        else
            BL_STATUS="🔴 BL Unspoofed"
        fi

        # Fetch Online Users Count every 6 loops (~30 seconds) to conserve network & battery
        if [ $((LOOP_COUNTER % 6)) -eq 0 ]; then
            RESPONSE=""
            if command -v curl >/dev/null 2>&1; then
                RESPONSE=$(curl -s --connect-timeout 2 --max-time 3 -X POST -H "Content-Type: application/json" -d "{\"deviceId\":\"$DEVICE_ID\"}" "$SERVER_URL/ping" 2>/dev/null)
            elif command -v wget >/dev/null 2>&1; then
                RESPONSE=$(wget -qO- --timeout=3 --post-data="{\"deviceId\":\"$DEVICE_ID\"}" --header="Content-Type: application/json" "$SERVER_URL/ping" 2>/dev/null)
            fi

            FETCHED_COUNT=$(echo "$RESPONSE" | grep -o '"onlineUsers":[0-9]*' | cut -d':' -f2)
            if [ -n "$FETCHED_COUNT" ]; then
                ONLINE_USERS="$FETCHED_COUNT"
            fi
        fi

        # Update description dynamically using User Logo 👤
        NEW_DESC="$ZYGISK_STATUS | $BL_STATUS | 👤 Online: $ONLINE_USERS"

        TARGET_PROP="/data/adb/modules/falcon_integrity_fix/module.prop"
        if [ -f "$TARGET_PROP" ]; then
            sed -i "s|^description=.*|description=$NEW_DESC|g" "$TARGET_PROP"
        fi
        
        if [ -f "$MODDIR/module.prop" ]; then
            sed -i "s|^description=.*|description=$NEW_DESC|g" "$MODDIR/module.prop"
        fi

        LOOP_COUNTER=$((LOOP_COUNTER + 1))
        sleep 5
    done
) &

# --- 6. Auto-Sync KeyBox from GitHub (Every 30 Minutes) ---
(
    # Wait for full system boot and internet initialization
    while [ "$(getprop sys.boot_completed)" != "1" ]; do 
        sleep 5
    done

    KEYBOX_BASE_URL="https://raw.githubusercontent.com/AHMED2111X/AHMED2111X/main/keybox.xml"
    TARGET_KEYBOX="/data/adb/tricky_store/keybox.xml"
    TMP_KEYBOX="/data/adb/tricky_store/keybox.xml.tmp"

    while true; do
        # Generate timestamp query parameter to bypass GitHub raw CDN cache
        TIMESTAMP=$(date +%s 2>/dev/null || echo "$RANDOM")
        FRESH_KEYBOX_URL="${KEYBOX_BASE_URL}?t=${TIMESTAMP}"

        # Download keybox.xml from GitHub
        if command -v curl >/dev/null 2>&1; then
            curl -sSL -H "Cache-Control: no-cache" --connect-timeout 5 --max-time 10 -o "$TMP_KEYBOX" "$FRESH_KEYBOX_URL"
        elif command -v wget >/dev/null 2>&1; then
            wget -q --no-cache --timeout=10 -O "$TMP_KEYBOX" "$FRESH_KEYBOX_URL"
        fi

        # Verify downloaded file is valid and contains Keybox tag
        if [ -s "$TMP_KEYBOX" ] && grep -qi "Keybox" "$TMP_KEYBOX" 2>/dev/null; then
            # Replace file if GitHub file is new/different or target file is missing
            if ! cmp -s "$TMP_KEYBOX" "$TARGET_KEYBOX"; then
                # Delete old Keybox file completely from TrickyStore
                rm -f "$TARGET_KEYBOX"
                
                # Install new Keybox file directly
                mv -f "$TMP_KEYBOX" "$TARGET_KEYBOX"
                chmod 644 "$TARGET_KEYBOX"
                chown root:root "$TARGET_KEYBOX"
                chcon u:object_r:system_file:s0 "$TARGET_KEYBOX" 2>/dev/null
            else
                rm -f "$TMP_KEYBOX"
            fi
        else
            rm -f "$TMP_KEYBOX"
        fi

        # Sleep 30 minutes (1800 seconds)
        sleep 1800
    done
) &