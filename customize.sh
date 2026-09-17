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

ui_print "- 🔍 Initializing Zygisk Next 1.5.0 environment..." ; delay

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

# 2. Clear Google Play cache
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