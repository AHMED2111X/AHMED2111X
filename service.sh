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

# --- 3. Enable Max Performance ---
settings put system min_refresh_rate 165.0
settings put system peak_refresh_rate 165.0
setprop windowsmgr.max_events_per_sec 300