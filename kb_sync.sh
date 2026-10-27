#!/system/bin/sh

# ==============================================================================
# FALCON INTEGRITY FIX — مزامنة الكيبوكس التلقائية (مدمجة في الموديول — v3.17)
# جلب كيبوكس جديد تلقائياً من مصادر عامة عند إبطال القديم + فحص CRL قبل التثبيت
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
#
# الاستخدام:
#   sh kb_sync.sh --check  : فحص الكيبوكس الحالي في CRL فقط (بلا تعديل)
#   sh kb_sync.sh --now    : جلب أحدث كيبوكس الآن من المصادر (زر الواجهة)
#   sh kb_sync.sh --auto   : فحص؛ وإن كان مُبطلاً/مفقوداً → جلب تلقائي (الخدمة)
#
# المخرجات النهائية: FALCON_KS_RESULT=OK|REVOKED|NOCHANGE|FAIL + FALCON_KS_DONE
# ==============================================================================

MODDIR="${0%/*}"
[ -n "$MODDIR" ] && [ -d "$MODDIR" ] || MODDIR="/data/adb/modules/playintegrityfix"

STATE="/data/adb/falcon_keysync"
LOG="$STATE/kb_sync.log"
CRL_DIR="$STATE/crl"
CRL_JSON="$CRL_DIR/status.json"
CRL_COMPACT="$CRL_DIR/status.compact.json"
CRL_URL="https://android.googleapis.com/attestation/status"
SRC_FILE="$STATE/sources.conf"
SRC_DEFAULT="$MODDIR/sources.conf"
TARGET="/data/adb/tricky_store/keybox.xml"
TARGET2="/data/adb/teesim/keybox.xml"
TMP="$STATE/tmp"
BACKUP_DIR="$STATE/backup"

MODE="auto"
for A in "$@"; do
    case "$A" in
        --check|-c|check) MODE="check" ;;
        --now|-n|now)     MODE="now" ;;
        --auto|-a|auto)   MODE="auto" ;;
    esac
done

mkdir -p "$STATE" "$CRL_DIR" "$TMP" "$BACKUP_DIR" 2>/dev/null

# --- سجل ---
ts() { date '+%Y-%m-%d %H:%M:%S' 2>/dev/null; }
logline() {
    printf '[%s] %s\n' "$(ts)" "$1"
    printf '[%s] %s\n' "$(ts)" "$1" >> "$LOG" 2>/dev/null
}
say() { logline "[➜] $1"; }
ok()  { logline "[✔] $1"; }
err() { logline "[✖] $1"; }

# --- عمر ملف/مجلد بالثواني ---
file_age() {
    [ -e "$1" ] || return 0
    local mt="" now=""
    mt=$(stat -c %Y "$1" 2>/dev/null)
    [ -z "$mt" ] && mt=$(date -r "$1" +%s 2>/dev/null)
    case "$mt" in ''|*[!0-9]*) return 0 ;; esac
    now=$(date +%s 2>/dev/null)
    case "$now" in ''|*[!0-9]*) return 0 ;; esac
    [ "$now" -ge "$mt" ] && echo $((now - mt))
}

# --- قفل بسيط ضد التشغيل المزدوج (يُفتح تلقائياً بعد 15 دقيقة لو علِق) ---
if ! mkdir "$STATE/lock" 2>/dev/null; then
    LAGE=$(file_age "$STATE/lock")
    case "$LAGE" in ''|*[!0-9]*) LAGE=0 ;; esac
    if [ "$LAGE" -gt 900 ] 2>/dev/null; then
        rmdir "$STATE/lock" 2>/dev/null
        mkdir "$STATE/lock" 2>/dev/null || { echo "[!] تعذر فتح القفل"; exit 1; }
    else
        echo "[!] عملية أخرى جارية بالفعل — انتظر انتهاءها ثم أعد المحاولة"
        exit 1
    fi
fi
trap 'rmdir "$STATE/lock" 2>/dev/null' EXIT

