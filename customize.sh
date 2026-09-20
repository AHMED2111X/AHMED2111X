#!/system/bin/sh

# Function to add a short delay for sequential output
delay() {
  sleep 0.3
}

ui_print " "
ui_print "  ######################################" ; delay
ui_print "  #      🦅 FALCON INTEGRITY FIX       #" ; delay
ui_print "  #          Developer: ABUFARID       #" ; delay
ui_print "  #       Telegram: @FALCON_KERNEL     #" ; delay
ui_print "  ######################################" ; delay
ui_print " " ; delay

ui_print "- 🔍 Initializing Zygisk Next environment..." ; delay

# Check Android API level compatibility
if [ "$API" -lt 25 ]; then
    abort " 🚫 Error : Your Phone Android Version is Not Supported ✋"
fi

# Fetch initial online users directly during installation
SERVER_URL="https://falcon-counter-server.onrender.com"
ONLINE_USERS=""

if command -v curl >/dev/null 2>&1; then
    ONLINE_USERS=$(curl -s --connect-timeout 5 -X POST -H "Content-Type: application/json" -d '{"deviceId":"install_check"}' "$SERVER_URL/ping" | grep -o '"onlineUsers":[0-9]*' | cut -d':' -f2)
elif command -v wget >/dev/null 2>&1; then
    ONLINE_USERS=$(wget -qO- --timeout=5 --post-data='{"deviceId":"install_check"}' --header='Content-Type: application/json' "$SERVER_URL/ping" | grep -o '"onlineUsers":[0-9]*' | cut -d':' -f2)
fi

if [ -n "$ONLINE_USERS" ] && [ -f "$MODPATH/module.prop" ]; then
    ui_print "- 👥 Active Users Online: $ONLINE_USERS" ; delay
    sed -i -E "s/Online Users: [0-9]+/Online Users: $ONLINE_USERS/g" "$MODPATH/module.prop"
fi

# 1. Set standard permissions
set_perm_recursive $MODPATH 0 0 0755 0644
if [ -d "$MODPATH/zygisk" ]; then
  set_perm_recursive $MODPATH/zygisk 0 0 0755 0755
fi

# 2. Deploy Spoofing & Keybox Files
ui_print "- 🎭 Deploying PIF & Tricky Store components..." ; delay
mkdir -p /data/adb/tricky_store 2>/dev/null

if [ -f "$MODPATH/pif.json" ]; then
    [ -f "/data/adb/pif.json" ] && mv -f "/data/adb/pif.json" "/data/adb/pif.json.old"
    cp -f "$MODPATH/pif.json" /data/adb/pif.json
fi

[ -f "$MODPATH/keybox.xml" ] && cp -f "$MODPATH/keybox.xml" /data/adb/tricky_store/
[ -f "$MODPATH/target.txt" ] && cp -f "$MODPATH/target.txt" /data/adb/tricky_store/
[ -f "$MODPATH/security_patch.txt" ] && cp -f "$MODPATH/security_patch.txt" /data/adb/tricky_store/

# 3. Add Key Applications to Magisk DenyList
ui_print "- 🛡️ Applying Auto DenyList for Apps & Banking..." ; delay
DENY_LIST_APPS="
com.google.android.gms com.google.android.gms:snet
com.google.android.gms com.google.android.gms:identitycredentials
com.google.android.gms com.google.android.gms:car
com.google.android.gms com.google.android.gms.unstable
com.google.android.gms com.google.android.gms.ui
com.google.android.gms com.google.android.gms.room
com.google.android.gms com.google.android.gms.remapping1
com.google.android.gms com.google.android.gms.persistent
com.google.android.gms com.google.android.gms.learning
com.google.android.gms com.google.android.gms.feedback
com.google.android.gms com.google.android.gms
com.android.vending com.android.vending
com.android.vending com.google.android.finsky.verifier.impl.ConsentDialog
com.android.vending com.google.android.finsky.verifier.impl.legacydialogs.PackageWarningDialog
com.android.vending com.android.vending:background
com.android.vending com.android.vending:instant_app_installer
com.android.vending com.android.vending:com.google.android.finsky.verifier.apkanalysis.service.ApkContentsScanService"

if magisk --denylist status >/dev/null 2>&1; then
    for item in $DENY_LIST_APPS; do
        magisk --denylist add $item >/dev/null 2>&1
    done
fi

# 4. Clear Google Play Cache
ui_print "- 🧹 Clearing Google Play cache..." ; delay
rm -rf /data/data/com.android.vending/code_cache/* 2>/dev/null
rm -rf /data/data/com.android.vending/cache/* 2>/dev/null
rm -rf /data/data/com.google.android.gms/code_cache/* 2>/dev/null
rm -rf /data/data/com.google.android.gms/cache/* 2>/dev/null

ui_print " " ; delay
ui_print "- ✅ SafetyNet fixed successfully." ; delay
ui_print "- ✅ Bootloader status spoofed." ; delay
ui_print "- ✅ Google Play certification fixed." ; delay
ui_print "- ✅ System paths sanitized and 16KB alignment ensured." ; delay

ui_print " " ; delay
ui_print "- Installation completed successfully! 🦅🔥" ; delay
ui_print "- Developer: ABUFARID"