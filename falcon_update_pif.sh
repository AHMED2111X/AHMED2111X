#!/system/bin/sh

# ==============================================================================
# FALCON INTEGRITY FIX — تحديث بصمة Canary تلقائياً من جوجل
# (v3.16) المطور: ABUFARID | تليجرام: @FALCON_KERNEL
#
# مبنى على منطق autopif4 لـ osm0sis (PIFork) — مُكيَّف لبنية FALCON
# (بلا الحاجة إلى migrate.sh — يكتب ملف custom.pif.prop كاملاً ثم يستدعي
#  apply_pif.sh force لتوليد JSON وتوزيعه على كل المسارات).
#
# الوظيفة:
#   1) يزحف developer.android.com لمعرفة أحدث إصدار أندرويد وأجهزة Beta.
#   2) يختار جهاز Beta (عشوائي، أو جهازك مع -m إن كان ضمن القائمة).
#   3) يجلب أحدث بناء Canary من Android Flash Tool.
#   4) يحدد تاريخ الإصدار من آخر تعديل لملف المصنع، والرقعة الأمنية من
#      نشرات أمان Pixel الرسمية.
#   5) يكتب custom.pif.prop جديداً (مع الإبقاء على إعداداتك المتقدمة)
#      + نسخة احتياطية تلقائية، ويزامن الرقعة مع Tricky Store، ويعيد
#      تشغيل خدمات جوجل.
#
# الاستخدام:
#   sh falcon_update_pif.sh [-m|--match] [--force]
#   - -m      : فضّل طراز جهازك إن كان ضمن أجهزة Beta (وإلا عشوائي).
#   - --force : أعد الكتابة حتى لو كانت البصمة الحالية هي الأحدث.
#
# ⛔ لا يُشغَّل تلقائياً عند الإقلاع أبداً — فقط عند طلب المستخدم.
# ==============================================================================

set +o standalone 2>/dev/null
unset ASH_STANDALONE 2>/dev/null

MODDIR="${0%/*}"
[ -n "$MODDIR" ] && [ -d "$MODDIR" ] || MODDIR="/data/adb/modules/playintegrityfix"
WRK="/data/adb/falcon/updater"
mkdir -p "$WRK" 2>/dev/null

FORCE_MATCH=0
FORCE_UPDATE=0
for A in "$@"; do
    case "$A" in
        -m|--match|match) FORCE_MATCH=1 ;;
        --force|-f) FORCE_UPDATE=1 ;;
        -h|--help|help)
            echo "الاستخدام: sh falcon_update_pif.sh [-m|--match] [--force]"
            exit 0
            ;;
    esac
done

say() { printf '[➜] %s\n' "$1"; }
ok()  { printf '[✔] %s\n' "$1"; }
die() { printf '[✖] %s\n' "$1"; exit 1; }

# --- فحص البيئة والصلاحيات ---
if [ "$USER" != "root" ] && [ "$(whoami 2>/dev/null)" != "root" ] && [ "$(id -u 2>/dev/null)" != "0" ]; then
    die "تتطلب هذه العملية صلاحيات الروت (Root)"
fi
case "$HOME" in
    *termux*) die "يرجى التشغيل من بيئة الروت الأساسية (داخل تطبيق الروت)" ;;
esac