CRL_TTL=10800
[ -f "$STATE/crl_ttl" ] && CRL_TTL=$(cat "$STATE/crl_ttl" 2>/dev/null)
case "$CRL_TTL" in ''|*[!0-9]*) CRL_TTL=10800 ;; esac
[ "$CRL_TTL" -lt 300 ] 2>/dev/null && CRL_TTL=300

FIN=""
REV_SERIAL=""
REV_STATUS=""
SER_LIST=""

# --- busybox ---
BUSYBOX=""
find_busybox() {
    [ -n "$BUSYBOX" ] && return 0
    local p
    for p in /data/adb/modules/busybox-ndk/system/*/busybox /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox; do
        if [ -f "$p" ]; then BUSYBOX="$p"; return 0; fi
    done
    return 1
}
find_busybox 2>/dev/null

# --- أداة od (لفحص CRL) ---
ODCMD=""
pick_od() {
    [ -n "$ODCMD" ] && return 0
    if printf 'A' | od -An -v -tx1 2>/dev/null | grep -q '41'; then ODCMD="od"; return 0; fi
    if [ -n "$BUSYBOX" ] && printf 'A' | "$BUSYBOX" od -An -v -tx1 2>/dev/null | grep -q '41'; then ODCMD="$BUSYBOX od"; return 0; fi
    return 1
}

# --- تنزيل: curl ثم busybox wget ثم wget النظامي ---
dl() {
    local tmp="$2.tmp"
    rm -f "$tmp" 2>/dev/null
    if command -v curl >/dev/null 2>&1; then
        curl -k -L -sS --connect-timeout 12 -m 60 -o "$tmp" "$1" 2>/dev/null
        if [ -s "$tmp" ]; then mv -f "$tmp" "$2" 2>/dev/null; return 0; fi
    fi
    if [ -n "$BUSYBOX" ]; then
        "$BUSYBOX" wget -q -T 60 --no-check-certificate -O "$tmp" "$1" 2>/dev/null
        if [ -s "$tmp" ]; then mv -f "$tmp" "$2" 2>/dev/null; return 0; fi
    fi
    if command -v wget >/dev/null 2>&1; then
        wget -q --no-check-certificate -O "$tmp" "$1" 2>/dev/null || wget -q -O "$tmp" "$1" 2>/dev/null
        if [ -s "$tmp" ]; then mv -f "$tmp" "$2" 2>/dev/null; return 0; fi
    fi
    rm -f "$tmp" 2>/dev/null
    return 1
}

# --- فك الترميز ---
dec_b64x() {
    cp -f "$1" "$2" 2>/dev/null
    local i=0
    while [ "$i" -lt 8 ]; do
        grep -q '<' "$2" 2>/dev/null && return 0
        head -c 512 "$2" 2>/dev/null | grep -qE '^[A-Za-z0-9+/=[:space:]]+$' || return 1
        if base64 -d "$2" > "$2.n" 2>/dev/null && [ -s "$2.n" ]; then
            mv -f "$2.n" "$2" 2>/dev/null
        elif [ -n "$BUSYBOX" ] && "$BUSYBOX" base64 -d "$2" > "$2.n" 2>/dev/null && [ -s "$2.n" ]; then
            mv -f "$2.n" "$2" 2>/dev/null
        else
            rm -f "$2.n" 2>/dev/null
            return 1
        fi
        i=$((i+1))
    done
    return 1
}

dec_hex() {
    local h=""
    h=$(tr -d '[:space:]' < "$1" 2>/dev/null)
    case "$h" in ''|*[!0-9a-fA-F]*) return 1 ;; esac
    [ $(( ${#h} % 2 )) -eq 0 ] || return 1
    h=$(printf '%s' "$h" | tr 'A-F' 'a-f')
    if command -v xxd >/dev/null 2>&1; then
        printf '%s' "$h" | xxd -r -p > "$2" 2>/dev/null
    fi
    if [ ! -s "$2" ] && [ -n "$BUSYBOX" ]; then
        printf '%s' "$h" | "$BUSYBOX" xxd -r -p > "$2" 2>/dev/null
    fi
    if [ ! -s "$2" ]; then
        printf '%s' "$h" | awk '
        { line = $0 }
        function hexdec(x,  c1, c2) {
            c1 = index("0123456789abcdef", substr(x,1,1)) - 1
            c2 = index("0123456789abcdef", substr(x,2,1)) - 1
            return c1*16 + c2
        }
        END {
            for (i=1;i<=length(line);i+=2) printf "%c", hexdec(substr(line,i,2))
        }
        ' > "$2" 2>/dev/null
    fi
    [ -s "$2" ]
}

dec_rot13() {
    tr 'A-Za-z' 'N-ZA-Mn-za-m' < "$1" > "$2" 2>/dev/null
    [ -s "$2" ]
}

# --- التحقق من بنية الكيبوكس ---
kb_valid() {
    local f="$1" n=""
    [ -s "$f" ] || return 1
    grep -q '<AndroidAttestation' "$f" 2>/dev/null || return 1
    grep -q '</AndroidAttestation>' "$f" 2>/dev/null || return 1
    grep -q 'BEGIN.*PRIVATE KEY' "$f" 2>/dev/null || return 1
    if ! grep -q 'algorithm="rsa"' "$f" 2>/dev/null && ! grep -q 'algorithm="ecdsa"' "$f" 2>/dev/null; then
        return 1
    fi
    n=$(grep -c 'BEGIN CERTIFICATE' "$f" 2>/dev/null)
    case "$n" in ''|*[!0-9]*) return 1 ;; esac
    [ "$n" -ge 2 ] || return 1
    return 0
}

# --- خطوط فك الترميز (تُجرَّب بالترتيب حتى يظهر XML صالح) ---
try_pipeline() {
    cp -f "$1" "$TMP/p.cur" 2>/dev/null
    local s
    for s in $3; do
        grep -q '<AndroidAttestation' "$TMP/p.cur" 2>/dev/null && break
        case "$s" in
            b64x)  dec_b64x "$TMP/p.cur" "$TMP/p.n" || return 1 ;;
            hex)   dec_hex  "$TMP/p.cur" "$TMP/p.n" || return 1 ;;
            rot13) dec_rot13 "$TMP/p.cur" "$TMP/p.n" || return 1 ;;
        esac
        mv -f "$TMP/p.n" "$TMP/p.cur" 2>/dev/null
    done
    cp -f "$TMP/p.cur" "$2" 2>/dev/null
    kb_valid "$2"
}

decode_file() {
    local P="" pipe="" OLDIFS=""
    case "$3" in
        b64)    P="b64x|b64x hex|b64x hex rot13|hex b64x|plain" ;;
        hex)    P="hex b64x|hex|b64x hex|plain" ;;
        b64hex) P="b64x hex rot13|b64x hex|b64x|hex b64x|plain" ;;
        *)      P="plain|b64x|hex b64x|b64x hex|b64x hex rot13" ;;
    esac
    OLDIFS="$IFS"; IFS='|'
    for pipe in $P; do
        IFS="$OLDIFS"
        if try_pipeline "$1" "$2" "$pipe"; then return 0; fi
        IFS='|'
    done
    IFS="$OLDIFS"
    return 1
}

# --- استخراج أرقام الشهادات (Serial) من كيبوكس ---
kb_serials() {
    local f="$1" c="" s=""
    rm -f "$TMP"/ser*.pem "$TMP"/ser*.der "$TMP"/ser*.b64 2>/dev/null
    awk -v dir="$TMP" '
    /-----BEGIN CERTIFICATE-----/ { i++; out = dir "/ser" i ".pem" }
    out != "" { print > out }
    /-----END CERTIFICATE-----/ { out = "" }
    ' "$f" 2>/dev/null
    for c in "$TMP"/ser*.pem; do
        [ -s "$c" ] || continue
        sed '1d;$d' "$c" 2>/dev/null | tr -d '\r\n' > "$c.b64" 2>/dev/null
        base64 -d "$c.b64" > "$c.der" 2>/dev/null
        if [ ! -s "$c.der" ] && [ -n "$BUSYBOX" ]; then
            "$BUSYBOX" base64 -d "$c.b64" > "$c.der" 2>/dev/null
        fi
        [ -s "$c.der" ] || continue
        s=$($ODCMD -An -v -tx1 "$c.der" 2>/dev/null | awk '
        { for (i=1;i<=NF;i++) hex = hex $i }
        function hexdec(h,  c1, c2) {
            c1 = index("0123456789abcdef", substr(h,1,1)) - 1
            c2 = index("0123456789abcdef", substr(h,2,1)) - 1
            return c1*16 + c2
        }
        function bval(p) { return hexdec(substr(hex, p*2+1, 2)) }
        function tlv(p,  l0, nb, i, len) {
            l0 = bval(p+1)
            if (l0 < 128) { CONT = p+2; LEN = l0; return }
            nb = l0 - 128
            len = 0
            for (i=0;i<nb;i++) len = len*256 + bval(p+2+i)
            CONT = p+2+nb; LEN = len
        }
        END {
            tlv(0)
            p = CONT
            tlv(p)
            p = CONT
            if (bval(p) == 160) { tlv(p); p = CONT + LEN }
            tlv(p)
            s = substr(hex, CONT*2+1, LEN*2)
            while (length(s) > 2 && substr(s,1,2) == "00") s = substr(s,3)
            print s
        }
        ' 2>/dev/null)
        s=$(printf '%s' "$s" | tr 'A-F' 'a-f' | tr -d ' \t\r\n')
        case "$s" in ''|*[!0-9a-f]*) continue ;; esac
        s=$(printf '%s' "$s" | sed 's/^0*//')
        [ -z "$s" ] && s=0
        printf '%s\n' "$s"
    done
}

