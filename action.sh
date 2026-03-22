#!/system/bin/sh

# تحديد مسار الإضافة
MODDIR="/data/adb/modules/my_custom_pif"

# 1. رسالة ترحيبية تظهر في واجهة الروت (Terminal Output)
echo "================================"
echo "   مرحباً بك في إضافة FALCON KERNEL Fix   "
echo "   جاري تحديث النظام وتأمين  الحساب   "
echo "================================"
sleep 1

# 2. فتح قناة التيليجرام الخاصة بك (تأكد من وضع رابط قناتك هنا)
am start -a android.intent.action.VIEW -d "https://t.me/falconkernal"
echo "• تم توجيهك لقناة التحديثات الرسمية."
sleep 2

# 3. مسح كاش جوجل بلاي وخدمات جوجل لضمان قراءة البصمة الجديدة
echo "• جاري تنظيف مخلفات جوجل (Clean Cache)..."
pm clear com.android.vending > /dev/null 2>&1
pm clear com.google.android.gms > /dev/null 2>&1
pm clear com.google.android.gsf > /dev/null 2>&1

# 4. إعادة كتابة ملفات البصمة والكيبوكس لضمان استقرار الفحص
echo "• جاري تحديث ملفات Keybox و PIF..."
if [ -f "$MODDIR/pif.json" ]; then
    cp $MODDIR/pif.json /data/adb/pif.json
    chmod 644 /data/adb/pif.json
fi

if [ -f "$MODDIR/keybox.xml" ]; then
    mkdir -p /data/adb/tricky_store
    cp $MODDIR/keybox.xml /data/adb/tricky_store/keybox.xml
    chmod 644 /data/adb/tricky_store/keybox.xml
fi

# 5. رسالة النهاية
echo "--------------------------------"
echo "✅ تمت العملية بنجاح!"
echo "🛡️ جهازك الآن محمي وجاهز للعب (Safe Play)."
echo "🚀 استعد للوصول إلى الكونكر مع FALCON!"
echo "--------------------------------"