# --- البحث عن busybox ---
BUSYBOX=""
find_busybox() {
    [ -n "$BUSYBOX" ] && return 0
    local path
    for path in /data/adb/modules/busybox-ndk/system/*/busybox /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox; do
        if [ -f "$path" ]; then
            BUSYBOX="$path"
            return 0
        fi
    done
    return 1
}
find_busybox 2>/dev/null

# --- فحص أدوات date/grep/tac (مع احتياطي busybox) ---
if date -D '%s' -d "$(date '+%s')" 2>&1 | grep -qE "bad date|invalid option"; then
    if ! find_busybox; then
        die "أمر date غير صالح — يرجى تثبيت إضافة busybox"
    fi
    date() { "$BUSYBOX" date "$@"; }
fi

if ! printf 'A\nB\n' | grep -m1 -A1 "A" | grep -q "B"; then
    if ! find_busybox; then
        die "أمر grep غير صالح — يرجى تثبيت إضافة busybox"
    fi
    grep() { "$BUSYBOX" grep "$@"; }
fi

# --- تنزيل: curl ثم busybox wget ثم wget النظامي (مع Referer اختياري) ---
dl() {
    local tmp="$2.tmp"
    rm -f "$tmp" 2>/dev/null
    if command -v curl >/dev/null 2>&1; then
        if [ -n "$3" ]; then
            curl -k -L -sS --connect-timeout 12 -m 90 -H "Referer: $3" -o "$tmp" "$1" 2>/dev/null
        else
            curl -k -L -sS --connect-timeout 12 -m 90 -o "$tmp" "$1" 2>/dev/null
        fi
        if [ -s "$tmp" ]; then mv -f "$tmp" "$2" 2>/dev/null; return 0; fi
    fi
    if [ -n "$BUSYBOX" ]; then
        if [ -n "$3" ]; then
            "$BUSYBOX" wget -q -T 60 --no-check-certificate --header "Referer: $3" -O "$tmp" "$1" 2>/dev/null
        else
            "$BUSYBOX" wget -q -T 60 --no-check-certificate -O "$tmp" "$1" 2>/dev/null
        fi
        if [ -s "$tmp" ]; then mv -f "$tmp" "$2" 2>/dev/null; return 0; fi
    fi
    if command -v wget >/dev/null 2>&1; then
        wget -q -T 60 --no-check-certificate -O "$tmp" "$1" 2>/dev/null || wget -q -O "$tmp" "$1" 2>/dev/null
        if [ -s "$tmp" ]; then mv -f "$tmp" "$2" 2>/dev/null; return 0; fi
    fi
    rm -f "$tmp" 2>/dev/null
    return 1
}

# --- جلب ترويسة Last-Modified لملف بعيد ---
get_lastmod() {
    if command -v curl >/dev/null 2>&1; then
        curl -k -sI -L --connect-timeout 12 -m 60 "$1" 2>/dev/null > "$2"
    elif [ -n "$BUSYBOX" ]; then
        "$BUSYBOX" wget -q -T 60 -S --spider --no-check-certificate -o "$2" "$1" 2>/dev/null
    elif command -v wget >/dev/null 2>&1; then
        wget -q -S --spider --no-check-certificate -o "$2" "$1" 2>/dev/null
    fi
    grep -i -m1 'last-modified' "$2" 2>/dev/null | sed 's/^[Ll]ast-[Mm]odified:[[:space:]]*//' | tr -d '\r'
}

# --- قراءة قيمة من ملف البصمة القديم (مع قيمة افتراضية) ---
get_adv() {
    local v=""
    [ -f "$OLD_PROP" ] && v=$(grep -m1 "^$1=" "$OLD_PROP" 2>/dev/null | cut -d= -f2 | tr -d '\r' | sed 's/[[:space:]]*$//')
    [ -z "$v" ] && v="$2"
    printf '%s' "$v"
}

cd "$WRK" || die "تعذر الوصول إلى مجلد العمل $WRK"
rm -f PIXEL_*.new PIXEL_VERSIONS_HTML PIXEL_LATEST_HTML PIXEL_FI_HTML PIXEL_OTA_HTML \
      PIXEL_FLASH_HTML PIXEL_STATION_JSON PIXEL_CANARY_JSON PIXEL_ZIP_HEADERS \
      PIXEL_SECBULL_HTML custom.pif.prop.new 2>/dev/null

# --- 1) أحدث إصدار أندرويد ---
say "جلب قائمة إصدارات أندرويد من موقع المطورين..."
dl "https://developer.android.com/about/versions" PIXEL_VERSIONS_HTML || die "فشل الاتصال بالإنترنت (developer.android.com)"

VMAX=0
for V in $(grep -oE 'about/versions/[0-9]+' PIXEL_VERSIONS_HTML 2>/dev/null | grep -oE '[0-9]+' | sort -u); do
    case "$V" in ''|*[!0-9]*) continue ;; esac
    [ "$V" -gt "$VMAX" ] && VMAX=$V
done
[ "$VMAX" -lt 9 ] 2>/dev/null && die "تعذر تحديد إصدارات أندرويد"