# --- قائمة الإبطال CRL ---
crl_ensure() {
    local force="$1" age="" NEED=0
    [ "$force" = "1" ] && NEED=1
    [ -s "$CRL_JSON" ] || NEED=1
    if [ "$NEED" = "0" ]; then
        age=$(file_age "$CRL_JSON")
        case "$age" in ''|*[!0-9]*) NEED=1 ;; *) [ "$age" -gt "$CRL_TTL" ] && NEED=1 ;; esac
    fi
    CRL_STATE=CACHED
    if [ "$NEED" = "1" ]; then
        if dl "$CRL_URL" "$CRL_JSON.new" && grep -q '"entries"' "$CRL_JSON.new" 2>/dev/null; then
            mv -f "$CRL_JSON.new" "$CRL_JSON" 2>/dev/null
            CRL_STATE=FRESH
        else
            rm -f "$CRL_JSON.new" 2>/dev/null
            if [ -s "$CRL_JSON" ]; then CRL_STATE=STALE; else CRL_STATE=NONE; fi
        fi
    fi
    if [ -s "$CRL_JSON" ]; then
        tr -d ' \t\r\n' < "$CRL_JSON" > "$CRL_COMPACT" 2>/dev/null
        [ -s "$CRL_COMPACT" ] || cp -f "$CRL_JSON" "$CRL_COMPACT" 2>/dev/null
    fi
}

