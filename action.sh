#!/system/bin/sh

# 1. تنظيف الكاش (الأوامر الأساسية)
pm clear com.google.android.gms > /dev/null 2>&1
pm clear com.android.vending > /dev/null 2>&1

# 2. تنبيه المستخدم بالاهتزاز (Vibrate) 
# سيشعر المستخدم بهزة خفيفة في يده عند انتهاء المسح
input keyevent 26 && input keyevent 26 > /dev/null 2>&1
cmd isms vibrate 100 > /dev/null 2>&1

# 3. إظهار رسالة بسيطة في سجل الروت
echo "FALCON: CLEAN DONE ✅"

# 4. فتح رابط القناة الجديد
sleep 1
am start -a android.intent.action.VIEW -d "https://t.me/falconkernal" > /dev/null 2>&1