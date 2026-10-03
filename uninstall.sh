#!/system/bin/sh

# ==============================================================================
# إصلاح فحص الحماية FALCON INTEGRITY FIX - سكربت إزالة التثبيت والتنظيف
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
# ==============================================================================

# تنظيف وإلغاء خصائص تزييف خدمات جوجل (GMS Spoofing) الخاصة بنظام LeafOS إن وجدت
if [ -f /data/system/gms_certified_props.json ]; then
    resetprop -p --delete persist.sys.spoof.gms
fi

# تنظيف وحذف ملف سجلات إصلاح الحماية المؤقت
rm -f /data/adb/modules/integrity_fix/integrity_fix.log