crl_status_serial() {
    local s="$1" hit="" st=""
    [ -s "$CRL_COMPACT" ] || { echo UNKNOWN; return; }
    hit=$(grep -o -E "\"$s\":.{0,200}" "$CRL_COMPACT" 2>/dev/null | head -n 1)
    if [ -z "$hit" ]; then echo OK; return; fi
    st=$(printf '%s' "$hit" | sed -n 's/.*"status":"\([A-Za-z]*\)".*/\1/p')
    [ -z "$st" ] && st=LISTED
    echo "$st"
}

# --- فحص ملف كيبوكس: 0=سليم 1=مُبطَل 2=بنية سيئة 3=CRL غير متاح ---
check_keybox_file() {
    local f="$1" s="" st="" bad=0
    kb_valid "$f" || return 2
    pick_od || return 3
    SER_LIST=$(kb_serials "$f")
    [ -n "$SER_LIST" ] || return 2
    for s in $SER_LIST; do
        st=$(crl_status_serial "$s")
        case "$st" in
            OK) : ;;
            UNKNOWN) [ "$bad" != "1" ] && bad=3 ;;
            *) bad=1; REV_SERIAL="$s"; REV_STATUS="$st" ;;
        esac
    done
    [ "$bad" = "1" ] && return 1
    [ "$bad" = "3" ] && return 3
    return 0
}

