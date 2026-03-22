#!/system/bin/sh

# 1. مسح كاش خدمات جوجل وبلاي ستور
pm clear com.google.android.gms > /dev/null 2>&1
pm clear com.android.vending > /dev/null 2>&1

# 2. إظهار رسالة تأكيد للمستخدم (Toast)
# هذه الرسالة ستظهر أسفل الشاشة لثوانٍ
echo "تم تنظيف الكاش بنجاح بواسطة FALCON 🦅" > /dev/shm/falcon_msg
# تنبيه بصري سريع
am no-export-service-call-broadcast -a android.intent.action.MAIN --es msg "FALCON: تم مسح الكاش ✅"

# 3. انتظار ثانية واحدة لكي يرى المستخدم الرسالة
sleep 1

# 4. فتح قناة التيليجرام الخاصة بك
am start -a android.intent.action.VIEW -d "https://t.me/falconkernal" > /dev/null 2>&1
echo "--------------------------------"