#!/system/bin/sh

# ==============================================================================
# FALCON INTEGRITY FIX - سكربت إزالة التثبيت والتنظيف
# المطور: ABUFARID
# ==============================================================================

# إزالة خاصية GMS من الذاكرة الحالية
if command -v resetprop >/dev/null 2>&1; then
    resetprop --delete persist.sys.spoof.gms 2>/dev/null
fi

# حذف ملف الخاصية الدائمة إن كان موجودًا
rm -f "/data/property/persist.sys.spoof.gms" 2>/dev/null

# حذف ملفات السجل الخاصة بالموديول
rm -f "/data/adb/modules/falcon_integrity_fix/falcon_integrity_fix.log" 2>/dev/null
rm -f "/data/adb/modules/falcon_integrity_fix/integrity_fix.log" 2>/dev/null

exit 0