# --- تثبيت الكيبوكس الجديد ---
install_kb() {
    local d="" PREF="" SLOT=""
    if [ -s "$TARGET" ]; then
        d="$BACKUP_DIR/keybox-$(date '+%Y%m%d-%H%M%S' 2>/dev/null).xml"
        cp -f "$TARGET" "$d" 2>/dev/null
    fi
    if [ -s "/data/adb/falcon/keybox.xml" ]; then
        cp -f "/data/adb/falcon/keybox.xml" "$BACKUP_DIR/keybox-user-$(date '+%Y%m%d-%H%M%S' 2>/dev/null).xml" 2>/dev/null
    fi
    ls -t "$BACKUP_DIR"/keybox-*.xml 2>/dev/null | tail -n +4 | while read -r x; do rm -f "$x" 2>/dev/null; done
    mkdir -p "/data/adb/tricky_store" "/data/adb/falcon" "/data/adb/falcon/keybox_slots/backups" 2>/dev/null
    [ -L "$TARGET" ] && rm -f "$TARGET" 2>/dev/null
    cp -f "$1" "$TARGET" 2>/dev/null || return 1
    chmod 644 "$TARGET" 2>/dev/null
    chown root:root "$TARGET" 2>/dev/null
    chcon u:object_r:system_file:s0 "$TARGET" 2>/dev/null
    # (v3.23) احترام تفضيل المنفذ: الثانوي إن كان مفعّلاً، وإلا الأساسي.
    PREF="$(cat "/data/adb/falcon/keybox_slots/preferred" 2>/dev/null | tr -d ' \t\r\n')"
    case "$PREF" in
        secondary) SLOT="/data/adb/falcon/keybox2.xml" ;;
        *)         SLOT="/data/adb/falcon/keybox.xml" ;;
    esac
    [ -L "$SLOT" ] && rm -f "$SLOT" 2>/dev/null
    if [ -s "$SLOT" ]; then
        cp -f "$SLOT" "/data/adb/falcon/keybox_slots/backups/slot-$(date '+%Y%m%d-%H%M%S' 2>/dev/null).xml" 2>/dev/null
        ls -t "/data/adb/falcon/keybox_slots/backups/slot-"*.xml 2>/dev/null | tail -n +4 | while read -r x; do rm -f "$x" 2>/dev/null; done
    fi
    cp -f "$1" "$SLOT" 2>/dev/null
    chmod 600 "$SLOT" 2>/dev/null
    chown root:root "$SLOT" 2>/dev/null
    say "تم تثبيت الكيبوكس في المنفذ: $SLOT"
    if [ -d "/data/adb/teesim" ]; then
        [ -L "$TARGET2" ] && rm -f "$TARGET2" 2>/dev/null
        cp -f "$1" "$TARGET2" 2>/dev/null
        chmod 644 "$TARGET2" 2>/dev/null
        chown root:root "$TARGET2" 2>/dev/null
    fi
    return 0
}

kill_gms() {
    killall -9 com.google.android.gms.unstable com.android.vending 2>/dev/null
    am force-stop com.google.android.gms.unstable 2>/dev/null
}

