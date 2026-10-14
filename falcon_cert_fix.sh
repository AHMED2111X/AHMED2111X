#!/system/bin/sh

# ==============================================================================
# إصلاح فحص الحماية FALCON INTEGRITY FIX - إصلاح اعتماد الجهاز في جوجل بلاي
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
# ------------------------------------------------------------------------------
# الاستخدام:
#   su -c 'sh /data/adb/modules/falcon_integrity_fix/falcon_cert_fix.sh'
#       → يمسح بيانات متجر بلاي + خدمات جوجل (يكفي في معظم الحالات)
#
#   su -c 'sh /data/adb/modules/falcon_integrity_fix/falcon_cert_fix.sh --full'
#       → يمسح أيضاً بيانات إطار خدمات جوجل (GSF) = معرّف GSF جديد
#         (استخدمه فقط إذا فشل المسح العادي)
# ==============================================================================

set +o standalone 2>/dev/null
unset ASH_STANDALONE 2>/dev/null

MODE="$1"

echo "=========================================================="
echo "   FALCON - إصلاح اعتماد الجهاز في جوجل بلاي"
echo "=========================================================="
echo ""

echo "[➜] إيقاف تطبيقات جوجل قسرياً..."
for p in com.android.vending com.google.android.gms com.google.android.gsf com.google.android.gms.unstable; do
    am force-stop "$p" 2>/dev/null
done
sleep 2
echo "[✔] تم"
echo ""

echo "[➜] مسح بيانات متجر Google Play..."
pm clear com.android.vending 2>&1
echo ""

echo "[➜] مسح بيانات خدمات Google Play (GMS)..."
pm clear com.google.android.gms 2>&1
echo ""

if [ "$MODE" = "--full" ]; then
    echo "[➜] مسح بيانات إطار خدمات جوجل (GSF) — وضع كامل..."
    pm clear com.google.android.gsf 2>&1
    echo ""
    echo "[!] تم إنشاء معرّف GSF جديد — ستحتاج تسجيل الجهاز من جديد:"
    echo "    https://www.google.com/android/uncertified/"
    echo ""
fi

echo "[➜] إعادة إيقاف قسري بعد المسح..."
for p in com.android.vending com.google.android.gms; do
    am force-stop "$p" 2>/dev/null
done
echo ""

# محاولة قراءة معرّف GSF (يحتاج sqlite3 - قد لا يتوفر)
echo "----------------------------------------------------------"
echo " معرّف الجهاز (android_id) : $(settings get secure android_id 2>/dev/null)"
echo "----------------------------------------------------------"
echo ""
echo "الخطوات التالية:"
echo "  1) أعد تشغيل الجهاز الآن."
echo "  2) اتصل بالإنترنت وانتظر 10 - 20 دقيقة."
echo "  3) افتح المتجر ← الإعدادات ← حول ← تحقّق Play Protect."
echo ""
echo "إن بقي 'غير معتمد'، سجّل الجهاز هنا بعد الحصول على GSF ID:"
echo "  https://www.google.com/android/uncertified/"
echo ""
echo "=========================================================="

exit 0