FI_LINK=""
V=$VMAX
while [ "$V" -ge 9 ]; do
    if dl "https://developer.android.com/about/versions/$V" PIXEL_LATEST_HTML; then
        FI_LINK=$(grep -o 'href="[^"]*download[^"]*"' PIXEL_LATEST_HTML 2>/dev/null | grep 'qpr' | cut -d'"' -f2 | head -n 1)
        [ -n "$FI_LINK" ] && break
    fi
    V=$((V - 1))
done
[ -z "$FI_LINK" ] && die "لم يُعثر على صفحة تنزيلات Beta/QPR"
say "صفحة الإصدار: أندرويد $V"

# --- 2) قوائم الأجهزة ---
OTA_LINK=$(grep -o 'href="[^"]*download-ota[^"]*"' PIXEL_LATEST_HTML 2>/dev/null | grep 'qpr' | cut -d'"' -f2 | head -n 1)
[ -z "$OTA_LINK" ] && OTA_LINK="$FI_LINK"

say "تنزيل صفحتي الصور الكاملة و OTA..."
dl "https://developer.android.com$FI_LINK" PIXEL_FI_HTML || die "فشل تنزيل صفحة الصور الكاملة"
dl "https://developer.android.com$OTA_LINK" PIXEL_OTA_HTML || true

FI_N=$(grep -c 'tr id=' PIXEL_FI_HTML 2>/dev/null)
case "$FI_N" in ''|*[!0-9]*) FI_N=0 ;; esac
OTA_N=$(grep -c 'tr id=' PIXEL_OTA_HTML 2>/dev/null)
case "$OTA_N" in ''|*[!0-9]*) OTA_N=0 ;; esac
SRC_HTML=PIXEL_FI_HTML
[ "$OTA_N" -gt "$FI_N" ] && SRC_HTML=PIXEL_OTA_HTML

MODEL_LIST=$(grep -A1 'tr id=' "$SRC_HTML" 2>/dev/null | grep 'td' | sed 's;.*<td>\(.*\)</td>.*;\1;')
PRODUCT_LIST=$(grep 'tr id=' "$SRC_HTML" 2>/dev/null | sed 's;.*<tr id="\(.*\)">.*;\1_beta;')
N=$(printf '%s\n' "$PRODUCT_LIST" | wc -w)
case "$N" in ''|*[!0-9]*) N=0 ;; esac
[ "$N" -ge 1 ] || die "قائمة أجهزة Beta فارغة"

# --- 3) اختيار الجهاز ---
PRODUCT=""
MODEL=""
if [ "$FORCE_MATCH" = "1" ]; then
    DEVP=$(getprop ro.product.device 2>/dev/null)
    case " $PRODUCT_LIST " in
        *" ${DEVP}_beta "*)
            PRODUCT="${DEVP}_beta"
            MODEL=$(getprop ro.product.model 2>/dev/null)
            ;;
    esac
fi
if [ -z "$PRODUCT" ]; then
    RND=$RANDOM
    case "$RND" in ''|*[!0-9]*) RND=1 ;; esac
    IDX=$((RND % N + 1))
    MODEL=$(printf '%s\n' "$MODEL_LIST" | sed -n "${IDX}p")
    PRODUCT=$(printf '%s\n' "$PRODUCT_LIST" | sed -n "${IDX}p")
fi
[ -z "$PRODUCT" ] && die "تعذر اختيار جهاز Beta"
DEVICE=$(printf '%s' "$PRODUCT" | sed 's/_beta$//')
[ -z "$MODEL" ] && MODEL="$DEVICE"
say "الجهاز المختار: $MODEL ($PRODUCT)"

# --- 4) أحدث بناء Canary من Flash Tool ---
say "جلب بيانات أحدث بناء Canary من Android Flash Tool..."
dl "https://flash.android.com/" PIXEL_FLASH_HTML || die "فشل تنزيل صفحة Flash Tool"
KEY=$(grep -o '<body data-client-config=.*' PIXEL_FLASH_HTML 2>/dev/null | cut -d';' -f2 | cut -d'&' -f1)
[ -z "$KEY" ] && die "تعذر استخراج مفتاح الاتصال من Flash Tool"

