#!/system/bin/sh

# ==============================================================================
# FALCON INTEGRITY FIX — إصلاح SOTER (خادم شهادات تينسنت لبعض تطبيقات الدفع)
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
#
# المشكلة: على بعض الأجهزة تتعطل خدمة vendor.soter فتظهر أخطاء «فشل التحقق
# من الجهاز» في تطبيقات الدفع/البنوك رغم سلامة كل شيء آخر.
# الحل (زر يدوي فقط — لا يعمل تلقائياً أبداً ولا عند الإقلاع):
#   إيقاف الخدمة → تصفير بيانات خادم SOTER فقط → إعادة تشغيلها (تهيئة جديدة
#   لمفاتيحها، بلا أي مساس ببيانات المستخدم أو أي تطبيق آخر).
#
# الاستخدام: sh soter_fix.sh   (أو من زر الواجهة)
# المخرجات: FALCON_SOTER=OK|NONE + FALCON_SOTER_DONE
# ==============================================================================

PKG="com.tencent.soter.soterserver"

echo "🔐 إصلاح SOTER — خادم شهادات تينسنت"
echo "------------------------------------"

if ! command -v pm >/dev/null 2>&1 || ! pm path "$PKG" >/dev/null 2>&1; then
    echo "ℹ️ التطبيق ($PKG) غير مثبّت على هذا الجهاز."
    echo "➜ لا حاجة للإصلاح — كل شيء سليم."
    echo "FALCON_SOTER=NONE"
    echo "FALCON_SOTER_DONE"
    exit 0
fi

echo "➜ إيقاف خدمة vendor.soter..."
stop vendor.soter 2>/dev/null
sleep 2

echo "➜ تصفير بيانات خادم SOTER (يعيد تهيئة المفاتيح فقط)..."
pm clear "$PKG" >/dev/null 2>&1

echo "➜ إعادة تشغيل خدمة vendor.soter..."
start vendor.soter 2>/dev/null
sleep 3

STATE="$(getprop init.svc.vendor.soter 2>/dev/null)"
case "$STATE" in
    running) echo "✅ الخدمة تعمل الآن — تم الإصلاح بنجاح." ;;
    "")      echo "✅ تمت إعادة التشغيل — الخدمة تُدار عبر النظام." ;;
    *)       echo "✅ تم تنفيذ الإصلاح (حالة الخدمة: $STATE)." ;;
esac
echo "➜ أعد فحص التطبيق الذي كان يواجه المشكلة."
echo "FALCON_SOTER=OK"
echo "FALCON_SOTER_DONE"
exit 0
