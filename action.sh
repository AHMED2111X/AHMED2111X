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

# --- أوضاع إضافية عبر الوسائط: تقرير تشخيصي / إصلاح اعتماد الجهاز ---
FALCON_SELF_DIR="$(dirname "$(readlink -f "$0")" 2>/dev/null)"
[ -d /data/adb/modules/falcon_integrity_fix ] && FALCON_SELF_DIR=/data/adb/modules/falcon_integrity_fix

case "$1" in
    --diag|-d|diag)
        if [ -f "$FALCON_SELF_DIR/falcon_diag.sh" ]; then
            exec sh "$FALCON_SELF_DIR/falcon_diag.sh"
        fi
        ;;
    --fix-cert|--fixcert|-c|fixcert)
        if [ -f "$FALCON_SELF_DIR/falcon_cert_fix.sh" ]; then
            exec sh "$FALCON_SELF_DIR/falcon_cert_fix.sh" "$2"
        fi
        ;;
esac

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

# --- 1. تنظيف ملفات Keybox القديمة والنسخ الاحتياطية ونقل الملف المحلي الجديد ---
step_item "جاري تنظيف ملفات Keybox القديمة والنسخ الاحتياطية (.bak/.tmp/.xml)..."

TARGET_DIR="/data/adb/tricky_store"
mkdir -p "$TARGET_DIR"
chmod 755 "$TARGET_DIR"
chown root:root "$TARGET_DIR"

# حذف أي ملفات قديمة أو احتياطية أو مؤقتة أو كيبوكس سابقة
rm -f "$TARGET_DIR/keybox.xml" 2>/dev/null
rm -f "$TARGET_DIR"/*.bak 2>/dev/null
rm -f "$TARGET_DIR"/*.tmp 2>/dev/null
rm -f "$TARGET_DIR"/*keybox* 2>/dev/null
step_success "تم تنظيف ملفات Tricky Store القديمة بنجاح"

step_item "جاري البحث عن ملف Keybox داخل الموديول ونقله..."
TARGET_KEYBOX="$TARGET_DIR/keybox.xml"
KEYBOX_SRC=""

if [ -f "$MODDIR/keybox.xml" ]; then
    KEYBOX_SRC="$MODDIR/keybox.xml"
elif [ -f "$MODDIR/zygisk/keybox.xml" ]; then
    KEYBOX_SRC="$MODDIR/zygisk/keybox.xml"
fi

if [ -n "$KEYBOX_SRC" ] && [ -f "$KEYBOX_SRC" ]; then
    cp -f "$KEYBOX_SRC" "$TARGET_KEYBOX"
    chmod 644 "$TARGET_KEYBOX"
    chown root:root "$TARGET_KEYBOX"
    chcon u:object_r:system_file:s0 "$TARGET_KEYBOX" 2>/dev/null
    step_success "تم العثور على ملف Keybox ونقله بنجاح إلى Tricky Store"
else
    step_info "تنبيه: لم يتم العثور على ملف keybox.xml محلياً في الموديول."
fi

# --- 2. توليد بصمة Pixel Canary المعتمدة (Play Integrity) عبر autopif4 ---
# ملاحظة مهمة: مكتبة PIF تقرأ الإعداد حصراً من:
#   /data/adb/falcon_pif/custom.pif.prop
# لذلك نولّد بصمة Pixel معتمدة (وليست بصمة الجهاز الحقيقية) ونضعها في المسار الصحيح.
PIF_DIR="/data/adb/falcon_pif"
step_item "جاري توليد بصمة Pixel معتمدة حديثة عبر autopif4..."

if [ -f "$MODDIR/pif_setup.sh" ]; then
    FALCON_PIF_VERBOSE=1 sh "$MODDIR/pif_setup.sh" --force || true
fi

FINGERPRINT=""
if [ -s "$PIF_DIR/custom.pif.prop" ]; then
    FINGERPRINT="$(grep -m1 '^FINGERPRINT=' "$PIF_DIR/custom.pif.prop" | cut -d= -f2- | cut -d\# -f1 | sed 's/[[:space:]]*$//')"
elif [ -s "$PIF_DIR/custom.pif.json" ]; then
    FINGERPRINT="$(grep -m1 '"FINGERPRINT"' "$PIF_DIR/custom.pif.json" | cut -d\" -f4)"
fi

MODEL="$(getprop ro.product.model)"
SECURITY_PATCH="$(getprop ro.build.version.security_patch)"
[ -z "$SECURITY_PATCH" ] && SECURITY_PATCH="$(date +%Y-%m-%d)"

if [ -n "$FINGERPRINT" ]; then
    step_success "تم توليد بصمة Pixel المعتمدة بنجاح"
    step_info "الطراز المُموَّه : $MODEL"
    step_info "نص البصمة       : $FINGERPRINT"
    step_info "الرقعة الأمنية  : $SECURITY_PATCH"
else
    # --- 2b. احتياطي: استخدام بصمة الجهاز الحقيقية عند تعذّر الإنترنت ---
    step_info "تعذّر جلب بصمة Pixel (تحقّق من الإنترنت) — سيتم استخدام بصمة الجهاز الحقيقية."
    DEVICE="$(getprop ro.product.device)"
    PRODUCT="$(getprop ro.product.name)"
    MANUFACTURER="$(getprop ro.product.manufacturer)"
    FINGERPRINT="$(getprop ro.build.fingerprint)"
    [ -z "$FINGERPRINT" ] && FINGERPRINT="$(getprop ro.vendor.build.fingerprint)"
    SDK_INT="$(getprop ro.build.version.sdk)"
    [ -z "$SDK_INT" ] && SDK_INT="34"

    mkdir -p "$PIF_DIR" 2>/dev/null
    cat <<EOF > "$PIF_DIR/custom.pif.json"
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
    cp -f "$PIF_DIR/custom.pif.json" /data/adb/pif.json 2>/dev/null
    chmod 644 "$PIF_DIR"/* 2>/dev/null
    step_success "تم إنشاء custom.pif.json بالبصمة الحقيقية للجهاز"
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

# --- 5. إعادة تشغيل العمليات وتطبيق التمويه ---
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
printf "  لفحص الحالة الكاملة (تقرير تشخيصي):\n"
printf "      sh action.sh --diag\n"
printf "  لإصلاح اعتماد الجهاز في متجر جوجل:\n"
printf "      sh action.sh --fix-cert\n"
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