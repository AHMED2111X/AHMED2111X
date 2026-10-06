#!/system/bin/sh

# ==============================================================================
# إصلاح فحص الحماية FALCON INTEGRITY FIX - زر التحديث الآلي للبصمة وKeybox
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
# ==============================================================================

# التأكد من صلاحيات وسياق التشغيل
chmod 755 "$0" 2>/dev/null || true
if [ -f "$(dirname "$0")/sepolicy.rule" ]; then
    magisk policy --live --file "$(dirname "$0")/sepolicy.rule" 2>/dev/null || true
fi

# إلغاء وضع بيئة busybox ash المنفردة لضمان التوافق
set +o standalone
unset ASH_STANDALONE

# --- تحليل وقراءة الخيارات والوسائط ---
FORCE_TOP=1
FORCE_DEPTH=1
FORCE_STRONG=0
FORCE_MATCH=0
PATCH_COMMENT=0
spoofProvider=""
ARGS=""

until [ -z "$1" ]; do
  case "$1" in
    -h|--help|help) 
      echo "الاستخدام: sh action.sh [-a|-s] [-m] [-t #] [-d #]"
      exit 0
      ;;
    -a|--advanced|advanced) 
      ARGS="-a"
      shift
      ;;
    -s|--strong|strong) 
      ARGS="-a"
      PATCH_COMMENT=1
      spoofProvider=0
      shift
      ;;
    -m|--match|match) 
      FORCE_MATCH=1
      shift
      ;;
    -t|--top|top) 
      echo "$2" | grep -q '^[1-9]$' || exit 1
      FORCE_TOP=$2
      shift 2
      ;;
    -d|--depth|depth) 
      echo "$2" | grep -q '^[1-9]$' || exit 1
      FORCE_DEPTH=$2
      shift 2
      ;;
    *) break;;
  esac
done

# --- واجهة المستخدم والدوال التفاعلية ---
draw_banner() {
    clear
    printf "====================================================\n"
    sleep 0.1
    printf "   🦅 FALCON INTEGRITY FIX - تحديث البصمات وKeybox 🦅   \n"
    sleep 0.1
    printf "====================================================\n"
    sleep 0.1
    printf "   المطور: ABUFARID | تليجرام: @FALCON_KERNEL\n"
    sleep 0.1
    printf "----------------------------------------------------\n\n"
    sleep 0.1
}

step_item() { 
    printf "[➜] %s\n" "$1"
    sleep 0.1
}

step_success() { 
    printf "[✔] %s\n\n" "$1"
    sleep 0.1
}

step_info() { 
    printf "    ↳ %s\n" "$1"
    sleep 0.1
}

die() { 
    printf "\n[✖] خطأ: %s!\n\n" "$1"
    exit 1
}

die_bb() { die "$1، يرجى تثبيت إضافة busybox"; }

# --- فحص البيئة والصلاحيات ---
draw_banner

if [ "$USER" != "root" -a "$(whoami 2>/dev/null)" != "root" ]; then
    die "تتطلب هذه العملية صلاحيات الروت (Root)"
fi

case "$HOME" in
    *termux*) die "يرجى التشغيل من بيئة الروت الأساسية (داخل تطبيق الروت)" ;;
esac

case "$0" in
  *.sh) DIR="$0";;
  *) DIR="$(lsof -p $$ 2>/dev/null | grep -o '/.*action.sh$')";;
esac
DIR=$(dirname "$(readlink -f "$DIR")")

MOD_BASE="/data/adb/modules/falcon_integrity_fix"
MODDIR="$DIR"
if [ -d "$MOD_BASE" ]; then
    MODDIR="$MOD_BASE"
fi

# البحث عن مسار أدوات busybox
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

# التحقق من أداة wget
if which wget2 >/dev/null; then
  wget() { wget2 "$@"; }
elif ! which wget >/dev/null || grep -q "wget-curl" $(which wget); then
  if ! find_busybox; then
    die_bb "تعذر العثور على أداة wget"
  elif $BUSYBOX ping -c1 -s2 android.com 2>&1 | grep -q "bad address"; then
    die_bb "أداة wget لا تعمل بشكل صحيح"
  else
    wget() { $BUSYBOX wget "$@"; }
  fi
fi

