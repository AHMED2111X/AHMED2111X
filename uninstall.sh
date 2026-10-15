#!/system/bin/sh

# ==============================================================================
# FALCON INTEGRITY FIX - سكربت إزالة التثبيت والتنظيف
# المطور: ABUFARID
# ==============================================================================

# إزالة خاصية GMS من الذاكرة الحالية
if command -v resetprop >/dev/null 2>&1; then
    resetprop --delete persist.sys.spoof.gms 2>/dev/null
fi

# حذف ملف الخاصية الدائمة إن كان موجودًا
rm -f "/data/property/persist.sys.spoof.gms" 2>/dev/null

# حذف ملفات السجل الخاصة بالموديول
rm -f "/data/adb/modules/playintegrityfix/falcon_integrity_fix.log" 2>/dev/null
rm -f "/data/adb/modules/playintegrityfix/integrity_fix.log" 2>/dev/null

# تنظيف ملفات البصمة التي نشرناها في مسار المحرك (فقط إن كنا نحن من أنشأها)
PIF_MIRROR_DIR="/data/adb/modules/playintegrityfix"
if [ -d "$PIF_MIRROR_DIR" ] && [ ! -f "$PIF_MIRROR_DIR/module.prop" ]; then
    rm -f "$PIF_MIRROR_DIR/custom.pif.json" "$PIF_MIRROR_DIR/pif.json" \
          "$PIF_MIRROR_DIR/custom.pif.prop" "$PIF_MIRROR_DIR/pif.prop" \
          "$PIF_MIRROR_DIR/classes.dex" 2>/dev/null
    rmdir "$PIF_MIRROR_DIR" 2>/dev/null
fi
rm -f /data/adb/pif.json /data/adb/pif.prop 2>/dev/null

# --- إيقاف محرك التعتيد المفتوح المصدر (Tricky Store OSS) ---
for P in TrickyStoreOSS TrickyStore; do
    for PID in $(pidof "$P" 2>/dev/null); do
        kill -9 "$PID" 2>/dev/null
    done
done
pkill -f "io.github.beakthoven.TrickyStoreOSS" 2>/dev/null || true

# --- إلغاء أي حذف معلّق للوحدات المتعارضة (احترام ممتلكات المستخدم) ---
# إن أزلت موديولنا قبل إعادة التشغيل، نُلغي علامة الحذف التي وضعناها على
# tricky_store / safetynet-fix حتى لا تُمسح وحدات المستخدم بلا سبب.
for RID in tricky_store safetynet-fix; do
    for RBASE in /data/adb/modules /data/adb/modules_update; do
        [ -d "$RBASE/$RID" ] || continue
        rm -f "$RBASE/$RID/remove" "$RBASE/$RID/disable" 2>/dev/null
    done
done

# --- تنظيف ملفات حالة المحرك ---
# ⛔ لا نحذف /data/adb/tricky_store إطلاقاً: قد يحتوي كيبوكس/إعدادات شخصية
#    للمستخدم من وحدة TrickyStore المستقلة. نُبقيها كما هي.
rm -f /data/adb/tricky_store/*.bak /data/adb/tricky_store/*.falcon_merge 2>/dev/null
rm -f /data/adb/falcon_daemon.log /data/adb/falcon_pif.log /data/adb/falcon_rkp_fix.log 2>/dev/null

exit 0