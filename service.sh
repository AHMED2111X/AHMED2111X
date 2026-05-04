#!/system/bin/sh
MODDIR=${0%/*}

# --- 1. تفعيل محرك الحقن الصافي ---
# (باستخدام المكتبات الموضحة في image_6349c8.png)
chmod 755 $MODDIR/inject
$MODDIR/inject &

# إنشاء مسار الحماية الأساسي
mkdir -p /data/adb/tricky_store

# --- 2. تحديث البصمة الأصلية (Red Magic 11 Pro) ---
# لضمان تجاوز فحص Play Integrity دون تعارض
cp $MODDIR/pif.json /data/adb/pif.json
chmod 644 /data/adb/pif.json

# --- 3. إدارة وتنظيف ملفات الكيبوكس (Keybox) ---
# حذف كافة الملفات القديمة والاحتياطية لضمان الاستبدال النظيف
rm -f /data/adb/tricky_store/keybox.xml
rm -f /data/adb/tricky_store/keybox.xml.bak
rm -f /data/adb/tricky_store/*.bak
rm -f /data/adb/tricky_store/*.tmp

# نقل ملف الكيبوكس الجديد وضبط الصلاحيات بالكامل
if [ -f "$MODDIR/keybox.xml" ]; then
    cp $MODDIR/keybox.xml /data/adb/tricky_store/keybox.xml
    chmod 644 /data/adb/tricky_store/keybox.xml
    chown root:root /data/adb/tricky_store/keybox.xml
fi

# --- 4. تفعيل الأداء الأقصى (وضع الوحش) ---
# تفعيل الـ 165 FPS دون أي أكواد تزييف إضافية
settings put signature min_refresh_rate 165.0
settings put signature peak_refresh_rate 165.0
setprop windowsmgr.max_events_per_sec 300