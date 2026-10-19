#!/system/bin/sh
# ==============================================================================
# FALCON INTEGRITY FIX — استخراج أيقونات التطبيقات
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
#
# v3.19c (إصلاح «لا تظهر أيقونات»):
#   1) إصلاح جذري: نمط الموارد القديم res/[A-Za-z0-9_]+/ic_launcher…
#      لا يطابق مجلدات الأدغال مثل res/mipmap-xxxhdpi/ (بها شرطة) — أي أنه
#      كان يفشل في كل التطبيقات الحديثة تقريباً. النمط الآن يقبل الشرطة والنقطة.
#   2) بحث الأيقونة في كل أجزاء الحزمة (base + split APKs) وليس base فقط —
#      بعض الحزم تضع أيقونة الدقة في جزء منفصل.
#   3) احتياطي لـunzip: إن كان النظام بلا unzip نستخدم busybox (ksu/magisk/ap).
#   4) احتياطي ثانٍ: أي ملف يحوي "launcher" في اسمه (بلا حساسية حالة).
#   5) سجل تشخيصي: /data/adb/falcon/icons.log
#   6) (v3.19d) فحص فعلي لأداة فك الضغط (unzip/toybox/busybox) + كشف NOUNZIP
#      + تسجيل مسارات أول 3 إخفاقات + مسح بوابة المسح عند الفشل الكلي.
#   7) (v3.19e) busybox مدمج مع الوحدة (arm64 ثابتة) يُجرَّب أولاً، وفحص كل
#      مرشّح صار فهرسة+استخراجاً فعلياً (-p)، + احتياطي pm من packages.list + DIAG.
#   8) (v3.19f) محرك dex اختياري (app_process): يجلب أيقونة المشغّل الحقيقية من
#      نظام أندرويد لباقي التطبيقات (يعالج التطبيقات ذات الموارد المقصّرة).
#
# طريقة العمل:
#   1) pm path <الحزمة>  ← مسارات كل أجزاء APK
#   2) نبحث داخل كل جزء عن مورد أيقونة المشغّل (ic_launcher)
#   3) نفضّل أعلى دقة متاحة، ونفضّل PNG على WEBP، ونعاقب background
#   4) نستخرجها إلى مجلد الأيقونات ثم نحدّث ملف الفهرس
#
# الاستخدام:
#   sh icons.sh                  ← لكل التطبيقات الموجودة في target.txt
#   sh icons.sh pkg1 pkg2 ...    ← لحزم محددة
# ==============================================================================

export PATH=/system/bin:/system/xbin:/vendor/bin:$PATH

ICON_DIR="/data/adb/falcon_icons"
ICON_WEB="/data/adb/modules/falcon_tricky/webroot/icons"
TARGET_FILE="/data/adb/tricky_store/target.txt"
LOG="/data/adb/falcon/icons.log"

# (v3.19e) مجلد السكربت نفسه — للوصول إلى busybox المدمج مع الوحدة
_SD=$(CDPATH= cd "$(dirname "$0")" 2>/dev/null && pwd)
[ -n "$_SD" ] && [ -f "$_SD/busybox" ] && chmod 755 "$_SD/busybox" 2>/dev/null

mkdir -p /data/adb/falcon 2>/dev/null
if [ -f "$LOG" ]; then
    _LINES=$(wc -l < "$LOG" 2>/dev/null)
    [ -n "$_LINES" ] && [ "$_LINES" -gt 600 ] && : > "$LOG" 2>/dev/null
fi
log() { echo "$(date '+%m-%d %H:%M:%S' 2>/dev/null) $*" >> "$LOG" 2>/dev/null; }

# (v3.19d/e) اختيار أداة فك الـAPK — بفحص فعلي (فهرسة + استخراج حقيقي)،
# وv3.19e يجرّب busybox المدمج مع الوحدة أولاً ثم أدوات النظام الاحتياطية.
_PROBE="/system/framework/framework-res.apk"
UNZ=""
for _CAND in "${_SD:+$_SD/busybox unzip}" "/data/adb/modules/playintegrityfix/busybox unzip" \
             "/data/adb/modules_update/playintegrityfix/busybox unzip" \
             "unzip" "/system/bin/unzip" "/system/xbin/unzip" "toybox unzip" "busybox unzip" \
             "/data/adb/ksu/bin/busybox unzip" "/data/adb/magisk/busybox unzip" \
             "/data/adb/ap/bin/busybox unzip" "/data/adb/ksud/bin/busybox unzip"; do
    [ -n "$_CAND" ] || continue
    if $_CAND -l "$_PROBE" >/dev/null 2>&1 && $_CAND -p "$_PROBE" AndroidManifest.xml >/dev/null 2>&1; then
        UNZ="$_CAND"; break
    fi
done
if [ -z "$UNZ" ]; then
    for _BB in $(find /data/adb -maxdepth 5 -name busybox -type f 2>/dev/null | head -3); do
        if "$_BB" unzip -l "$_PROBE" >/dev/null 2>&1 && "$_BB" unzip -p "$_PROBE" AndroidManifest.xml >/dev/null 2>&1; then UNZ="$_BB unzip"; break; fi
    done
