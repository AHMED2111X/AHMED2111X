#!/system/bin/sh

# ==============================================================================
# إصلاح فحص الحماية FALCON INTEGRITY FIX - مدير بصمة Play Integrity
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
# ------------------------------------------------------------------------------
# مكتبة PIF الأصلية (zygisk/*.so) تقرأ الإعدادات حصراً من المسار الثابت:
#     /data/adb/falcon_pif/custom.pif.prop
# لذلك نُنشئ هذا المجلد وننشر فيه أدوات autopif4 + migrate ونولّد بصمة Pixel
# معتمدة، لتعمل البصمة فعلياً على الجهاز (كانت المشكلة أن الإعداد لم يُقرأ إطلاقاً).
# ==============================================================================

MODPATH="${0%/*}"
case "$MODPATH" in
    */*) : ;;
    *)   MODPATH="/data/adb/modules/falcon_integrity_fix" ;;
esac
PIF_DIR="/data/adb/falcon_pif"
SRC="$MODPATH/pif"
LOG="/data/adb/falcon_pif.log"
: > "$LOG" 2>/dev/null
log() { echo "$@" >> "$LOG" 2>/dev/null; }

# --- 1. إنشاء مجلد PIF الجديد وتطبيق الصلاحيات ---
# ملاحظة: المسار خارج /data/adb/modules عمداً حتى لا يظهر كـ"موديول وهمي"
# في قائمة الموديولات داخل مدير الروت.
mkdir -p "$PIF_DIR" 2>/dev/null
chmod 755 "$PIF_DIR" 2>/dev/null
chown root:root "$PIF_DIR" 2>/dev/null

# --- 1b. ترحيل ثم حذف مجلد PIF القديم من داخل /data/adb/modules ---
OLD_PIF_DIR="/data/adb/modules/playintegrityfix"
if [ -d "$OLD_PIF_DIR" ] && [ ! -f "$OLD_PIF_DIR/module.prop" ]; then
    if [ -s "$OLD_PIF_DIR/custom.pif.prop" ] && [ ! -s "$PIF_DIR/custom.pif.prop" ]; then
        cp -f "$OLD_PIF_DIR/custom.pif.prop" "$PIF_DIR/custom.pif.prop" 2>/dev/null
    fi
    if [ -s "$OLD_PIF_DIR/custom.pif.json" ] && [ ! -s "$PIF_DIR/custom.pif.json" ]; then
        cp -f "$OLD_PIF_DIR/custom.pif.json" "$PIF_DIR/custom.pif.json" 2>/dev/null
    fi
    rm -rf "$OLD_PIF_DIR" 2>/dev/null
    log "== removed legacy dir /data/adb/modules/playintegrityfix =="
fi

# --- 2. نشر أدوات التوليد (idempotent) ---
for f in autopif4.sh migrate.sh killpi.sh example.pif.prop; do
    if [ -f "$SRC/$f" ]; then
        cp -f "$SRC/$f" "$PIF_DIR/$f" 2>/dev/null
    fi
done
chmod 755 "$PIF_DIR"/*.sh 2>/dev/null
chmod 644 "$PIF_DIR"/*.prop 2>/dev/null

# --- 2b. نشر كلاس EntryPoint الخاص بـ PIF (classes.dex) في مسار المكتبة ---
# المكتبة تبحث عن es.chiteroman.playintegrityfix.EntryPoint في:
#   /data/adb/falcon_pif/classes.dex
if [ -f "$MODPATH/classes.dex" ]; then
    cp -f "$MODPATH/classes.dex" "$PIF_DIR/classes.dex" 2>/dev/null
    chmod 644 "$PIF_DIR/classes.dex" 2>/dev/null
fi

# --- 3. التحقق من صلاحية البصمة الحالية ---
pif_config_ok() {
    if [ -s "$PIF_DIR/custom.pif.prop" ]; then
        grep -qE '^FINGERPRINT=[^[:space:]]' "$PIF_DIR/custom.pif.prop" 2>/dev/null && return 0
    fi
    if [ -s "$PIF_DIR/custom.pif.json" ]; then
        grep -qE '"FINGERPRINT"[[:space:]]*:[[:space:]]*"[^"]' "$PIF_DIR/custom.pif.json" 2>/dev/null && return 0
    fi
    return 1
}

# --- 4. توليد بصمة Pixel Canary معتمدة عند الحاجة أو عند الطلب ---
GEN=0
case "$1" in
    --deploy) GEN=0 ;;
    --force)  GEN=1 ;;
    *)        pif_config_ok || GEN=1 ;;
esac

if [ "$GEN" = "1" ] && [ -f "$PIF_DIR/autopif4.sh" ]; then
    log "== autopif4: start =="
    # autopif4 يتوقّع أن يكون في جذر مجلد إعدادات PIF ليضبط DIR بشكل صحيح
    OUT="$( ( cd "$PIF_DIR" && sh "$PIF_DIR/autopif4.sh" -m ) 2>&1 )" \
    || OUT="$( ( cd "$PIF_DIR" && sh "$PIF_DIR/autopif4.sh" ) 2>&1 )" || true
    printf '%s\n' "$OUT" >> "$LOG" 2>/dev/null
    if [ -n "$FALCON_PIF_VERBOSE" ]; then
        printf '%s\n' "$OUT"
    fi
fi

# --- 4b. بصمة احتياطية جاهزة عند تعذّر التوليد (بدون إنترنت) ---
if ! pif_config_ok; then
    if [ -f "$SRC/fallback.pif.prop" ]; then
        log "== generation failed: using bundled fallback fingerprint =="
        cp -f "$SRC/fallback.pif.prop" "$PIF_DIR/custom.pif.prop" 2>/dev/null
    fi
fi

# --- 5. مزامنة مسارات قديمة للتوافق ---
[ -s "$PIF_DIR/custom.pif.prop" ] && cp -f "$PIF_DIR/custom.pif.prop" /data/adb/pif.prop 2>/dev/null
[ -s "$PIF_DIR/custom.pif.json" ] && cp -f "$PIF_DIR/custom.pif.json" /data/adb/pif.json 2>/dev/null

# --- 6. سياق SELinux (ليتمكّن gmscore_app/untrusted_app من قراءة الإعداد) ---
if command -v chcon >/dev/null 2>&1; then
    chcon u:object_r:system_file:s0 "$PIF_DIR" 2>/dev/null || true
    chcon u:object_r:system_file:s0 "$PIF_DIR"/* 2>/dev/null || true
fi
chmod 755 "$PIF_DIR" 2>/dev/null
for f in "$PIF_DIR"/*; do
    if [ -f "$f" ] && [ -x "$f" ]; then
        chmod 755 "$f" 2>/dev/null
    elif [ -f "$f" ]; then
        chmod 644 "$f" 2>/dev/null
    fi
done

if pif_config_ok; then log "== result: CONFIG OK =="; else log "== result: CONFIG MISSING =="; fi

exit 0
