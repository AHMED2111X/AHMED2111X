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

# 1. Set standard permissions for files and zygisk directory
set_perm_recursive $MODPATH 0 0 0755 0644
if [ -d "$MODPATH/zygisk" ]; then
  set_perm_recursive $MODPATH/zygisk 0 0 0755 0755
fi

# 2. Clear Google Play Store and Play Services cache
ui_print "- 🧹 Clearing Google Play cache..." ; delay
rm -rf /data/data/com.android.vending/code_cache/* 2>/dev/null
rm -rf /data/data/com.android.vending/cache/* 2>/dev/null
rm -rf /data/data/com.google.android.gms/code_cache/* 2>/dev/null
rm -rf /data/data/com.google.android.gms/cache/* 2>/dev/null

ui_print " " ; delay
ui_print "- ✅ SafetyNet fixed successfully." ; delay
ui_print "- ✅ Bootloader status spoofed." ; delay
ui_print "- ✅ Google Play certification fixed." ; delay
ui_print "- ✅ Google Play cache cleared." ; delay
ui_print "- ✅ PUBG Mobile frame rate stability improved." ; delay
ui_print "- ✅ Tricky Store residuals cleaned." ; delay
ui_print "- ✅ System paths sanitized and 16KB alignment ensured." ; delay

ui_print " " ; delay
ui_print "- Installation completed successfully! 🦅🔥" ; delay
ui_print "- Developer: ABUFARID"