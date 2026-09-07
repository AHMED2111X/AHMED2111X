#!/system/bin/sh
MODDIR=${0%/*}

# --- 1. تفعيل محرك الحقن الصافي ---
# فحص وجود ملف الحقن أولاً وضبط الصلاحيات
if [ -f "$MODDIR/inject" ]; then
    chmod 755 "$MODDIR/inject"
    "$MODDIR/inject" &
fi

# إنشاء مسار الحماية الأساسي
mkdir -p /data/adb/tricky_store
chmod 755 /data/adb/tricky_store
chown root:root /data/adb/tricky_store

# --- 2. تحديث البصمة الأصلية (Pixel 9 Pro XL) ---
# لضمان تجاوز فحص Play Integrity دون تعارض
if [ -f "$MODDIR/pif.json" ]; then
    cp "$MODDIR/pif.json" /data/adb/pif.json
    chmod 644 /data/adb/pif.json
    chown root:root /data/adb/pif.json
    chcon u:object_r:system_file:s0 /data/adb/pif.json 2>/dev/null
fi

# --- 3. إدارة وتنظيف ملفات الكيبوكس (Keybox) ---
# حذف كافة الملفات القديمة والاحتياطية لضمان الاستبدال النظيف
rm -f /data/adb/tricky_store/keybox.xml
rm -f /data/adb/tricky_store/keybox.xml.bak
rm -f /data/adb/tricky_store/*.bak
rm -f /data/adb/tricky_store/*.tmp

# نقل ملف الكيبوكس الجديد وضبط الصلاحيات وسياق SELinux لـ Android 16
if [ -f "$MODDIR/keybox.xml" ]; then
    cp "$MODDIR/keybox.xml" /data/adb/tricky_store/keybox.xml
    chmod 644 /data/adb/tricky_store/keybox.xml
    chown root:root /data/adb/tricky_store/keybox.xml
    chcon u:object_r:system_file:s0 /data/adb/tricky_store/keybox.xml 2>/dev/null
fi

# --- 4. تفعيل الأداء الأقصى (وضع الوحش) ---
# تفعيل الـ 165 FPS وضبط الاستجابة الأقصى للمس
settings put system min_refresh_rate 165.0
settings put system peak_refresh_rate 165.0
setprop windowsmgr.max_events_per_sec 300