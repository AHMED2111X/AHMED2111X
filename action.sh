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
FORCE_MATCH=0
PATCH_COMMENT=0
spoofProvider=""
ARGS=""

until [ -z "$1" ]; do
  case "$1" in
    -h|--help|help) 
      echo "الاستخدام: sh action.sh [-a|-s] [-m]"
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

MOD_BASE="/data/adb/modules/playintegrityfix"
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

# --- 1. Keybox: نحفظ كيبوكس المستخدم الصالح ولا نطمسه أبداً (v3.04) ---
# ⚠️ كان هذا الزر يحذف الكيبوكس ثم ينسخ كيبوكس الإضافة المرفق فوقه، فيُدمَّر أي
#    كيبوكس جديد ثبّته المستخدم. الآن: الأولوية لكيبوكس المستخدم ثم الموجود ثم المرفق.
step_item "جاري التحقق من سلامة ملف Keybox الحالي..."

TARGET_DIR="/data/adb/tricky_store"
mkdir -p "$TARGET_DIR" /data/adb/falcon
chmod 755 "$TARGET_DIR" 2>/dev/null
chown root:root "$TARGET_DIR" 2>/dev/null

TS_KEYBOX="$TARGET_DIR/keybox.xml"
USER_KEYBOX="/data/adb/falcon/keybox.xml"
SECONDARY_KEYBOX="/data/adb/falcon/keybox2.xml"

kb_valid() { [ -s "$1" ] && grep -q "<AndroidAttestation" "$1" 2>/dev/null; }

BUNDLED_KEYBOX=""
if [ -s "$MODDIR/keybox.xml" ]; then
    BUNDLED_KEYBOX="$MODDIR/keybox.xml"
elif [ -s "$MODDIR/zygisk/keybox.xml" ]; then
    BUNDLED_KEYBOX="$MODDIR/zygisk/keybox.xml"
fi

KB_CHOSEN=""
# (v3.23) لا نستبدل ملفاً نشطاً صالحاً قبل فحص CRL؛ إن كان تالفاً نختار بديلاً.
if ! kb_valid "$TS_KEYBOX"; then
    if kb_valid "$USER_KEYBOX"; then
        KB_CHOSEN="$USER_KEYBOX"
        step_info "سيُستخدم كيبوكس المستخدم المحفوظ (لن يُستبدل بكيبوكس الإضافة)."
    elif kb_valid "$SECONDARY_KEYBOX"; then
        KB_CHOSEN="$SECONDARY_KEYBOX"
        step_info "سيُستخدم المنفذ الثانوي الصالح."
    elif [ -n "$BUNDLED_KEYBOX" ]; then
        KB_CHOSEN="$BUNDLED_KEYBOX"
        step_info "لا يوجد كيبوكس مستخدم — سيُثبّت الكيبوكس المرفق مع الإضافة."
    fi
else
    step_info "الكيبوكس النشط صالح — لن يُستبدل قبل فحص CRL."
fi

