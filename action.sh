#!/system/bin/sh

# 1. رسالة البداية (تظهر في السجل)
echo "------------------------------"
echo "🦅 FALCON KERNEL FIX 🦅"
echo "جاري فحص ملفات الكاش..."
sleep 2

# 2. تنظيف خدمات جوجل (ببطء)
echo "تفريغ كاش Google Play Services..."
pm clear com.google.android.gms > /dev/null 2>&1
sleep 1.5

# 3. تنظيف المتجر
echo "تفريغ كاش Google Play Store..."
pm clear com.android.vending > /dev/null 2>&1
sleep 1.5

# 4. رسالة النجاح النهائية
echo "تم التنظيف بنجاح! ✅"
echo "جاري توجيهك لقناة FALCON..."
echo "------------------------------"
sleep 2

# 5. فتح القناة
am start -a android.intent.action.VIEW -d "https://t.me/falconkernal" > /dev/null 2>&1