# --- جلب جديد من المصادر: 0=ثُبّت 2=مطابق 1=فشل ---
fetch_new() {
    local name="" url="" hint="" cand="" tried=0 s="" st="" bad=""
    [ -f "$SRC_FILE" ] || SRC_FILE="$SRC_DEFAULT"
    [ -f "$SRC_FILE" ] || { err "ملف المصادر غير موجود"; return 1; }
    while IFS='|' read -r name url hint; do
        name=$(printf '%s' "$name" | tr -d '\r')
        case "$name" in ''|'#'*) continue ;; esac
        url=$(printf '%s' "$url" | tr -d ' \t\r\n')
        hint=$(printf '%s' "$hint" | tr -d ' \t\r\n')
        [ -n "$url" ] || continue
        tried=$((tried+1))
        say "المصدر $tried: $name"
        cand="$TMP/cand.bin"
        rm -f "$cand" "$TMP/cand.xml" 2>/dev/null
        if ! dl "$url" "$cand"; then err "فشل التنزيل — المصدر التالي"; continue; fi
        ok "نُزّل ($(wc -c < "$cand" 2>/dev/null | tr -d ' ') بايت)"
        if ! decode_file "$cand" "$TMP/cand.xml" "$hint"; then err "فك الترميز/البنية فشل — التالي"; continue; fi
        ok "بنية سليمة ($(grep -c 'BEGIN CERTIFICATE' "$TMP/cand.xml" 2>/dev/null) شهادات)"
        if ! pick_od; then err "أداة od غير متوفرة — لا يمكن فحص CRL"; continue; fi
        SER_LIST=$(kb_serials "$TMP/cand.xml")
        bad=0
        for s in $SER_LIST; do
            st=$(crl_status_serial "$s")
            case "$st" in
                OK) : ;;
                UNKNOWN) [ "$bad" != "1" ] && bad=3 ;;
                *) bad=1; REV_SERIAL="$s"; REV_STATUS="$st" ;;
            esac
        done
        if [ "$bad" = "1" ]; then err "الجديد مُبطَل في CRL ($REV_SERIAL $REV_STATUS) — التالي"; continue; fi
        if [ "$bad" = "3" ]; then err "CRL غير متاح لفحص الجديد — لن نثبّت بلا فحص"; continue; fi
        ok "الجديد نظيف في CRL"
        if [ -s "$TARGET" ] && cmp -s "$TMP/cand.xml" "$TARGET"; then
            ok "المثبّت مطابق لأحدث مصدر — لا تغيير"
            return 2
        fi
        if install_kb "$TMP/cand.xml"; then
            ok "ثُبّت الكيبوكس الجديد"
            say "إعادة تشغيل خدمات جوجل لتطبيق الجديد..."
            kill_gms
            ok "تم"
            return 0
        fi
        err "فشل التثبيت — التالي"
    done < "$SRC_FILE"
    return 1
}

