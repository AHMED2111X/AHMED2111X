#!/system/bin/sh
MODDIR=${0%/*}

# 1. تفعيل محرك الحقن (المكتبات الموضحة في image_6349c8.png)
chmod 755 $MODDIR/inject
$MODDIR/inject &[cite: 2]

# إنشاء مسار Tricky Store لضمان عمل المكتبات
mkdir -p /data/adb/tricky_store[cite: 2]

# 2. تحديث بصمة Red Magic 11 Pro الأصلية
cp $MODDIR/pif.json /data/adb/pif.json[cite: 2]
chmod 644 /data/adb/pif.json[cite: 2]

# 3. إدارة واستبدال ملفات الكيبوكس (Keybox)
# حذف الملفات القديمة والاحتياطية والمؤقتة لضمان التحديث النظيف[cite: 2]
rm -f /data/adb/tricky_store/keybox.xml[cite: 2]
rm -f /data/adb/tricky_store/keybox.xml.bak[cite: 2]
rm -f /data/adb/tricky_store/*.bak[cite: 2]
rm -f /data/adb/tricky_store/*.tmp

# نقل ملف الكيبوكس الجديد وضبط الصلاحيات
if [ -f "$MODDIR/keybox.xml" ]; then
    cp $MODDIR/keybox.xml /data/adb/tricky_store/keybox.xml[cite: 2]
    chmod 644 /data/adb/tricky_store/keybox.xml[cite: 2]
    chown root:root /data/adb/tricky_store/keybox.xml[cite: 3]
fi

# 4. تفعيل الأداء العالي (165 FPS)
settings put signature min_refresh_rate 165.0[cite: 2]
settings put signature peak_refresh_rate 165.0[cite: 2]
setprop windowsmgr.max_events_per_sec 300[cite: 2]