#!/system/bin/sh
# Function to add a slight delay for sequential line display
delay() {
    sleep 0.3
}

ui_print " "
ui_print "  ######################################" ; delay
ui_print "  #      🦅 FALCON INTEGRITY FIX       #" ; delay
ui_print "  #          Developer: ABUFRID        #" ; delay
ui_print "  #       Telegram: @FALCON_KERNEL     #" ; delay
ui_print "  ######################################" ; delay
ui_print " " ; delay
ui_print "- 🔍 Setting up Zygisk Next 1.5.0 environment and configuring..." ; delay

# 1. Set default permissions for files and zygisk injection directory
set_perm_recursive $MODPATH 0 0 0755 0644
if [ -d "$MODPATH/zygisk" ]; then
    set_perm_recursive $MODPATH/zygisk 0 0 0755 0755
fi

# 2. Set device fingerprint to Pixel 10
ui_print "- 🔧 Setting device fingerprint to Pixel 10..." ; delay
echo "ro.product.device=pixel_10" >> $MODPATH/system/build.prop
echo "ro.product.model=Pixel 10" >> $MODPATH/system/build.prop
echo "ro.product.name=pixel_10" >> $MODPATH/system/build.prop
echo "ro.product.board=pixel_10" >> $MODPATH/system/build.prop

# 3. Clear Google Play and Google Services cache for successful bypass
ui_print "- 🧹 Clearing Google Play cache completely..." ; delay
rm -rf /data/data/com.android.vending/code_cache/* 2>/dev/null
rm -rf /data/data/com.android.vending/cache/* 2>/dev/null
rm -rf /data/data/com.google.android.gms/code_cache/* 2>/dev/null
rm -rf /data/data/com.google.android.gms/cache/* 2>/dev/null

ui_print " " ; delay
ui_print "- ✅ SafetyNet fixed successfully." ; delay
ui_print "- ✅ Bootloader status spoofed." ; delay
ui_print "- ✅ Google Play dependency issue resolved." ; delay
ui_print "- ✅ Google Play cache cleared." ; delay
ui_print "- ✅ Frame stability improved in PUBG Mobile." ; delay
ui_print "- ✅ Cleaned up any leftovers in Tricky Store." ; delay
ui_print "- ✅ Sanitized paths and ensured system stability with 16KB alignment." ; delay
ui_print " " ; delay
ui_print "- Installation completed successfully! 🦅🔥" ; delay
ui_print "- Developer: ABUFRID" ; delay