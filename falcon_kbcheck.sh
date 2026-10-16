#!/system/bin/sh

# ==============================================================================
# FALCON INTEGRITY FIX — فحص إبطال الكيبوكس لدى جوجل (CRL / attestation status)
# (v3.16) المطور: ABUFARID | تليجرام: @FALCON_KERNEL
#
# الوظيفة:
#   يجلب قائمة الإبطال الرسمية من جوجل:
#       https://android.googleapis.com/attestation/status
#   ويقارن أرقام شهادات الكيبوكس (Serial) بها لمعرفة إن كان الكيبوكس
#   مُبطَلاً (Soft-Ban) أم سليماً.
#
#   ملاحظة رسمية من جوجل: مفاتيح القائمة هي رقم الشهادة بصيغة Hex بحروف
#   صغيرة مع إزالة الأصفار البادئة.
#
# الاستخدام:
#   sh falcon_kbcheck.sh [--force] [SERIAL1 SERIAL2 ...]
#   - --force : أجبر تحديث القائمة من الإنترنت حتى لو الكاش حديث.
#   - SERIAL  : رقم شهادة بصيغة hex صغيرة (يُطابق بعد إزالة الأصفار).
#
# المخرجات (سطور قابلة للتحليل — لا شيء غيرها):
#   INFO|STATE=FRESH|AGE=0|SIZE=179615|DATE=2026-10-16 12:00|PATH=/data/adb/falcon/crl/attestation-status.json
#   SER|a1b2c3|OK
#   SER|deadbeef|REVOKED|KEY_COMPROMISE|تعليق
#
# ملاحظات أمان:
#   • لا يمس أي ملف للمستخدم — يكتب فقط داخل /data/adb/falcon/crl/
#   • لا يُشغَّل تلقائياً عند الإقلاع — فقط عند طلب المستخدم من الواجهة.
#   • بلا أي حلقات انتظار — شبكة محدودة بزمن أقصى ثم ينتهي فوراً.
# ==============================================================================

MODDIR="${0%/*}"
[ -n "$MODDIR" ] && [ -d "$MODDIR" ] || MODDIR="/data/adb/modules/playintegrityfix"

FALCON_DIR="/data/adb/falcon"
CRL_DIR="$FALCON_DIR/crl"
JSON="$CRL_DIR/attestation-status.json"
NEWJSON="$CRL_DIR/attestation-status.json.new"
COMPACT="$CRL_DIR/attestation-status.compact.json"
URL="https://android.googleapis.com/attestation/status"
TTL=43200

mkdir -p "$CRL_DIR" 2>/dev/null

FORCE=0
SERIALS=""
for A in "$@"; do
    case "$A" in
        --force|-f) FORCE=1 ;;
        '') ;;
        *) SERIALS="$SERIALS $A" ;;
    esac
done

# --- البحث عن busybox (لسطر الأوامر الاحتياطي عند غياب curl/wget) ---
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

# --- تنزيل ملف: curl ثم busybox wget ثم wget النظامي ---
dl() {
    local tmp="$2.tmp"
    rm -f "$tmp" 2>/dev/null
    if command -v curl >/dev/null 2>&1; then
        curl -k -L -sS --connect-timeout 10 -m 45 -o "$tmp" "$1" 2>/dev/null
        if [ -s "$tmp" ]; then mv -f "$tmp" "$2" 2>/dev/null; return 0; fi
    fi
    find_busybox
    if [ -n "$BUSYBOX" ]; then
        "$BUSYBOX" wget -q -T 45 --no-check-certificate -O "$tmp" "$1" 2>/dev/null
        if [ -s "$tmp" ]; then mv -f "$tmp" "$2" 2>/dev/null; return 0; fi
    fi
    if command -v wget >/dev/null 2>&1; then
        wget -q --no-check-certificate -O "$tmp" "$1" 2>/dev/null || wget -q -O "$tmp" "$1" 2>/dev/null
        if [ -s "$tmp" ]; then mv -f "$tmp" "$2" 2>/dev/null; return 0; fi
    fi
    rm -f "$tmp" 2>/dev/null
    return 1
}

