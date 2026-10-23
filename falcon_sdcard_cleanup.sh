#!/system/bin/sh

# ==============================================================================
# FALCON INTEGRITY FIX — إخفاء بقايا الريكفري من مساحة المستخدم (v3.19)
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
#
# وجود مجلدات TWRP/OrangeFox الفارغة أو ملف .twrps على /sdcard دليل شائع عند
# كاشفات الروت على أن الجهاز دخل وضع الريكفري. تنظيف آمن غير مدمّر:
#   • نحذف فقط ملف .twrps ونتخلى (rmdir) عن المجلدات الفارغة تماماً.
#   • ⛔ لا نمس أي مجلد يحتوي نسخاً احتياطية أو ملفات — تبقى كما هي.
#
# الإيقاف: touch /data/adb/falcon/no_sdcard_cleanup
# ==============================================================================

[ -f /data/adb/falcon/no_sdcard_cleanup ] && exit 0

# --- الانتظار حتى يكتمل الإقلاع وتجهز مساحة التخزين ---
W=0
while [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ] && [ "$W" -lt 240 ]; do
    sleep 2
    W=$((W + 1))
done
sleep 15

SD="/sdcard"
[ -d "$SD" ] || SD="/storage/emulated/0"
[ -d "$SD" ] || exit 0

# ملف إعدادات TWRP (يُنشئه الريكفري عند أول دخول)
rm -f "$SD/.twrps" 2>/dev/null
rm -f "$SD/TWRP/.twrps" 2>/dev/null

# إزالة المجلدات الفارغة فقط — أي مجلد فيه نسخ احتياطية يبقى ولا يُمس
for D in TWRP Fox OrangeFox PBRP PitchBlack Recovery; do
    [ -d "$SD/$D" ] && rmdir "$SD/$D" 2>/dev/null
done

exit 0
