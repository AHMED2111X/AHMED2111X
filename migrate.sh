#!/bin/sh

# ==============================================================================
# إصلاح فحص الحماية FALCON INTEGRITY FIX - سكربت تحديث وترقية ملفات البصمة
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
# ==============================================================================

N="
";

case "$1" in
  -h|--help|help) echo "sh migrate.sh [-f] [-o] [-a] [الملف_المدخل] [الملف_المخرج]"; exit 0;;
  -i|--install|install) INSTALL=1; shift;;
  *) echo "سكربت ترقية وتحويل ملف custom.pif.json \
    $N   $N";;
esac;

item() { echo "- $@"; }
die() { [ "$INSTALL" ] || echo "$N$N! $@"; exit 1; }

# دالة قراءة واستخراج القيم من ملف JSON
grep_get_json() {
  local target="$FILE";
  [ -n "$2" ] && target="$2";
  eval set -- "$(cat "$target" | tr -d '\r\n' | grep -m1 -o "$1"'".*' | cut -d: -f2- | sed 's|//|#|g')";
  echo "$1" | sed -e 's|"|\\\\\\"|g' -e 's|[,}]*$||';
}

# دالة التحقق من وجود مفتاح محدد داخل ملف JSON
grep_check_json() {
  local target="$FILE";
  [ -n "$2" ] && target="$2";
  grep -q "$1" "$target" && [ "$(grep_get_json $1 "$target")" ];
}

until [ -z "$1" -o -f "$1" ]; do
  case "$1" in
    -f|--force|force) FORCE=1; shift;;
    -o|--override|override) OVERRIDE=1; shift;;
    -a|--advanced|advanced) ADVANCED=1; shift;;
    *) die "وسيط غير صالح / تعذر العثور على الملف: $1";;
  esac;
done;

if [ -f "$1" ]; then
  FILE="$1";
  DIR="$1";
else
  case "$0" in
    *.sh) DIR="$0";;
    *) DIR="$(lsof -p $$ 2>/dev/null | grep -o '/.*migrate.sh$')";;
  esac;
fi;
DIR=$(dirname "$(readlink -f "$DIR")");
[ -z "$FILE" ] && FILE="$DIR/custom.pif.json";

OUT="$2";
[ -z "$OUT" ] && OUT="$DIR/custom.pif.json";

[ -f "$FILE" ] || die "لم يتم العثور على ملف json";

grep_check_json api_level && [ ! "$FORCE" ] && die "الملف مُحدث بالفعل، لا يتطلب ترقية";

[ "$INSTALL" ] || item "جاري تحليل الحقول والبيانات ...";

FPFIELDS="BRAND PRODUCT DEVICE RELEASE ID INCREMENTAL TYPE TAGS";
ALLFIELDS="MANUFACTURER MODEL FINGERPRINT $FPFIELDS SECURITY_PATCH DEVICE_INITIAL_SDK_INT";

for FIELD in $ALLFIELDS; do
  eval $FIELD=\"$(grep_get_json $FIELD)\";
done;

# ترقية حقول المعرفات البسيطة إلى الهيكل الحديث
if [ -n "$ID" ] && ! grep_check_json build.id; then
  item 'تم العثور على حقل ID بسيط، جاري التحويل إلى خاصية "*.build.id" ...';
fi;

if [ -z "$ID" ] && grep_check_json BUILD_ID; then
  item 'تم العثور على حقل BUILD_ID قديم، جاري التحويل إلى خاصية "*.build.id" ...';
  ID="$(grep_get_json BUILD_ID)";
fi;

if [ -n "$SECURITY_PATCH" ] && ! grep_check_json security_patch; then
  item 'تم العثور على حقل SECURITY_PATCH، جاري التحديث لخاصية "*.security_patch" ...';
fi;

if grep_check_json VNDK_VERSION; then
  item 'تم العثور على حقل VNDK_VERSION قديم، جاري التحويل إلى خاصية "*.vndk.version" ...';
  VNDK_VERSION="$(grep_get_json VNDK_VERSION)";
fi;

if [ -n "$DEVICE_INITIAL_SDK_INT" ] && ! grep_check_json api_level; then
  item 'تم العثور على حقل DEVICE_INITIAL_SDK_INT، جاري التحديث لخاصية "*api_level" ...';