fi
log "START unz=[$UNZ] args=$#"
log "DIAG bsd=$([ -n "$_SD" ] && [ -f "$_SD/busybox" ] && echo 1 || echo 0) u1=[$(unzip -l "$_PROBE" 2>&1 | head -1)] t1=[$(toybox unzip -l "$_PROBE" 2>&1 | head -1)]"
if [ -z "$UNZ" ]; then
    log "NOUNZIP aborted — no working unzip/toybox/busybox on device"
    rm -f /data/adb/falcon/icons_scan 2>/dev/null
    echo "ICONS_NOUNZIP"
    exit 3
fi

mkdir -p "$ICON_DIR" 2>/dev/null
if [ -d "/data/adb/modules/falcon_tricky/webroot" ]; then
    mkdir -p "$ICON_WEB" 2>/dev/null
else
    ICON_WEB=""
fi

OK_N=0; FAIL_N=0; SKIP_N=0

extract_one() {
    _pkg="$1"
    [ -n "$_pkg" ] || return 0
    _out="$ICON_DIR/$_pkg.png"
    if [ -s "$_out" ]; then SKIP_N=$((SKIP_N+1)); return 0; fi

    # v3.19c: كل أجزاء الحزمة — base ثم split APKs
    _apks=$(pm path "$_pkg" 2>/dev/null | sed 's/package://' | tr -d '\r')
    if [ -z "$_apks" ]; then
        # (v3.19e) احتياطي: استنتاج مسار base.apk من packages.list إن فشل/تأخر pm
        _cp=$(awk -v p="$_pkg" '$1==p{print $2}' /data/system/packages.list 2>/dev/null | head -1)
        [ -n "$_cp" ] && [ -f "$_cp/base.apk" ] && _apks="$_cp/base.apk"
    fi
    [ -n "$_apks" ] || { FAIL_N=$((FAIL_N+1)); log "NOPATH $_pkg"; return 1; }

    for _apk in $_apks; do
        [ -f "$_apk" ] || continue
        # النمط الموسّع: يقبل الشرطة والنقطة في اسم مجلد الموارد (mipmap-xxxhdpi …)
        _icon=$($UNZ -l "$_apk" 2>/dev/null \
            | grep -oE 'res/[A-Za-z0-9._-]+/ic_launcher[A-Za-z0-9_]*\.(png|webp)' \
            | awk '{
                p = $NF
                s = (p ~ /xxxhdpi/ ? 6 : p ~ /xxhdpi/ ? 5 : p ~ /xhdpi/ ? 4 : p ~ /hdpi/ ? 3 : p ~ /mdpi/ ? 2 : p ~ /ldpi/ ? 1 : 0)
                s += (p ~ /[.]png$/ ? 10 : 5)
                s += (p ~ /foreground/ ? 3 : 0)
                s -= (p ~ /background/ ? 6 : 0)
                print s "\t" p
            }' \
            | sort -rn | head -1 | cut -f2-)
        # الاحتياطي الثاني: أي ملف باسم يحوي launcher (بلا حساسية حالة)
        if [ -z "$_icon" ]; then
            _icon=$($UNZ -l "$_apk" 2>/dev/null \
                | grep -oiE 'res/[A-Za-z0-9._-]+/[A-Za-z0-9_]*launcher[A-Za-z0-9_]*\.(png|webp)' \
                | awk '{
                    p = $NF
                    s = (p ~ /xxxhdpi/ ? 6 : p ~ /xxhdpi/ ? 5 : p ~ /xhdpi/ ? 4 : p ~ /hdpi/ ? 3 : p ~ /mdpi/ ? 2 : p ~ /ldpi/ ? 1 : 0)
                    s += (p ~ /[.]png$/ ? 10 : 5)
                    s -= (p ~ /background/ ? 6 : 0)
                    print s "\t" p
                }' \
                | sort -rn | head -1 | cut -f2-)
        fi
        [ -n "$_icon" ] || continue

        $UNZ -p "$_apk" "$_icon" > "$_out" 2>/dev/null
        if [ -s "$_out" ]; then
            chmod 644 "$_out" 2>/dev/null
            OK_N=$((OK_N+1))
            return 0
        fi
        rm -f "$_out" 2>/dev/null
    done

    FAIL_N=$((FAIL_N+1))
    if [ "$FAIL_N" -le 3 ]; then log "MISS $_pkg first apk=[$_apks]"; else log "MISS $_pkg"; fi
    return 1
}

