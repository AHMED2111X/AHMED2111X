#!/system/bin/sh
MODDIR=${0%/*}

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
rm -f /data/adb/tricky_store/keybox.xml
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

# --- 4. Real-time Status, Bootloader & Online Users Checker (1s Ultra-Fast Interval) ---
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

    while true; do
        # Check Zygisk Injection Status
        ZYGISK_STATUS="🔴 Not Injecting"
        if [ -p /dev/socket/zygisk ] || [ -d "/data/adb/modules/zygisk_next" ] || pgrep -f "zygisk" >/dev/null 2>&1; then
            ZYGISK_STATUS="🟢 Zygisk Active"
        fi

        # Check Strict Bootloader Spoofing Status (Turns Red if Keybox file is missing or empty)
        BL_STATUS="🔴 BL Unspoofed"
        if [ -f "/data/adb/tricky_store/keybox.xml" ] && [ -s "/data/adb/tricky_store/keybox.xml" ]; then
            BL_STATUS="🟢 BL Spoofed"
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

        # Update description dynamically in module.prop (Falcon icon moved next to Online)
        NEW_DESC="$ZYGISK_STATUS | $BL_STATUS | 🦅 Online: $ONLINE_USERS"

        TARGET_PROP="/data/adb/modules/falcon_integrity_fix/module.prop"
        if [ -f "$TARGET_PROP" ]; then
            sed -i -E "s/^description=.*/description=$NEW_DESC/g" "$TARGET_PROP"
        fi
        
        if [ -f "$MODDIR/module.prop" ]; then
            sed -i -E "s/^description=.*/description=$NEW_DESC/g" "$MODDIR/module.prop"
        fi

        # Ultra-fast refresh every 1 second
        sleep 1
    done
) &