dl "https://content-flashstation-pa.googleapis.com/v1/builds?product=$PRODUCT&key=$KEY" PIXEL_STATION_JSON "https://flash.android.com" || die "فشل جلب بيانات البناء من جوجل"

CLINE=$(grep -n '"canary": true' PIXEL_STATION_JSON 2>/dev/null | tail -n 1 | cut -d: -f1)
case "$CLINE" in ''|*[!0-9]*) die "لا يوجد بناء Canary لهذا الجهاز" ;; esac
CSTART=$((CLINE - 14))
[ "$CSTART" -lt 1 ] && CSTART=1
sed -n "${CSTART},${CLINE}p" PIXEL_STATION_JSON > PIXEL_CANARY_JSON 2>/dev/null
[ -s PIXEL_CANARY_JSON ] || die "لا يوجد بناء Canary لهذا الجهاز"

ID=$(grep 'releaseCandidateName' PIXEL_CANARY_JSON 2>/dev/null | cut -d'"' -f4)
INCREMENTAL=$(grep 'buildId' PIXEL_CANARY_JSON 2>/dev/null | cut -d'"' -f4)
RTVER=$(grep 'releaseTrackVersionName' PIXEL_CANARY_JSON 2>/dev/null | cut -d'"' -f4)
[ -z "$ID" ] && die "تعذر استخراج رقم البناء (ID)"
[ -z "$INCREMENTAL" ] && die "تعذر استخراج رقم الإصدار (INCREMENTAL)"
case "$ID" in *[!A-Za-z0-9._-]*) die "رقم البناء غير صالح: $ID" ;; esac
case "$INCREMENTAL" in ''|*[!0-9]*) die "قيمة INCREMENTAL غير صالحة" ;; esac
say "أحدث بصمة Canary: $ID ($RTVER)"

# --- 5) تاريخ الإصدار والانتهاء التقديري (+ 6 أسابيع) ---
FI_URL=$(grep 'factoryImageDownloadUrl' PIXEL_CANARY_JSON 2>/dev/null | cut -d'"' -f4)
REL=""
EXP=""
if [ -n "$FI_URL" ]; then
    LM=$(get_lastmod "$FI_URL" PIXEL_ZIP_HEADERS)
    if [ -n "$LM" ]; then
        REL=$(date -D '%a, %d %b %Y %H:%M:%S %Z' -d "$LM" '+%Y-%m-%d' 2>/dev/null)
        case "$REL" in ''|*[!0-9-]*) REL="" ;; esac
    fi
fi
if [ -n "$REL" ]; then
    EXP=$(date -D '%s' -d "$(( $(date -D '%Y-%m-%d' -d "$REL" '+%s') + 60 * 60 * 24 * 7 * 6 ))" '+%Y-%m-%d' 2>/dev/null)
    case "$EXP" in ''|*[!0-9-]*) EXP="" ;; esac
fi
[ -z "$REL" ] && REL="Unknown"
[ -z "$EXP" ] && EXP="Unknown"
say "تاريخ الإصدار: $REL | الانتهاء التقديري: $EXP"

# --- 6) الرقعة الأمنية من نشرات أمان Pixel ---
CID=$(grep '"id"' PIXEL_CANARY_JSON 2>/dev/null | sed -e 's;.*canary-\(.*\)".*;\1;' -e 's;^\(.\{4\}\);\1-;' | head -n 1)
if [ -z "$CID" ]; then
    MM=$(printf '%s' "$ID" | grep -oE '[0-9]{6}' | head -n 1 | cut -c1-4)
    case "$MM" in
        [0-9][0-9][0-9][0-9]) CID="20$(printf '%s' "$MM" | cut -c1-2)-$(printf '%s' "$MM" | cut -c3-4)" ;;
    esac
fi
SECURITY_PATCH=""
if [ -n "$CID" ]; then
    if dl "https://source.android.com/docs/security/bulletin/pixel" PIXEL_SECBULL_HTML; then
        SECURITY_PATCH=$(grep "<td>$CID" PIXEL_SECBULL_HTML 2>/dev/null | sed 's;.*<td>\(.*\)</td>.*;\1;' | head -n 1)
    fi