# حذف النسخ الاحتياطية/المؤقتة فقط — لا نحذف أي كيبوكس صالح
rm -f "$TARGET_DIR"/*.bak "$TARGET_DIR"/*.tmp "$TARGET_DIR"/*.falcon_merge 2>/dev/null
step_success "تم تنظيف ملفات Tricky Store المؤقتة بنجاح"

step_item "جاري تثبيت ملف Keybox في المسار الدائم..."
if [ -n "$KB_CHOSEN" ]; then
    cp -f "$KB_CHOSEN" "$TS_KEYBOX"
    chmod 644 "$TS_KEYBOX"
    chown root:root "$TS_KEYBOX"
    chcon u:object_r:system_file:s0 "$TS_KEYBOX" 2>/dev/null
    # لا ننسخ المنفذ الثانوي فوق الأساسي أبداً.
    if [ "$KB_CHOSEN" != "$SECONDARY_KEYBOX" ]; then
        cp -f "$KB_CHOSEN" "$USER_KEYBOX" 2>/dev/null
        chmod 600 "$USER_KEYBOX" 2>/dev/null
        chown root:root "$USER_KEYBOX" 2>/dev/null
    fi
    step_success "تم تثبيت Keybox بشكل دائم (يبقى بعد إعادة التشغيل)"
elif ! kb_valid "$TS_KEYBOX"; then
    step_info "تنبيه: لم يتم العثور على أي ملف keybox.xml صالح."
fi

# --- 1.5 (v3.17) المزامنة الذكية للكيبوكس: فحص CRL + جلب تلقائي إن كان مُبطَلاً ---
step_item "جاري الفحص الذكي للكيبوكس (قائمة إبطال جوجل CRL)..."
if [ -f "$MODDIR/kb_sync.sh" ]; then
  KS_OUT=$(sh "$MODDIR/kb_sync.sh" --auto 2>&1)
  KS_RES=$(printf '%s\n' "$KS_OUT" | grep -o 'FALCON_KS_RESULT=[A-Z]*' | head -n 1 | cut -d= -f2)
  case "$KS_RES" in
    OK)       step_success "الكيبوكس كان مُبطَلاً/مفقوداً — تم جلب كيبوكس جديد سليم وتثبيته تلقائياً" ;;
    NOCHANGE) step_success "الكيبوكس الحالي سليم لدى جوجل — لا حاجة لجلب جديد" ;;
    FAIL)     step_info "تعذّر الفحص الآن (لا إنترنت؟) — ستُعاد المحاولة تلقائياً بعد الإقلاع" ;;
    *)        step_info "لم يكتمل الفحص الذكي — تخطّي (راجع /data/adb/falcon_keysync/kb_sync.log)" ;;
  esac
else
  step_info "سكربت المزامنة الذكية غير موجود — تخطّي."
fi

# --- 1.6 (v3.23) تطبيق تفضيل المنفذ (أساسي/ثانوي) بعد أي جلب جديد ---
if [ -f "$MODDIR/falcon_keybox.sh" ]; then
  sh "$MODDIR/falcon_keybox.sh" sync --force --quiet 2>/dev/null
fi

# --- 2. قراءة بصمة التمويه (PIF) من custom.pif.prop ---
# ⚠️ (v3.04) كان هذا الزر يكتب «بصمة الجهاز الحقيقية» (Red Magic/OnePlus) فيُتلف
#    تمويه Play Integrity بالكامل! الآن يقرأ البصمة المزيفة (Pixel 6a) من
#    custom.pif.prop نفسها التي يستخدمها المحرك عند الإقلاع.
step_item "جاري قراءة بصمة التمويه من custom.pif.prop..."

PROP_FILE="$MODDIR/custom.pif.prop"
[ -s "$PROP_FILE" ] || PROP_FILE="$MODDIR/pif.prop"

pprop() {
    awk -v k="$1" 'index($0, k"=")==1 { print substr($0, length(k)+2); exit }' "$PROP_FILE" 2>/dev/null | tr -d '\r'
}

MODEL="$(pprop MODEL)"
DEVICE="$(pprop DEVICE)"
PRODUCT="$(pprop PRODUCT)"
MANUFACTURER="$(pprop MANUFACTURER)"
FINGERPRINT="$(pprop FINGERPRINT)"
SECURITY_PATCH="$(pprop SECURITY_PATCH)"
SDK_INT="$(pprop DEVICE_INITIAL_SDK_INT)"

[ -z "$MODEL" ] && MODEL="$(getprop ro.product.model)"
[ -z "$DEVICE" ] && DEVICE="$(getprop ro.product.device)"
[ -z "$PRODUCT" ] && PRODUCT="$(getprop ro.product.name)"
[ -z "$MANUFACTURER" ] && MANUFACTURER="$(getprop ro.product.manufacturer)"
[ -z "$FINGERPRINT" ] && FINGERPRINT="$(getprop ro.build.fingerprint)"
[ -z "$SECURITY_PATCH" ] && SECURITY_PATCH="2026-09-05"
[ -z "$SDK_INT" ] && SDK_INT="32"

step_info "الطراز المزيف    : $MODEL"
step_info "المنتج المزيف    : $PRODUCT"
step_info "البصمة المزيفة   : $FINGERPRINT"
step_info "الرقعة الأمنية    : $SECURITY_PATCH"
step_success "تم قراءة بصمة التمويه بنجاح"

step_item "جاري كتابة الإعدادات المزيفة لملف pif.json..."
cat <<EOF > pif.json
{
  "MANUFACTURER": "$MANUFACTURER",
  "MODEL": "$MODEL",
  "FINGERPRINT": "$FINGERPRINT",
  "PRODUCT": "$PRODUCT",
  "DEVICE": "$DEVICE",
  "SECURITY_PATCH": "$SECURITY_PATCH",
  "DEVICE_INITIAL_SDK_INT": "$SDK_INT"
}
EOF
step_success "تم إنشاء ملف pif.json ببصمة التمويه"

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
  SECURITY_PATCH_COMPACT="$(printf '%s' "$SECURITY_PATCH" | tr -d '-')"
  if grep -qE '^[0-9]{8}$' "$TS_SECPAT"; then
    sed -i "s/^.*$/$SECURITY_PATCH_COMPACT/" "$TS_SECPAT"
  fi
  if grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' "$TS_SECPAT"; then
    sed -i "s/^.*$/$SECURITY_PATCH/" "$TS_SECPAT"
  fi
  if grep -q 'all=' "$TS_SECPAT"; then
    sed -i "s/all=.*/all=$SECURITY_PATCH/" "$TS_SECPAT"
  fi
  if grep -q 'system=' "$TS_SECPAT"; then
    sed -i "s/system=.*/system=$(printf '%s' "$SECURITY_PATCH_COMPACT" | cut -c-6)/" "$TS_SECPAT"
  fi
  sed -i '$a\' "$TS_SECPAT"
  step_success "تم توحيد تاريخ الرقعة الأمنية لـ Tricky Store"
fi

# --- 5. تثبيت ملفات البصمة المزيفة نهائياً ثم إعادة تشغيل العمليات (v3.04) ---
step_item "جاري تثبيت ملفات البصمة المزيفة (JSON/prop) عبر apply_pif.sh..."
if [ -f "$MODDIR/apply_pif.sh" ]; then
  sh "$MODDIR/apply_pif.sh" force >/dev/null 2>&1
  step_success "تم تثبيت ملفات البصمة المزيفة بنجاح"
else
  step_info "تنبيه: apply_pif.sh غير موجود."
fi

step_item "جاري إعادة تشغيل خدمات Google Play Services (GMS)..."
if [ -f "$MODDIR/killpi.sh" ]; then
  sh "$MODDIR/killpi.sh" >/dev/null 2>&1
else
  killall -9 com.google.android.gms.unstable com.android.vending 2>/dev/null
fi
step_success "تمت إعادة تشغيل عمليات خدمات جوجل بنجاح"

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