fi;

if [ -z "$DEVICE_INITIAL_SDK_INT" ] && grep_check_json FIRST_API_LEVEL; then
  item 'تم العثور على حقل FIRST_API_LEVEL قديم، جاري التحديث لخاصية "*api_level" ...';
  DEVICE_INITIAL_SDK_INT="$(grep_get_json FIRST_API_LEVEL)";
fi;

# اشتقاق الخصائص المفقودة مباشرة من نص البصمة (FINGERPRINT)
if [ -z "$RELEASE" -o -z "$INCREMENTAL" -o -z "$TYPE" -o -z "$TAGS" -o "$OVERRIDE" ]; then
  if [ "$OVERRIDE" ]; then
    item "جاري استبدال القيم المشتقة مباشرة من نص FINGERPRINT ...";
  else
    item "تم العثور على حقول مفقودة، جاري اشتقاقها تلقائياً من FINGERPRINT ...";
  fi;
  IFS='/:' read F1 F2 F3 F4 F5 F6 F7 F8 <<EOF
$(grep_get_json FINGERPRINT)
EOF
  i=1;
  for FIELD in $FPFIELDS; do
    eval [ -z \"\$$FIELD\" -o \"$OVERRIDE\" ] \&\& $FIELD=\"\$F$i\";
    i=$((i+1));
  done;
fi;

if [ -z "$SECURITY_PATCH" -o "$SECURITY_PATCH" = "null" ]; then
  item 'لم يتم العثور على قيمة SECURITY_PATCH، سيتم تركه فارغاً ليُحدد ديناميكياً ...';
  unset SECURITY_PATCH;
fi;

if [ -z "$DEVICE_INITIAL_SDK_INT" -o "$DEVICE_INITIAL_SDK_INT" = "null" ]; then
  item 'حقل DEVICE_INITIAL_SDK_INT مفقود، جاري تعيين القيمة الافتراضية 25 ...';
  DEVICE_INITIAL_SDK_INT=25;
fi;

# إعدادات التمويه المتقدمة
ADVSETTINGS="spoofBuild spoofProps spoofProvider spoofSignature spoofVendingSdk verboseLogs";

spoofBuild=1;
spoofProps=1;
spoofProvider=1;
spoofSignature=0;
spoofVendingSdk=0;
verboseLogs=0;

if [ -f "$OUT" ]; then
  if grep -qE "verboseLogs|VERBOSE_LOGS" "$OUT"; then
    ADVANCED=1;
    grep_check_json VERBOSE_LOGS "$OUT" && verboseLogs="$(grep_get_json VERBOSE_LOGS "$OUT")";
    for SETTING in $ADVSETTINGS; do
      eval grep_check_json $SETTING \"$OUT\" \&\& $SETTING=\"$(grep_get_json $SETTING "$OUT")\";
    done;
    grep -q '//"\*.security_patch"' "$OUT" && SECURITY_COMMENT='//';
  fi;
fi;

[ "$INSTALL" ] || item "جاري كتابة الحقول والخصائص المحدثة في ملف custom.pif.json ...";
[ "$ADVANCED" ] && item "جاري إدراج الإعدادات المتقدمة ...";

# إنشاء وكتابة البنية المحدثة لملف JSON
(echo "{";
echo "  // حقول البناء (Build Fields)";
for FIELD in $ALLFIELDS; do
  eval echo '\ \ \ \ \"$FIELD\": \"'\$$FIELD'\",';
done;
echo "$N  // خصائص النظام (System Properties)";
echo '    "*.build.id": "'$ID'",';
echo "    $SECURITY_COMMENT"'"*.security_patch": "'$SECURITY_PATCH'",';
[ -z "$VNDK_VERSION" ] || echo '    "*.vndk.version": "'$VNDK_VERSION'",';
echo '    "*api_level": "'$DEVICE_INITIAL_SDK_INT'",';
if [ "$ADVANCED" ]; then
  echo "$N  // الإعدادات المتقدمة (Advanced Settings)";
  for SETTING in $ADVSETTINGS; do
    eval echo '\ \ \ \ \"$SETTING\": \"'\$$SETTING'\",';
  done;
fi) | sed '$s/,/\n}/' > "$OUT";

[ "$INSTALL" ] || cat "$OUT";