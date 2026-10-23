#!/system/bin/sh

# ==============================================================================
# إصلاح فحص الحماية FALCON INTEGRITY FIX - تطبيق ملف البصمة (PIF)
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
#
# الوظيفة:
#   يحوّل ملف البصمة بصيغة PIFork  (custom.pif.prop  →  KEY=value)
#   إلى صيغة JSON (custom.pif.json) ويوزّعه على كل المسارات المحتملة،
#   لأن بعض الأجهزة لا ينقل الملف تلقائياً إلى مسار PIF الصحيح.
#
# الأوضاع:
#   sh apply_pif.sh auto    ← يطبّق فقط إذا كان ملف المسار الأساسي مفقوداً أو فارغ البصمة
#   sh apply_pif.sh force   ← يعيد التطبيق دائماً من custom.pif.prop (من زر WebUI)
#   sh apply_pif.sh ensure  ← إقلاع مبكر (post-fs-data): يملأ الفراغات فقط بلا إيقاف GMS
# ==============================================================================

# --- مجلد الموديول = مسار المحرك نفسه (playintegrityfix) ---
# محرك libplayintegrityfix.so يقرأ ملفاته من /data/adb/modules/playintegrityfix/
# ولأن معرّف موديولنا صار playintegrityfix فالمجلد مطابق تماماً (لا حاجة لنسخ لمسار آخر).
MODDIR="${0%/*}"
[ -n "$MODDIR" ] && [ -d "$MODDIR" ] || MODDIR="/data/adb/modules/playintegrityfix"

PIFD="/data/adb/modules/playintegrityfix"

FALCON_DIR="/data/adb/falcon"
LOG="/data/adb/falcon_pif.log"
mkdir -p "$FALCON_DIR" 2>/dev/null
mkdir -p /data/adb 2>/dev/null

MODE="$1"
case "$MODE" in
    force|auto|ensure) ;;
    *) MODE="auto" ;;
esac

say() {
    [ "$MODE" = "force" ] && echo "$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null) | $1" >> "$LOG" 2>/dev/null
}

# --- قراءة قيمة من ملف بصيغة KEY=value (بدون أي مشاكل رموز) ---
pv() {
    awk -v k="$1" 'index($0, k"=")==1 { print substr($0, length(k)+2); exit }' "$PROP_SRC" 2>/dev/null | tr -d '\r'
}

# --- التحقق من صلاحية ملف بصمة JSON (يحتوي FINGERPRINT غير فارغ) ---
valid_pif() {
    [ -s "$1" ] && grep -qE '"FINGERPRINT"[[:space:]]*:[[:space:]]*"[^"]' "$1" 2>/dev/null
}

# --- البحث عن ملف البصمة بصيغة prop ---
PROP_SRC=""
for C in "$MODDIR/custom.pif.prop" "/data/adb/pif.prop" "/sdcard/custom.pif.prop" "/storage/emulated/0/custom.pif.prop" "/sdcard/Download/custom.pif.prop"; do
    [ -f "$C" ] && PROP_SRC="$C" && break
done

# --- تحديد ما إذا كنا بحاجة للتطبيق ---
CUR_PIF="/data/adb/pif.json"
NEED_APPLY=0
if [ "$MODE" = "force" ]; then
    NEED_APPLY=1
elif ! valid_pif "$CUR_PIF"; then
    NEED_APPLY=1
elif ! valid_pif "$PIFD/custom.pif.json" && ! valid_pif "$PIFD/pif.json"; then
    NEED_APPLY=1
elif [ ! -s "$PIFD/classes.dex" ] && [ -s "$MODDIR/classes.dex" ]; then
    NEED_APPLY=1
fi

if [ "$NEED_APPLY" = "0" ]; then
    say "ℹ️ ملف البصمة الحالي صالح — لا حاجة لإعادة التطبيق."
    exit 0
fi

if [ -z "$PROP_SRC" ]; then
    say "✖ لم يتم العثور على ملف custom.pif.prop في أي مسار معروف."
    exit 1
fi

say "🎭 تطبيق البصمة من: $PROP_SRC"