fi
case "$SECURITY_PATCH" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *)
        [ -n "$CID" ] && SECURITY_PATCH="${CID}-05"
        ;;
esac
case "$SECURITY_PATCH" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *) die "تعذر تحديد الرقعة الأمنية" ;;
esac
say "الرقعة الأمنية: $SECURITY_PATCH"

# --- 7) مقارنة مع البصمة الحالية ---
OLD_PROP="$MODDIR/custom.pif.prop"
OLD_ID=""
OLD_FP=""
if [ -f "$OLD_PROP" ]; then
    OLD_ID=$(grep -m1 '^ID=' "$OLD_PROP" 2>/dev/null | cut -d= -f2 | tr -d '\r')
    OLD_FP=$(grep -m1 '^FINGERPRINT=' "$OLD_PROP" 2>/dev/null | cut -d= -f2 | tr -d '\r')
fi
NEW_FP="google/$PRODUCT/$DEVICE:CANARY/$ID/$INCREMENTAL:user/release-keys"
if [ "$OLD_FP" = "$NEW_FP" ] && [ "$FORCE_UPDATE" != "1" ]; then
    ok "أنت بالفعل على أحدث بصمة Canary ($ID) — لم يُغيَّر أي ملف."
    printf 'FALCON_PIF_UPDATE_DONE\n'
    exit 0
fi

# --- 8) الإبقاء على الإعدادات المتقدمة للمستخدم ---
SPOOF_BUILD=$(get_adv spoofBuild 1)
SPOOF_PROPS=$(get_adv spoofProps 1)
SPOOF_PROVIDER=$(get_adv spoofProvider 0)
SPOOF_SIGNATURE=$(get_adv spoofSignature 0)
SPOOF_VENDING_FINGER=$(get_adv spoofVendingFinger 1)
SPOOF_VENDING_SDK=$(get_adv spoofVendingSdk 0)
VERBOSE_LOGS=$(get_adv verboseLogs 0)
SDK_INT=$(get_adv DEVICE_INITIAL_SDK_INT 32)
APIL=$(get_adv '*api_level' "$SDK_INT")

# --- 9) نسخ احتياطية (نحتفظ بآخر 3) ---
case "$OLD_ID" in ''|*[!A-Za-z0-9._-]*) OLD_ID="prev" ;; esac
if [ -s "$OLD_PROP" ]; then
    cp -f "$OLD_PROP" "$MODDIR/custom.pif.prop.bak-$OLD_ID" 2>/dev/null
fi
if [ -s "$MODDIR/custom.pif.json" ]; then
    cp -f "$MODDIR/custom.pif.json" "$MODDIR/custom.pif.json.bak-$OLD_ID" 2>/dev/null
fi
ls -t "$MODDIR"/custom.pif.prop.bak-* 2>/dev/null | tail -n +4 | while read -r X; do rm -f "$X" 2>/dev/null; done
ls -t "$MODDIR"/custom.pif.json.bak-* 2>/dev/null | tail -n +4 | while read -r X; do rm -f "$X" 2>/dev/null; done

# --- 10) كتابة ملف البصمة الجديد ---
NEW_PROP="$WRK/custom.pif.prop.new"
{
    printf '%s\n' "# Build Fields"
    printf 'MANUFACTURER=Google\n'
    printf 'MODEL=%s\n' "$MODEL"
    printf 'FINGERPRINT=%s\n' "$NEW_FP"
    printf 'BRAND=google\n'
    printf 'PRODUCT=%s\n' "$PRODUCT"
    printf 'DEVICE=%s\n' "$DEVICE"
    printf 'RELEASE=CANARY\n'
    printf 'ID=%s\n' "$ID"
    printf 'INCREMENTAL=%s\n' "$INCREMENTAL"
    printf 'TYPE=user\n'
    printf 'TAGS=release-keys\n'
    printf 'SECURITY_PATCH=%s\n' "$SECURITY_PATCH"
    printf 'DEVICE_INITIAL_SDK_INT=%s\n' "$SDK_INT"
    printf '\n%s\n' "# System Properties"
    printf '*.build.id=%s\n' "$ID"
    printf '*.security_patch=%s\n' "$SECURITY_PATCH"
    printf '*api_level=%s\n' "$APIL"
    printf '\n%s\n' "# Advanced Settings"
    printf 'spoofBuild=%s\n' "$SPOOF_BUILD"
    printf 'spoofProps=%s\n' "$SPOOF_PROPS"
    printf 'spoofProvider=%s\n' "$SPOOF_PROVIDER"
    printf 'spoofSignature=%s\n' "$SPOOF_SIGNATURE"
    printf 'spoofVendingFinger=%s\n' "$SPOOF_VENDING_FINGER"
    printf 'spoofVendingSdk=%s\n' "$SPOOF_VENDING_SDK"
    printf 'verboseLogs=%s\n' "$VERBOSE_LOGS"
    printf '\n# Canary Released: %s\n# Estimated Expiry: %s\n' "$REL" "$EXP"
} > "$NEW_PROP" 2>/dev/null