# (v3.19f) محرك أخير: أيقونة المشغّل الحقيقية من النظام نفسه (app_process + icondump.dex)
# $1 = ملف فيه أسماء الحزم المرشّحة — نمرّر منه فقط ما لا أيقونة له.
dump_icons_dex() {
    _SRC="$1"
    [ -n "$_SRC" ] && [ -s "$_SRC" ] || return 0
    _DEX=""
    for _d in "${_SD:+$_SD/icondump.dex}" "/data/adb/modules/playintegrityfix/icondump.dex" \
              "/data/adb/modules_update/playintegrityfix/icondump.dex"; do
        [ -n "$_d" ] && [ -f "$_d" ] && _DEX="$_d" && break
    done
    [ -n "$_DEX" ] || { log "DEX skip (no icondump.dex)"; return 0; }
    _LIST=/data/adb/falcon/.icon_dump_list
    : > "$_LIST" 2>/dev/null
    while read -r _p; do
        [ -n "$_p" ] || continue
        [ -s "$ICON_DIR/$_p.png" ] || echo "$_p" >> "$_LIST"
    done < "$_SRC"
    _N=$(wc -l < "$_LIST" 2>/dev/null)
    if [ -z "$_N" ] || [ "$_N" -eq 0 ]; then
        rm -f "$_LIST" 2>/dev/null
        log "DEX nothing-missing"
        return 0
    fi
    log "DEX start list=$_N dex=[$_DEX]"
    _OUT=/data/adb/falcon/.icon_dump_out
    if command -v timeout >/dev/null 2>&1; then
        CLASSPATH="$_DEX" timeout 420 app_process /system/bin com.falcon.FalconIconDump "$_LIST" "$ICON_DIR" > "$_OUT" 2>&1
    else
        CLASSPATH="$_DEX" app_process /system/bin com.falcon.FalconIconDump "$_LIST" "$ICON_DIR" > "$_OUT" 2>&1
    fi
    _OK=$(grep -c '^OK ' "$_OUT" 2>/dev/null)
    [ -n "$_OK" ] || _OK=0
    _ERR=$(grep -cE '^ERR |^FATAL ' "$_OUT" 2>/dev/null)
    [ -n "$_ERR" ] || _ERR=0
    while read -r _l; do log "DEX $_l"; done < "$_OUT"
    log "DEX done ok=$_OK err=$_ERR"
    OK_N=$((OK_N+_OK))
    rm -f "$_OUT" "$_LIST" 2>/dev/null
}

# نسخ الأيقونات إلى webroot الوحدة المرافقة + كتابة الفهرس للواجهة
publish_icons() {
    [ -n "$ICON_WEB" ] || return 0
    for _f in "$ICON_DIR"/*.png; do
        [ -s "$_f" ] || continue
        _b=$(basename "$_f")
        [ -s "$ICON_WEB/$_b" ] && continue
        cp -f "$_f" "$ICON_WEB/$_b" 2>/dev/null
    done
    # الفهرس: أسماء الحزم التي لها أيقونة فعلية (من ملفات .png فقط)
    {
        echo "# falcon-icons-index"
        for _g in "$ICON_WEB"/*.png; do
            [ -s "$_g" ] || continue
            basename "$_g" .png
        done
    } > "$ICON_WEB/.idx.tmp" 2>/dev/null
    mv -f "$ICON_WEB/.idx.tmp" "$ICON_WEB/_index.txt" 2>/dev/null || cp -f "$ICON_WEB/.idx.tmp" "$ICON_WEB/_index.txt" 2>/dev/null
    chmod 644 "$ICON_WEB/_index.txt" 2>/dev/null
    chmod 755 "$ICON_WEB" 2>/dev/null
}

# وضع الحزم المحددة
if [ "$#" -gt 0 ]; then
    _ALL=/data/adb/falcon/.scan_args
    : > "$_ALL" 2>/dev/null
    for _p in "$@"; do
        echo "$_p" >> "$_ALL"
        extract_one "$_p"
    done
    dump_icons_dex "$_ALL"
    rm -f "$_ALL" 2>/dev/null
    publish_icons
    [ "$OK_N" -eq 0 ] && [ "$FAIL_N" -gt 30 ] && rm -f /data/adb/falcon/icons_scan 2>/dev/null
    log "DONE args ok=$OK_N fail=$FAIL_N skip=$SKIP_N web=$([ -n "$ICON_WEB" ] && echo 1 || echo 0)"
    echo "ICONS_DONE"
    exit 0
fi

# الوضع الكامل: كل التطبيقات الموجودة في target.txt
if [ -f "$TARGET_FILE" ]; then
    _ALL=/data/adb/falcon/.scan_all
    : > "$_ALL" 2>/dev/null
    while read -r _line; do
        case "$_line" in
            ''|'#'*) continue ;;
        esac
        _line="${_line%!}"
        echo "$_line" >> "$_ALL"
        extract_one "$_line"
    done < "$TARGET_FILE"
    dump_icons_dex "$_ALL"
    rm -f "$_ALL" 2>/dev/null
else
    log "NOTARGET"
fi

publish_icons
[ "$OK_N" -eq 0 ] && [ "$FAIL_N" -gt 30 ] && rm -f /data/adb/falcon/icons_scan 2>/dev/null
log "DONE full ok=$OK_N fail=$FAIL_N skip=$SKIP_N web=$([ -n "$ICON_WEB" ] && echo 1 || echo 0)"
echo "ICONS_DONE"