MANUFACTURER=$(pv MANUFACTURER)
MODEL=$(pv MODEL)
FINGERPRINT=$(pv FINGERPRINT)
BRAND=$(pv BRAND)
PRODUCT=$(pv PRODUCT)
DEVICE=$(pv DEVICE)
RELEASE=$(pv RELEASE)
ID=$(pv ID)
INCREMENTAL=$(pv INCREMENTAL)
TYPE=$(pv TYPE)
TAGS=$(pv TAGS)
SECURITY_PATCH=$(pv SECURITY_PATCH)
DEVICE_INITIAL_SDK_INT=$(pv DEVICE_INITIAL_SDK_INT)
BUILD_ID=$(pv '*.build.id')
APILEVEL=$(pv '*api_level')
SPOOF_BUILD=$(pv spoofBuild)
SPOOF_PROPS=$(pv spoofProps)
SPOOF_PROVIDER=$(pv spoofProvider)
SPOOF_SIGNATURE=$(pv spoofSignature)
SPOOF_VENDING_FINGER=$(pv spoofVendingFinger)
SPOOF_VENDING_SDK=$(pv spoofVendingSdk)
VERBOSE_LOGS=$(pv verboseLogs)

if [ -z "$FINGERPRINT" ]; then
    say "✖ ملف البصمة لا يحتوي على FINGERPRINT صالح — تم الإلغاء (لن يُلمس أي شيء)."
    exit 1
fi

# --- اشتقاق الحقول المفقودة تلقائياً من نص البصمة ---
if [ -z "$RELEASE" ] || [ -z "$INCREMENTAL" ] || [ -z "$TYPE" ] || [ -z "$TAGS" ] || \
   [ -z "$BRAND" ] || [ -z "$PRODUCT" ] || [ -z "$DEVICE" ] || [ -z "$ID" ]; then
    IFS='/:' read F1 F2 F3 F4 F5 F6 F7 F8 <<EOF
$FINGERPRINT
EOF
    [ -z "$BRAND" ]     && BRAND="$F1"
    [ -z "$PRODUCT" ]   && PRODUCT="$F2"
    [ -z "$DEVICE" ]    && DEVICE="$F3"
    [ -z "$RELEASE" ]   && RELEASE="$F4"
    [ -z "$ID" ]        && ID="$F5"
    [ -z "$INCREMENTAL" ] && INCREMENTAL="$F6"
    [ -z "$TYPE" ]      && TYPE="$F7"
    [ -z "$TAGS" ]      && TAGS="$F8"
fi

[ -z "$MANUFACTURER" ] && MANUFACTURER="$(echo "$BRAND" | cut -c1 | tr 'a-z' 'A-Z')$(echo "$BRAND" | cut -c2-)"
[ -z "$DEVICE_INITIAL_SDK_INT" ] && DEVICE_INITIAL_SDK_INT="32"
[ -z "$BUILD_ID" ] && BUILD_ID="$ID"
[ -z "$APILEVEL" ] && APILEVEL="$DEVICE_INITIAL_SDK_INT"
[ -z "$SPOOF_BUILD" ] && SPOOF_BUILD="1"
[ -z "$SPOOF_PROPS" ] && SPOOF_PROPS="1"
[ -z "$SPOOF_PROVIDER" ] && SPOOF_PROVIDER="0"
[ -z "$SPOOF_SIGNATURE" ] && SPOOF_SIGNATURE="0"
[ -z "$SPOOF_VENDING_FINGER" ] && SPOOF_VENDING_FINGER="1"
[ -z "$SPOOF_VENDING_SDK" ] && SPOOF_VENDING_SDK="0"
[ -z "$VERBOSE_LOGS" ] && VERBOSE_LOGS="0"

# --- توليد ملف JSON (بدون تعليقات: مكتبة nlohmann/json ترفض التعليقات) ---
TMP="$MODDIR/custom.pif.json.tmp"
{
    echo "{"
    echo "    \"MANUFACTURER\": \"$MANUFACTURER\","
    echo "    \"MODEL\": \"$MODEL\","
    echo "    \"FINGERPRINT\": \"$FINGERPRINT\","
    echo "    \"BRAND\": \"$BRAND\","
    echo "    \"PRODUCT\": \"$PRODUCT\","
    echo "    \"DEVICE\": \"$DEVICE\","
    echo "    \"RELEASE\": \"$RELEASE\","
    echo "    \"ID\": \"$ID\","
    echo "    \"INCREMENTAL\": \"$INCREMENTAL\","
    echo "    \"TYPE\": \"$TYPE\","
    echo "    \"TAGS\": \"$TAGS\","
    echo "    \"SECURITY_PATCH\": \"$SECURITY_PATCH\","
    echo "    \"DEVICE_INITIAL_SDK_INT\": \"$DEVICE_INITIAL_SDK_INT\","
    echo "    \"*.build.id\": \"$BUILD_ID\","
    echo "    \"*.security_patch\": \"$SECURITY_PATCH\","
    echo "    \"*api_level\": \"$APILEVEL\","
    echo "    \"spoofBuild\": \"$SPOOF_BUILD\","
    echo "    \"spoofProps\": \"$SPOOF_PROPS\","
    echo "    \"spoofProvider\": \"$SPOOF_PROVIDER\","
    echo "    \"spoofSignature\": \"$SPOOF_SIGNATURE\","
    echo "    \"spoofVendingFinger\": \"$SPOOF_VENDING_FINGER\","
    echo "    \"spoofVendingSdk\": \"$SPOOF_VENDING_SDK\","
    echo "    \"verboseLogs\": \"$VERBOSE_LOGS\""
    echo "}"
} > "$TMP" 2>/dev/null