# التحقق من أداة date
if date -D '%s' -d "$(date '+%s')" 2>&1 | grep -qE "bad date|invalid option"; then
  if ! find_busybox; then
    die_bb "أمر date غير صالح"
  else
    date() { $BUSYBOX date "$@"; }
  fi
fi

# التحقق من أداة grep
if ! echo -e "A\nB" | grep -m1 -A1 "A" | grep -q "B"; then
  if ! find_busybox; then
    die_bb "أمر grep غير صالح"
  else
    grep() { $BUSYBOX grep "$@"; }
  fi
fi

# --- 1. تنظيف ملفات Keybox القديمة وتثبيت الملف المحلي مباشرة ---
step_item "جاري تنظيف ملفات Keybox القديمة والنسخ الاحتياطية (.bak/.tmp)..."

TARGET_DIR="/data/adb/tricky_store"
mkdir -p "$TARGET_DIR"
chmod 755 "$TARGET_DIR"
chown root:root "$TARGET_DIR"

# حذف أي ملفات قديمة أو احتياطية أو مؤقتة
rm -f "$TARGET_DIR/keybox.xml" 2>/dev/null
rm -f "$TARGET_DIR"/*.bak 2>/dev/null
rm -f "$TARGET_DIR"/*.tmp 2>/dev/null
step_success "تم تنظيف ملفات Tricky Store القديمة"

step_item "جاري تطبيق ملف Keybox المحلي المرفق داخل الإضافة..."
TARGET_KEYBOX="$TARGET_DIR/keybox.xml"

KEYBOX_SRC=""
if [ -f "$MODDIR/keybox.xml" ]; then
    KEYBOX_SRC="$MODDIR/keybox.xml"
elif [ -f "$MODDIR/zygisk/keybox.xml" ]; then
    KEYBOX_SRC="$MODDIR/zygisk/keybox.xml"
fi

if [ -n "$KEYBOX_SRC" ]; then
    cp -f "$KEYBOX_SRC" "$TARGET_KEYBOX"
    chmod 644 "$TARGET_KEYBOX"
    chown root:root "$TARGET_KEYBOX"
    chcon u:object_r:system_file:s0 "$TARGET_KEYBOX" 2>/dev/null
    step_success "تم تطبيق ونقل ملف Keybox المحلي بنجاح"
else
    step_info "لم يتم العثور على ملف keybox.xml محلي داخل الإضافة"
fi

# --- 2. التنقيب وجلب بصمات أجهزة Pixel Beta ---
TEMP_DIR="/dev/falcon_pif_tmp"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR" || die "فشل في إنشاء مجلد العمل المؤقت"

step_item "جاري الزحف ومسح موقع مطوري أندرويد لأحدث إصدارات Pixel Beta..."
wget -q -O PIXEL_VERSIONS_HTML --no-check-certificate "https://developer.android.com/about/versions" 2>&1 || die "خطأ في الاتصال بالشبكة"
wget -q -O PIXEL_LATEST_HTML --no-check-certificate "$(grep -o 'https://developer.android.com/about/versions/.*[0-9]"' PIXEL_VERSIONS_HTML | sort -ru | cut -d\" -f1 | head -n$FORCE_TOP | tail -n1)" 2>&1 || die "فشل في جلب صفحة أحدث إصدار"
wget -q -O PIXEL_OTA_HTML --no-check-certificate "https://developer.android.com$(grep -o 'href=".*download-ota.*"' PIXEL_LATEST_HTML | grep 'qpr' | cut -d\" -f2 | head -n$FORCE_DEPTH | tail -n1)" 2>&1 || die "فشل في جلب صفحة تحسينات OTA"

MODEL_LIST="$(grep -A1 'tr id=' PIXEL_OTA_HTML 2>/dev/null | grep 'td' | sed 's;.*<td>\(.*\)</td>.*;\1;')"
PRODUCT_LIST="$(grep -o 'ota/.*_beta' PIXEL_OTA_HTML | cut -d\/ -f2)"
OTA_LIST="$(grep 'ota/.*_beta' PIXEL_OTA_HTML | cut -d\" -f2)"

if [ "$FORCE_MATCH" = "1" ]; then
  DEVICE="$(getprop ro.product.device)"
  case "$PRODUCT_LIST" in
    *${DEVICE}_beta*)
      MODEL="$(getprop ro.product.model)"
      PRODUCT="${DEVICE}_beta"
      OTA="$(echo "$OTA_LIST" | grep "$PRODUCT")"
    ;;
  esac
fi

step_item "جاري تحديد طراز Pixel المستهدف..."
if [ -z "$PRODUCT" ]; then
  set_random_beta() {
    local list_count="$(echo "$MODEL_LIST" | wc -l)"
    local list_rand="$((RANDOM % $list_count + 1))"
    local IFS=$'\n'
    set -- $MODEL_LIST
    MODEL="$(eval echo \${$list_rand})"
    set -- $PRODUCT_LIST
    PRODUCT="$(eval echo \${$list_rand})"
    set -- $OTA_LIST
    OTA="$(eval echo \${$list_rand})"
    DEVICE="$(echo "$PRODUCT" | sed 's/_beta//')"
  }
  set_random_beta
fi

BETA_REL_DATE="$(date -D '%B %e, %Y' -d "$(grep -m1 -A1 'Release date' PIXEL_OTA_HTML | tail -n1 | sed 's;.*<td>\(.*\)</td>.*;\1;')" '+%Y-%m-%d')"
BETA_EXP_DATE="$(date -D '%s' -d "$(($(date -D '%Y-%m-%d' -d "$BETA_REL_DATE" '+%s') + 60 * 60 * 24 * 7 * 6))" '+%Y-%m-%d')"

step_info "الطراز المستهدف   : $MODEL"
step_info "المنتج المستهدف   : $PRODUCT"
step_success "تم اختيار هدف البيتا بنجاح"

step_item "جاري استخراج الخصائص من بيانات حزمة OTA..."
(ulimit -f 2; wget -q -O PIXEL_ZIP_METADATA --no-check-certificate "$OTA") 2>/dev/null
FINGERPRINT="$(grep -am1 'post-build=' PIXEL_ZIP_METADATA 2>/dev/null | cut -d= -f2)"
SECURITY_PATCH="$(grep -am1 'security-patch-level=' PIXEL_ZIP_METADATA 2>/dev/null | cut -d= -f2)"

[ -z "$FINGERPRINT" -o -z "$SECURITY_PATCH" ] && die "فشل استخراج معلومات البناء من ملف OTA"

step_info "البصمة (Fingerprint): $FINGERPRINT"
step_info "الرقعة (Security Patch): $SECURITY_PATCH"
step_success "تم استخراج معلمات الـ OTA بنجاح"

step_item "جاري كتابة الإعدادات الأساسية لملف pif.json..."
cat <<EOF > pif.json
{
  "MANUFACTURER": "Google",
  "MODEL": "$MODEL",
  "FINGERPRINT": "$FINGERPRINT",
  "PRODUCT": "$PRODUCT",
  "DEVICE": "$DEVICE",
  "SECURITY_PATCH": "$SECURITY_PATCH",
  "DEVICE_INITIAL_SDK_INT": "32"
}
EOF
step_success "تم إنشاء ملف pif.json الأساسي"

# --- 3. الترقية والمزامنة ---
MIGRATE_SCRIPT=""
for m in "$MODDIR/migrate.sh" "$DIR/migrate.sh"; do
  if [ -f "$m" ]; then
    MIGRATE_SCRIPT="$m"
    break
  fi
done

if [ -n "$MIGRATE_SCRIPT" ]; then
  step_item "جاري التحويل إلى custom.pif.json عبر migrate.sh..."
  OLDJSON="$MODDIR/custom.pif.json"
  if [ -f "$OLDJSON" ]; then
    grep -q '//"\*.security_patch"' "$OLDJSON" && PATCH_COMMENT=1
    grep -qE "verboseLogs|VERBOSE_LOGS" "$OLDJSON" && ARGS="-a"
  fi
  [ -f /data/adb/tricky_store/security_patch.txt ] && unset PATCH_COMMENT

  rm -f custom.pif.json
  sh "$MIGRATE_SCRIPT" -i $ARGS pif.json >/dev/null 2>&1
  
  if [ -n "$ARGS" ]; then
    grep_json() { [ -f "$2" ] && grep -m1 "$1" "$2" | cut -d\" -f4; }
    verboseLogs=$(grep_json "VERBOSE_LOGS" "$OLDJSON")
    ADVSETTINGS="spoofBuild spoofProps spoofProvider spoofSignature spoofVendingSdk verboseLogs"
    for SETTING in $ADVSETTINGS; do
      eval [ -z \"\$$SETTING\" ] \&\& $SETTING=$(grep_json "$SETTING" "$OLDJSON")
      eval TMPVAL=\$$SETTING
      [ -n "$TMPVAL" ] && sed -i "s;\($SETTING\": \"\).;\1$TMPVAL;" custom.pif.json
    done
  fi
  
  [ "$PATCH_COMMENT" = "1" ] && sed -i 's;"\*.security_patch";//"\*.security_patch";' custom.pif.json
  sed -i "s;};\n  // تاريخ إصدار البيتا: $BETA_REL_DATE\n  // الانتهاء التقديري: $BETA_EXP_DATE\n};" custom.pif.json

  if [ -f "custom.pif.json" ]; then
    cp -f custom.pif.json "$MODDIR/custom.pif.json" 2>/dev/null
    cp -f custom.pif.json /data/adb/pif.json 2>/dev/null
  fi
  step_success "تمت ترقية خصائص PIF بنجاح"
else
  cp -f pif.json "$MODDIR/pif.json" 2>/dev/null
  cp -f pif.json /data/adb/pif.json 2>/dev/null
  step_success "تم تطبيق pif.json القياسي"
fi

# --- 4. مزامنة أداة Tricky Store ---
TS_SECPAT="/data/adb/tricky_store/security_patch.txt"
if [ -f "$TS_SECPAT" ]; then
  step_item "جاري مزامنة ملف security_patch.txt الخاص بـ Tricky Store..."
  [ -s "$TS_SECPAT" ] || echo "all=" > "$TS_SECPAT"
  grep -qE '^[0-9]{8}$' "$TS_SECPAT" && sed -i "s/^.*$/${SECURITY_PATCH//-}/" "$TS_SECPAT"
  grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' "$TS_SECPAT" && sed -i "s/^.*$/$SECURITY_PATCH/" "$TS_SECPAT"
  grep -q 'all=' "$TS_SECPAT" && sed -i "s/all=.*/all=$SECURITY_PATCH/" "$TS_SECPAT"
  grep -q 'system=' "$TS_SECPAT" && sed -i "s/system=.*/system=$(echo ${SECURITY_PATCH//-} | cut -c-6)/" "$TS_SECPAT"
  sed -i '$a\' "$TS_SECPAT"
  step_success "تم توحيد تاريخ الرقعة الأمنية لـ Tricky Store"
