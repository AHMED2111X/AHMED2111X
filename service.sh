#!/system/bin/sh
MODDIR=${0%/*}

# --- 1. تفعيل محرك التزييف (Tricky Store) ---
# ضبط صلاحيات وتشغيل ملف الحقن الموجود في المجلد الرئيسي[cite: 10, 11]
chmod 755 $MODDIR/inject[cite: 11, 12]
$MODDIR/inject &[cite: 12]

# إعداد بيئة تزييف البوت لودر[cite: 12]
mkdir -p /data/adb/tricky_store[cite: 12]
touch /data/adb/tricky_store/spoof_build_vars[cite: 12]
echo "com.google.android.gms!" > /data/adb/tricky_store/target.txt[cite: 12]

# --- 2. تحديث البصمة (Red Magic 11 Pro) ---
cp $MODDIR/pif.json /data/adb/pif.json[cite: 12]
chmod 644 /data/adb/pif.json[cite: 12]

# --- 3. التنظيف الشامل وتجديد الكيبوكس ---
# حذف أي ملف ينتهي بـ .bak لضمان نظافة الفحص[cite: 12]
rm -f /data/adb/tricky_store/*.bak[cite: 12]

if [ -f "$MODDIR/keybox.xml" ]; then
    cp $MODDIR/keybox.xml /data/adb/tricky_store/keybox.xml[cite: 12]
    chmod 644 /data/adb/tricky_store/keybox.xml[cite: 12]
fi

# --- 4. تفعيل الأداء العالي (165 FPS) ---
settings put signature min_refresh_rate 165.0[cite: 12]
settings put signature peak_refresh_rate 165.0[cite: 12]
setprop windowsmgr.max_events_per_sec 300[cite: 12]