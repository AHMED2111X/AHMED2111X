#!/system/bin/sh
set +e

# ==============================================================================
# إصلاح فحص الحماية FALCON INTEGRITY FIX - سكربت الخدمة
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
# ==============================================================================

MODPATH="${0%/*}"
MODDIR="$MODPATH"

if [ -f "$MODPATH/sepolicy.rule" ]; then
    magisk policy --live --file "$MODPATH/sepolicy.rule" 2>/dev/null
fi

chcon u:object_r:system_file:s0 "$MODPATH/service.sh" 2>/dev/null
chmod 755 "$MODPATH/service.sh" 2>/dev/null

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

CURRENT_YEAR_MONTH=$(date +%Y-%m 2>/dev/null)
if [ -n "$CURRENT_YEAR_MONTH" ]; then
    novo_patch="${CURRENT_YEAR_MONTH}-05"
else
    novo_patch="2026-10-05"
fi

resetprop -n ro.build.version.security_patch "$novo_patch"
resetprop -n ro.vendor.build.security_patch "$novo_patch"

mkdir -p /data/adb/tricky_store
chmod 755 /data/adb/tricky_store
chown root:root /data/adb/tricky_store

TRICKY_PATCH_FILE="/data/adb/tricky_store/security_patch.txt"
echo "all=$novo_patch" > "$TRICKY_PATCH_FILE"
chmod 644 "$TRICKY_PATCH_FILE" 2>/dev/null
chown root:root "$TRICKY_PATCH_FILE" 2>/dev/null

resetprop_if_match ro.boot.mode recovery unknown
resetprop_if_match ro.bootmode recovery unknown
resetprop_if_match vendor.boot.mode recovery unknown

resetprop_if_diff ro.boot.selinux enforcing
if [ "$SKIPDELPROP" != "true" ]; then
    delprop_if_exist ro.build.selinux
fi

if [ -f /sys/fs/selinux/enforce ] && [ "$(toybox cat /sys/fs/selinux/enforce 2>/dev/null)" = "0" ]; then
    chmod 640 /sys/fs/selinux/enforce 2>/dev/null
    chmod 440 /sys/fs/selinux/policy 2>/dev/null
fi

if [ -f "$MODDIR/inject" ]; then
    chmod 755 "$MODDIR/inject"
    "$MODDIR/inject" &
fi

rm -f /data/adb/tricky_store/keybox.xml 2>/dev/null
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