fi

# --- 5. إعادة تشغيل العمليات وتطبيق التمويه ---
step_item "جاري إعادة تشغيل خدمات Google Play Services (GMS)..."
if [ -f "$MODDIR/killpi.sh" ]; then
  sh "$MODDIR/killpi.sh" >/dev/null 2>&1
else
  killall -9 com.google.android.gms.unstable com.android.vending 2>/dev/null
fi
step_success "تمت إعادة تشغيل عمليات خدمات جوجل بنجاح"

# --- 6. تنظيف مساحة العمل ---
step_item "جاري تنظيف مجلدات العمل المؤقتة..."
cd /
rm -rf "$TEMP_DIR"
step_success "اكتمل التنظيف"

# --- البطاقة والموجز النهائي ---
printf "====================================================\n"
sleep 0.1
printf "     ✔ تم تحديث الكيبوكس والبصمة بنجاح بنسبة 100%%    \n"
sleep 0.1
printf "====================================================\n"
sleep 0.1
printf "  • طراز الجهاز    : %s\n" "$MODEL"
sleep 0.1
printf "  • نص البصمة      : %s\n" "$FINGERPRINT"
sleep 0.1
printf "  • الرقعة الأمنية : %s\n" "$SECURITY_PATCH"
sleep 0.1
printf "----------------------------------------------------\n"
sleep 0.1
printf "  المطور: ABUFARID | تليجرام: @FALCON_KERNEL\n"
sleep 0.1
printf "====================================================\n\n"

# تأخير إغلاق النافذة لتطبيقات KernelSU / APatch
if [ "$KSU" = "true" -o "$APATCH" = "true" ] && [ "$KSU_NEXT" != "true" ] && [ "$MMRL" != "true" ]; then
  printf "سيتم إغلاق النافذة خلال 5 ثوانٍ ...\n"
  sleep 5
fi