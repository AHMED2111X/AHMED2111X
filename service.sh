#!/system/bin/sh
MODDIR=${0%/*}

# --- 1. تفعيل محرك الحقن الصافي ---
# فحص وجود ملف الحقن أولاً وضبط الصلاحيات[cite: 6]
if [ -f "$MODDIR/inject" ]; then
    chmod 755 "$MODDIR/inject"[cite: 6]
    "$MODDIR/inject" &[cite: 6]
fi

# إنشاء مسار الحماية الأساسي[cite: 6]
mkdir -p /data/adb/tricky_store[cite: 6]
chmod 755 /data/adb/tricky_store
chown root:root /data/adb/tricky_store

# --- 2. تحديث البصمة الأصلية (Red Magic 11 Pro) ---
# لضمان تجاوز فحص Play Integrity دون تعارض[cite: 6]
if [ -f "$MODDIR/pif.json" ]; then
    cp "$MODDIR/pif.json" /data/adb/pif.json[cite: 6]
    chmod 644 /data/adb/pif.json[cite: 6]
    chown root:root /data/adb/pif.json
    chcon u:object_r:system_file:s0 /data/adb/pif.json 2>/dev/null
fi

# --- 3. إدارة وتنظيف ملفات الكيبوكس (Keybox) ---
# حذف كافة الملفات القديمة والاحتياطية لضمان الاستبدال النظيف[cite: 6]
rm -f /data/adb/tricky_store/keybox.xml[cite: 6]
rm -f /data/adb/tricky_store/keybox.xml.bak[cite: 6]
rm -f /data/adb/tricky_store/*.bak[cite: 6]
rm -f /data/adb/tricky_store/*.tmp[cite: 6]

# نقل ملف الكيبوكس الجديد وضبط الصلاحيات وسياق SELinux لـ Android 16[cite: 6]
if [ -f "$MODDIR/keybox.xml" ]; then
    cp "$MODDIR/keybox.xml" /data/adb/tricky_store/keybox.xml[cite: 6]
    chmod 644 /data/adb/tricky_store/keybox.xml[cite: 6]
    chown root:root /data/adb/tricky_store/keybox.xml[cite: 6]
    chcon u:object_r:system_file:s0 /data/adb/tricky_store/keybox.xml 2>/dev/null
fi

# --- 4. تفعيل الأداء الأقصى (وضع الوحش) ---
# تفعيل الـ 165 FPS وضبط الاستجابة الأقصى للمس[cite: 6]
settings put system min_refresh_rate 165.0
settings put system peak_refresh_rate 165.0
setprop windowsmgr.max_events_per_sec 300[cite: 6]