#!/system/bin/sh

# 1. رسالة البداية
echo "------------------------------"
echo "🦅 FALCON INTGRTY FIX 🦅"
echo "جاري فحص ملفات الكاش الذكي..."
sleep 2

# 2. تنظيف خدمات جوجل (بدون تسجيل خروج)
echo "تفريغ كاش Google Play Services..."
# نمسح المجلدات المؤقتة فقط بدلاً من pm clear
rm -rf /data/data/com.google.android.gms/cache/*
rm -rf /data/data/com.google.android.gms/code_cache/*
sleep 1.5

# 3. تنظيف المتجر (بدون تسجيل خروج)
echo "تفريغ كاش Google Play Store..."
# نمسح المجلدات المؤقتة فقط بدلاً من pm clear
rm -rf /data/data/com.android.vending/cache/*
rm -rf /data/data/com.android.vending/code_cache/*
sleep 1.5

# 4. تنظيف الكاش العام للنظام (إضافة اختيارية قوية)
echo "تنظيف الكاش العام للنظام..."
rm -rf /data/local/tmp/*
sleep 1

# 5. رسالة النجاح النهائية
echo "تم التنظيف الذكي بنجاح! ✅"
echo "حساباتك آمنة وجهازك أسرع الآن."
echo "جاري توجيهك لقناة FALCON..."
echo "------------------------------"
sleep 2

# 6. فتح القناة
am start -a android.intent.action.VIEW -d "https://t.me/falconkernal" > /dev/null 2>&1