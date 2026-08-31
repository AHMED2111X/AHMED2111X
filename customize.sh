#!/system/bin/sh

SKIPUNZIP=0

ui_print "*************************************"
ui_print "*     FALCON INTEGRITY FIX v2.40    *"
ui_print "*         By Author: ABUFARID       *"
ui_print "*************************************"

# التحقق من بيئة SUSFS
if [ -d "/data/adb/susfs4ksu" ] || [ -f "/data/adb/ksu/bin/susfs" ] || [ -d "/data/adb/sufs" ]; then
    ui_print "- SUSFS environment detected! Enabling full integration..."
else
    ui_print "- Standard Superuser environment detected."
fi

# التحقق من Zygisk Next
if [ -d "/data/adb/modules/zygisk_next" ]; then
    stream_zn=$(grep "version=" /data/adb/modules/zygisk_next/module.prop 2>/dev/null)
    ui_print "- Found Zygisk Next: ${stream_zn}"
    ui_print "- Applied compatibility layer for Zygisk Next 1.5.0+"
fi

# ضبط صلاحيات الملفات والسكريبتات وزر الأكشن
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm $MODPATH/service.sh 0 0 0755
set_perm $MODPATH/post-fs-data.sh 0 0 0755 2>/dev/null
set_perm $MODPATH/action.sh 0 0 0755

ui_print "- Installation completed successfully!"