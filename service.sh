#!/system/bin/sh
MODDIR=${0%/*}
# --- 1. Enable Clean Injection Engine ---
# Check for the existence of the injection file and set permissions
if [ -f "$MODDIR/inject" ]; then
    chmod 755 "$MODDIR/inject"
    "$MODDIR/inject" &
fi
# Create the basic protection path
mkdir -p /data/adb/tricky_store
chmod 755 /data/adb/tricky_store
chown root:root /data/adb/tricky_store
# --- 2. Update Original Fingerprint (Pixel 9 Pro XL) ---
# To bypass Play Integrity check without conflict
if [ -f "$MODDIR/pif.json" ]; then
    cp "$MODDIR/pif.json" /data/adb/pif.json
    chmod 644 /data/adb/pif.json
    chown root:root /data/adb/pif.json
    chcon u:object_r:system_file:s0 /data/adb/pif.json 2>/dev/null
fi
# --- 3. Manage and Clean Keybox Files ---
# Delete all old and backup files to ensure clean replacement
rm -f /data/adb/tricky_store/keybox.xml
rm -f /data/adb/tricky_store/keybox.xml.bak
rm -f /data/adb/tricky_store/*.bak
rm -f /data/adb/tricky_store/*.tmp
# Copy the new keybox file and set permissions and SELinux context for Android 16
if [ -f "$MODDIR/keybox.xml" ]; then
    cp "$MODDIR/keybox.xml" /data/adb/tricky_store/keybox.xml
    chmod 644 /data/adb/tricky_store/keybox.xml
    chown root:root /data/adb/tricky_store/keybox.xml
    chcon u:object_r:system_file:s0 /data/adb/tricky_store/keybox.xml 2>/dev/null
fi
# --- 4. Enable Maximum Performance (Monster Mode) ---
# Enable 165 FPS and set maximum touch response
settings put system min_refresh_rate 165.0
settings put system peak_refresh_rate 165.0
setprop windowsmgr.max_events_per_sec 300

# --- 5. Set Device Fingerprint to Pixel 10 ---
# Set relevant system properties to match Pixel 10
setprop ro.product.device pixel_10
setprop ro.product.model Pixel\ 10
setprop ro.product.name pixel_10
setprop ro.product.board pixel_10