if [ ! -s "$TMP" ]; then
    say "✖ فشل توليد ملف JSON."
    exit 1
fi

# --- توزيع الملف على كل المسارات المحتملة ---
mkdir -p "$PIFD" 2>/dev/null
chmod 755 "$PIFD" 2>/dev/null

if [ "$MODE" = "force" ]; then
    # الكتابة الإجبارية على كل المسارات
    cp -f "$TMP" /data/adb/pif.json 2>/dev/null
    cp -f "$TMP" "$PIFD/custom.pif.json" 2>/dev/null
    cp -f "$TMP" "$PIFD/pif.json" 2>/dev/null
    cp -f "$PROP_SRC" "$PIFD/custom.pif.prop" 2>/dev/null
    cp -f "$PROP_SRC" "$PIFD/pif.prop" 2>/dev/null
    cp -f "$PROP_SRC" /data/adb/pif.prop 2>/dev/null
else
    # لا نطمس ملفاً صالحاً — نملأ الفراغات فقط
    valid_pif /data/adb/pif.json || cp -f "$TMP" /data/adb/pif.json 2>/dev/null
    valid_pif "$PIFD/custom.pif.json" || cp -f "$TMP" "$PIFD/custom.pif.json" 2>/dev/null
    valid_pif "$PIFD/pif.json" || cp -f "$TMP" "$PIFD/pif.json" 2>/dev/null
    [ -f "$PIFD/custom.pif.prop" ] || cp -f "$PROP_SRC" "$PIFD/custom.pif.prop" 2>/dev/null
    [ -f "$PIFD/pif.prop" ] || cp -f "$PROP_SRC" "$PIFD/pif.prop" 2>/dev/null
    [ -f /data/adb/pif.prop ] || cp -f "$PROP_SRC" /data/adb/pif.prop 2>/dev/null
fi

# ملف بصمة الموديول نفسه (نسخة مرآة)
cp -f "$TMP" "$MODDIR/custom.pif.json" 2>/dev/null
rm -f "$TMP" 2>/dev/null

# ⚠️ classes.dex: المحرك (libplayintegrityfix.so) يقرؤه من مسار playintegrityfix
if [ -s "$MODDIR/classes.dex" ] && [ ! -s "$PIFD/classes.dex" ]; then
    cp -f "$MODDIR/classes.dex" "$PIFD/classes.dex" 2>/dev/null
fi

chmod 644 "$MODDIR/custom.pif.json" /data/adb/pif.json /data/adb/pif.prop 2>/dev/null
chmod 644 "$PIFD/custom.pif.json" "$PIFD/pif.json" "$PIFD/custom.pif.prop" "$PIFD/pif.prop" "$PIFD/classes.dex" 2>/dev/null

say "✔ تم تثبيت البصمة الجديدة في:"
say "   • $PIFD/custom.pif.json   ← المسار الذي يقرؤه المحرك فعلياً"
say "   • $PIFD/pif.json"
say "   • $PIFD/classes.dex"
say "   • /data/adb/pif.json (مسار احتياطي)"
say "   البصمة: $FINGERPRINT"
say "   Patch: $SECURITY_PATCH"

# إيقاف خدمات جوجل ليعاد تحميل البصمة الجديدة (نتجاهلها في الإقلاع المبكر)
if [ "$MODE" != "ensure" ]; then
    for PKG in com.google.android.gms.unstable com.google.android.gms com.android.vending; do
        if command -v killall >/dev/null 2>&1; then
            killall "$PKG" 2>/dev/null
        elif command -v am >/dev/null 2>&1; then
            am force-stop "$PKG" 2>/dev/null
        fi
    done
fi

say "— انتهى. أعد تشغيل الجهاز ثم افحص مرة واحدة بعد دقيقتين —"
exit 0