# ============================ التشغيل ============================
KS_REV=0
case "$MODE" in
    check)
        say "فحص الكيبوكس الحالي: $TARGET"
        if [ ! -s "$TARGET" ]; then
            err "لا يوجد كيبوكس مثبت"
            FIN=FAIL
        else
            crl_ensure 0
            say "قائمة CRL: $CRL_STATE"
            check_keybox_file "$TARGET"
            rc=$?
            case "$rc" in
                0) ok "الكيبوكس سليم — لا إبطال في CRL"; FIN=OK ;;
                1) err "الكيبوكس مُبطَل: $REV_SERIAL ($REV_STATUS)"; FIN=REVOKED ;;
                2) err "بنية الكيبوكس غير سليمة"; FIN=FAIL ;;
                *) err "تعذر فحص CRL (إنترنت؟)"; FIN=FAIL ;;
            esac
        fi
        ;;
    now)
        say "جلب أحدث كيبوكس الآن (يدوي)"
        crl_ensure 1
        say "قائمة CRL: $CRL_STATE"
        if [ ! -s "$CRL_COMPACT" ]; then
            err "تعذر جلب قائمة CRL — يلزم اتصال إنترنت"
            FIN=FAIL
        else
            CUR_OK=0
            if [ -s "$TARGET" ]; then
                check_keybox_file "$TARGET"
                rc=$?
                case "$rc" in
                    0) CUR_OK=1; say "الحالي سليم — سنجلب الأحدث رغم ذلك (طلب يدوي)" ;;
                    1) KS_REV=1; say "الحالي مُبطَل ($REV_SERIAL) — جلب بديل" ;;
                    *) say "الحالي غير صالح — جلب بديل" ;;
                esac
            else
                say "لا يوجد كيبوكس مثبت — جلب أول"
            fi
            fetch_new
            fr=$?
            case "$fr" in
                0) FIN=OK ;;
                2) FIN=NOCHANGE ;;
                *) if [ "$CUR_OK" = "1" ]; then ok "تعذر جلب مصدر أحدث — أبقينا الكيبوكس الحالي السليم"; FIN=NOCHANGE; else FIN=FAIL; fi ;;
            esac
        fi
        ;;
    *)
        if [ ! -s "$TARGET" ]; then
            say "[auto] لا يوجد كيبوكس — جلب تلقائي أول"
            crl_ensure 0
            if [ -s "$CRL_COMPACT" ]; then
                fetch_new >/dev/null 2>&1
                case "$?" in 0) FIN=OK ;; 2) FIN=NOCHANGE ;; *) FIN=FAIL ;; esac
            else
                err "[auto] تعذر جلب قائمة CRL — لا جلب بلا فحص"
                FIN=FAIL
            fi
        else
            crl_ensure 0
            check_keybox_file "$TARGET"
            rc=$?
            if [ "$rc" = "1" ] || [ "$rc" = "2" ]; then
                [ "$rc" = "1" ] && KS_REV=1
                say "[auto] الحالة=$rc $REV_SERIAL $REV_STATUS — جلب تلقائي"
                if [ -s "$CRL_COMPACT" ]; then
                    fetch_new >/dev/null 2>&1
                    case "$?" in 0) FIN=OK ;; 2) FIN=NOCHANGE ;; *) FIN=FAIL ;; esac
                else
                    FIN=FAIL
                fi
            elif [ "$rc" = "0" ]; then
                logline "[auto] CRL سليم — لا تغيير"
                FIN=NOCHANGE
            else
                logline "[auto] CRL غير متاح — لا تغيير"
                FIN=NOCHANGE
            fi
        fi
        ;;
esac

# --- (v3.19) تحديث مؤشر صحة الكيبوكس في وصف الوحدة ---
mkdir -p "$STATE" 2>/dev/null
case "$FIN" in
    OK)       printf 'OK %s\n' "$(date '+%Y-%m-%d %H:%M')" > "$STATE/kb_state" 2>/dev/null ;;
    NOCHANGE) [ -s "$STATE/kb_state" ] || printf 'OK %s\n' "$(date '+%Y-%m-%d %H:%M')" > "$STATE/kb_state" 2>/dev/null ;;
    REVOKED)  printf 'REVOKED %s\n' "$(date '+%Y-%m-%d %H:%M')" > "$STATE/kb_state" 2>/dev/null ;;
    *)        [ "$KS_REV" = "1" ] && printf 'REVOKED %s\n' "$(date '+%Y-%m-%d %H:%M')" > "$STATE/kb_state" 2>/dev/null ;;
esac

echo "FALCON_KS_RESULT=${FIN:-UNKNOWN}"
echo "FALCON_KS_DONE"

# --- تدوير السجل عند الكبر ---
sz=$(wc -c < "$LOG" 2>/dev/null | tr -d ' ')
case "$sz" in
    ''|*[!0-9]*) ;;
    *) if [ "$sz" -gt 200000 ]; then tail -c 100000 "$LOG" > "$LOG.tmp" 2>/dev/null && mv -f "$LOG.tmp" "$LOG" 2>/dev/null; fi ;;
esac

exit 0