# --- عمر ملف بالثواني (فارغ إن تعذّر الحساب) ---
file_age() {
    [ -s "$1" ] || return 0
    local mt=""
    mt=$(stat -c %Y "$1" 2>/dev/null)
    [ -z "$mt" ] && mt=$(date -r "$1" +%s 2>/dev/null)
    case "$mt" in ''|*[!0-9]*) return 0 ;; esac
    local now=""
    now=$(date +%s 2>/dev/null)
    case "$now" in ''|*[!0-9]*) return 0 ;; esac
    [ "$now" -ge "$mt" ] && echo $((now - mt))
}

# --- قرار التحديث ---
NEED=0
[ "$FORCE" = "1" ] && NEED=1
[ -s "$JSON" ] || NEED=1
if [ "$NEED" = "0" ]; then
    AGE0=$(file_age "$JSON")
    case "$AGE0" in
        ''|*[!0-9]*) NEED=1 ;;
        *) [ "$AGE0" -gt "$TTL" ] && NEED=1 ;;
    esac
fi

STATE=CACHED
if [ "$NEED" = "1" ]; then
    if dl "$URL" "$NEWJSON"; then
        if grep -q '"entries"' "$NEWJSON" 2>/dev/null; then
            mv -f "$NEWJSON" "$JSON" 2>/dev/null
            STATE=FRESH
        else
            rm -f "$NEWJSON" 2>/dev/null
            [ -s "$JSON" ] && STATE=STALE || STATE=NONE
        fi
    else
        rm -f "$NEWJSON" 2>/dev/null
        [ -s "$JSON" ] && STATE=STALE || STATE=NONE
    fi
else
    STATE=CACHED
fi

# --- بناء النسخة المضغوطة (سطر واحد) لتسريع البحث ---
if [ -s "$JSON" ]; then
    tr -d ' \t\r\n' < "$JSON" > "$COMPACT" 2>/dev/null
    [ -s "$COMPACT" ] || cp -f "$JSON" "$COMPACT" 2>/dev/null
fi

AGE=$(file_age "$JSON")
SIZE=""
[ -s "$JSON" ] && SIZE=$(wc -c < "$JSON" 2>/dev/null | tr -d ' ')
case "$SIZE" in ''|*[!0-9]*) SIZE="-" ;; esac
case "$AGE" in ''|*[!0-9]*) AGE="-" ;; esac
DATE="-"
if [ -s "$JSON" ]; then
    DATE=$(date -r "$JSON" '+%Y-%m-%d %H:%M' 2>/dev/null)
    [ -z "$DATE" ] && DATE="-"
fi

printf 'INFO|STATE=%s|AGE=%s|SIZE=%s|DATE=%s|PATH=%s\n' "$STATE" "$AGE" "$SIZE" "$DATE" "$JSON"

# --- فحص الأرقام المطلوبة ---
if [ -n "$SERIALS" ]; then
    for S in $SERIALS; do
        case "$S" in
            ''|*[!0-9a-fA-F]*) continue ;;
        esac
        S=$(printf '%s' "$S" | tr 'A-F' 'a-f')
        if [ -s "$COMPACT" ]; then
            HIT=$(grep -o -E "\"${S}\":.{0,200}" "$COMPACT" 2>/dev/null | head -n 1)
            if [ -z "$HIT" ]; then
                printf 'SER|%s|OK\n' "$S"
            else
                ST=$(printf '%s' "$HIT" | sed -n 's/.*"status":"\([A-Za-z]*\)".*/\1/p')
                RS=$(printf '%s' "$HIT" | sed -n 's/.*"reason":"\([A-Za-z_]*\)".*/\1/p')
                CM=$(printf '%s' "$HIT" | sed -n 's/.*"comment":"\([^"]*\)".*/\1/p')
                [ -z "$ST" ] && ST="LISTED"
                printf 'SER|%s|%s|%s|%s\n' "$S" "$ST" "$RS" "$CM"
            fi
        else
            printf 'SER|%s|UNKNOWN\n' "$S"
        fi
    done
fi

exit 0