grep -q '^FINGERPRINT=google/' "$NEW_PROP" 2>/dev/null || die "فشل توليد ملف البصمة الجديد"
cp -f "$NEW_PROP" "$MODDIR/custom.pif.prop" 2>/dev/null || die "فشل كتابة custom.pif.prop في مجلد الموديول"
chmod 644 "$MODDIR/custom.pif.prop" 2>/dev/null
ok "كُتبت البصمة الجديدة: $NEW_FP"

# --- 11) مزامنة الرقعة الأمنية (الموديول + Tricky Store) ---
printf 'all=%s\n' "$SECURITY_PATCH" > "$MODDIR/security_patch.txt" 2>/dev/null
TS_SECPAT="/data/adb/tricky_store/security_patch.txt"
if [ -d /data/adb/tricky_store ]; then
    [ -s "$TS_SECPAT" ] || echo "all=" > "$TS_SECPAT" 2>/dev/null
    SPC=$(printf '%s' "$SECURITY_PATCH" | tr -d '-')
    if grep -qE '^[0-9]{8}$' "$TS_SECPAT" 2>/dev/null; then
        sed -i "s/^.*$/$SPC/" "$TS_SECPAT" 2>/dev/null
    fi
    if grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' "$TS_SECPAT" 2>/dev/null; then
        sed -i "s/^.*$/$SECURITY_PATCH/" "$TS_SECPAT" 2>/dev/null
    fi
    if grep -q 'all=' "$TS_SECPAT" 2>/dev/null; then
        sed -i "s/all=.*/all=$SECURITY_PATCH/" "$TS_SECPAT" 2>/dev/null
    fi
    if grep -q 'system=' "$TS_SECPAT" 2>/dev/null; then
        sed -i "s/system=.*/system=$(printf '%s' "$SPC" | cut -c-6)/" "$TS_SECPAT" 2>/dev/null
    fi
fi

# --- 12) تطبيق البصمة (توليد JSON + التوزيع + إعادة تشغيل خدمات جوجل) ---
if [ -f "$MODDIR/apply_pif.sh" ]; then
    say "تطبيق البصمة الجديدة وإعادة تشغيل خدمات جوجل..."
    sh "$MODDIR/apply_pif.sh" force >/dev/null 2>&1
    ok "تم تطبيق البصمة على كل المسارات"
else
    cp -f "$NEW_PROP" /data/adb/pif.prop 2>/dev/null
    killall com.google.android.gms.unstable com.google.android.gms com.android.vending 2>/dev/null
    ok "تم نسخ البصمة (apply_pif.sh غير موجود)"
fi

# --- 13) الملخص ---
printf '\n%s\n' "================ ملخص التحديث ================"
printf '  البصمة القديمة : %s\n' "${OLD_FP:--}"
printf '  البصمة الجديدة : %s\n' "$NEW_FP"
printf '  الرقعة الأمنية  : %s\n' "$SECURITY_PATCH"
printf '  تاريخ الإصدار  : %s\n' "$REL"
printf '  الانتهاء تقديراً: %s\n' "$EXP"
printf '  نسخة احتياطية  : custom.pif.prop.bak-%s\n' "$OLD_ID"
printf '%s\n' "=============================================="
printf 'FALCON_PIF_UPDATE_DONE\n'
exit 0