(
    while [ "$(getprop sys.boot_completed)" != "1" ]; do 
        sleep 3
    done

    TARGET_FILE="/data/adb/tricky_store/target.txt"
    touch "$TARGET_FILE"

    KNOWN_PACKAGES_FILE="/data/adb/falcon_known_packages.txt"
    pm list packages | cut -d':' -f2 | sort -u > "$KNOWN_PACKAGES_FILE"

    cat "$KNOWN_PACKAGES_FILE" >> "$TARGET_FILE"
    sort -u "$TARGET_FILE" > "$TARGET_FILE.tmp" 2>/dev/null
    if [ -s "$TARGET_FILE.tmp" ]; then
        mv -f "$TARGET_FILE.tmp" "$TARGET_FILE"
    else
        rm -f "$TARGET_FILE.tmp" 2>/dev/null
    fi

    while true; do
        sleep 10

        rm -f /data/adb/tricky_store/*.bak 2>/dev/null
        rm -f /data/adb/tricky_store/*.tmp 2>/dev/null

        CURRENT_PACKAGES=$(pm list packages | cut -d':' -f2 | sort -u)
        NEW_PACKAGES=$(comm -13 "$KNOWN_PACKAGES_FILE" <(echo "$CURRENT_PACKAGES"))

        if [ -n "$NEW_PACKAGES" ]; then
            for pkg in $NEW_PACKAGES; do
                if ! grep -q "^$pkg$" "$TARGET_FILE"; then
                    echo "$pkg" >> "$TARGET_FILE"
                fi
            done
            echo "$CURRENT_PACKAGES" > "$KNOWN_PACKAGES_FILE"
            chmod 644 "$TARGET_FILE" 2>/dev/null
        fi
    done
) &

SERVER_URL="https://falcon-counter-server.onrender.com"
COUNT_CACHE_FILE="/data/adb/falcon_online_count"
[ ! -f "$COUNT_CACHE_FILE" ] && echo "1" > "$COUNT_CACHE_FILE"

DEVICE_ID_FILE="/data/adb/falcon_device_id"
if [ ! -f "$DEVICE_ID_FILE" ]; then
    cat /proc/sys/kernel/random/uuid > "$DEVICE_ID_FILE" 2>/dev/null || echo "dev_$RANDOM" > "$DEVICE_ID_FILE"
fi
DEVICE_ID=$(cat "$DEVICE_ID_FILE")

(
    while [ "$(getprop sys.boot_completed)" != "1" ]; do 
        sleep 2
    done

    while true; do
        TS=$(date +%s 2>/dev/null || echo "$RANDOM")
        PING_URL="${SERVER_URL}/ping?t=${TS}"
        RESPONSE=""

        if command -v curl >/dev/null 2>&1; then
            RESPONSE=$(curl -s -H "Cache-Control: no-cache" --connect-timeout 10 --max-time 30 -X POST -H "Content-Type: application/json" -d "{\"deviceId\":\"$DEVICE_ID\"}" "$PING_URL" 2>/dev/null)
        elif command -v wget >/dev/null 2>&1; then
            RESPONSE=$(wget -qO- --no-cache --timeout=30 --post-data="{\"deviceId\":\"$DEVICE_ID\"}" --header="Content-Type: application/json" "$PING_URL" 2>/dev/null)
        fi

        FETCHED_COUNT=""
        if [ -n "$RESPONSE" ]; then
            FETCHED_COUNT=$(echo "$RESPONSE" | tr -d ' ' | grep -o '"onlineUsers":[0-9]*' | cut -d':' -f2 2>/dev/null)
        fi
        
        # حماية ضد المشاكل اللغوية (Syntax Errors)
        if [ -n "$FETCHED_COUNT" ] && [ "$FETCHED_COUNT" -gt 0 ] 2>/dev/null; then
            echo "$FETCHED_COUNT" > "$COUNT_CACHE_FILE"
        fi

        sleep 8
    done
) &

(
    while [ "$(getprop sys.boot_completed)" != "1" ]; do 
        sleep 2
    done

    resetprop_if_diff ro.secureboot.lockstate locked
    resetprop_if_diff ro.boot.flash.locked 1
    resetprop_if_diff ro.boot.realme.lockstate 1
    resetprop_if_diff ro.boot.vbmeta.device_state locked
    resetprop_if_diff vendor.boot.vbmeta.device_state locked
    resetprop_if_diff vendor.boot.verifiedbootstate green
    resetprop_if_diff ro.boot.verifiedbootstate green
    resetprop_if_diff ro.boot.vendor.boot.verifiedbootstate green
    resetprop_if_diff ro.vendor.boot.verifiedbootstate green
    resetprop_if_diff ro.boot.veritymode enforcing
    resetprop_if_diff sys.oem_unlock_allowed 0
    resetprop_if_diff ro.boot.warranty_bit 0
    resetprop_if_diff ro.warranty_bit 0
    resetprop_if_diff ro.secure 1
    resetprop_if_diff ro.debuggable 0
    resetprop_if_diff ro.build.type user
    resetprop_if_diff ro.build.tags release-keys

    while true; do
        ZYGISK_FOUND=false
        
        for pid in $(pidof zygote zygote64 2>/dev/null); do
            if grep -qi "zygisk" /proc/$pid/maps 2>/dev/null; then
                ZYGISK_FOUND=true
                break
            fi
        done

        if [ "$ZYGISK_FOUND" = "false" ]; then
            if ls /dev/socket/*zygisk* >/dev/null 2>&1; then
                ZYGISK_FOUND=true
            fi
        fi

        if [ "$ZYGISK_FOUND" = "false" ]; then
            for mod in /data/adb/modules/*zygisk*; do
                if [ -d "$mod" ] && [ ! -f "$mod/disable" ]; then
                    ZYGISK_FOUND=true
                    break
                fi
            done
        fi

        if [ "$ZYGISK_FOUND" = "true" ]; then
            ZYGISK_STATUS="🟢 Zygisk Injected"
        else
            ZYGISK_STATUS="🔴 Zygisk Not Injecting"
        fi

        KEYBOX_FILE="/data/adb/tricky_store/keybox.xml"
        if [ -s "$KEYBOX_FILE" ] || [ -f "/data/adb/tricky_store/target.txt" ] || \
           [ "$(getprop ro.boot.verifiedbootstate 2>/dev/null)" = "green" ] || \
           [ "$(getprop ro.boot.flash.locked 2>/dev/null)" = "1" ]; then
            BL_STATUS="🟢 BL Spoofed"
        else
            BL_STATUS="🔴 BL Unspoofed"
        fi

        ONLINE_USERS=$(cat "$COUNT_CACHE_FILE" 2>/dev/null || echo "0")
        NEW_DESC="$ZYGISK_STATUS | $BL_STATUS | 👤 Online: $ONLINE_USERS"

        for prop_file in "$MODDIR/module.prop" "/data/adb/modules/falcon_integrity_fix/module.prop" "/data/adb/modules/FALCON_INTEGRITY_FIX/module.prop"; do
            if [ -f "$prop_file" ]; then
                sed -i "s|^description=.*|description=$NEW_DESC|g" "$prop_file" 2>/dev/null
            fi
        done

        sleep 4
    done
) &