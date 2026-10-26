#!/system/bin/sh
# ==============================================================================
# FALCON INTEGRITY FIX - طبقة توافق الرومات المعدّلة (Custom ROM Compatibility)
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
# ==============================================================================
#
# المشكلة التي يحلّها هذا السكربت:
#   على الرومات المعدّلة (LineageOS / crDroid / Evolution X / PixelOS ...) تكون:
#     1) وسوم البناء  ro.build.tags = test-keys  بدل release-keys
#        ⇒ فحص السلامة (Device Integrity) يفشل فوراً وبلا استثناء.
#     2) نوع البناء    ro.build.type = userdebug / eng
#        ⇒ نفس الفشل (وهي من أوضح علامات الروم المعدّل).
#     3) بصمات الأجزاء ro.system|vendor|odm|product.build.fingerprint
#        ما زالت بصمة الروم الأصلي، بينما البصمة الرئيسية مموَّهة ⇒ تعارض ⇒ فشل.
#     4) تواريخ الرقعة في الأجزاء مختلفة عن الرئيسية ⇒ تعارض ⇒ فشل.
#     5) بعض الرومات تكتب خصائصها في service.sh متأخراً فتسحق خصائصنا.
#
# الحل:
#   نقرأ الهوية المموَّهة من custom.pif.prop (مصدر واحد للحقيقة) ونطبّقها
#   اتساقاً على كل الأجزاء عبر resetprop — دون لمس أي ملف نظام إطلاقاً.
#
# ⛔ مبادئ السلامة:
#   1) قيم النوع والوسوم تُستخرج من نص البصمة نفسها ⇒ اتساق مضمون 100%
#      مع محرك PIF ولا يمكن أن تتعارض معه.
#   2) نكتب فقط عبر resetprop (منطقة الخصائص الجديدة) ⇒ لا نلمس الأقسام.
#   3) لا نكتب إلا إذا اختلفت القيمة ⇒ لا عبء على الجهاز.
#   4) قابل للتعطيل بالكامل: touch /data/adb/falcon/rom_compat_off
#
# الاستخدام:
#   sh falcon_rom_compat.sh apply     # تطبيق مرة واحدة
#   sh falcon_rom_compat.sh watch     # إعادة تطبيق دورية (كل 20 ثانية)
#   sh falcon_rom_compat.sh status    # عرض حالة الخصائص على الجهاز
#   sh falcon_rom_compat.sh disable   # تعطيل
#   sh falcon_rom_compat.sh enable    # تفعيل
#   sh falcon_rom_compat.sh help
# ==============================================================================

MODDIR="${0%/*}"
[ -d "$MODDIR" ] || MODDIR="/data/adb/modules/playintegrityfix"

STATE_DIR="/data/adb/falcon"
OFF_MARK="$STATE_DIR/rom_compat_off"
LOG_FILE="$STATE_DIR/rom_compat.log"
INTERVAL=20

# --- مصدر الحقيقة الوحيد: ملف البصمة المموَّهة ---
PROP_FILE="$MODDIR/custom.pif.prop"
[ -s "$PROP_FILE" ] || PROP_FILE="/data/adb/modules/playintegrityfix/custom.pif.prop"
[ -s "$PROP_FILE" ] || PROP_FILE="/data/adb/modules_update/playintegrityfix/custom.pif.prop"

# --- قراءة قيمة مفتاح من ملف الخصائص ---
pval() {
    awk -v k="$1" 'index($0, k"=")==1 { print substr($0, length(k)+2); exit }' \
        "$PROP_FILE" 2>/dev/null | tr -d '\r' | tr -d '"'
}

# --- قراءة حقل من ملف JSON (الهوية المحفوظة من الواجهة) بدون python ---
ID_JSON="/data/adb/falcon/applied_identity.json"
jget() {
    [ -s "$ID_JSON" ] || return 0
    grep -m1 -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$ID_JSON" 2>/dev/null \
        | sed 's/.*:[[:space:]]*"\(.*\)"$/\1/'
}

ts() { date '+%Y-%m-%d %H:%M:%S' 2>/dev/null; }
log_line() {
    [ -d "$STATE_DIR" ] || mkdir -p "$STATE_DIR" 2>/dev/null
    printf '[%s] %s\n' "$(ts)" "$1" >> "$LOG_FILE" 2>/dev/null
}

# --- كتابة خاصية فقط إذا اختلفت قيمتها ---
CHANGED=0
set_prop() {
    _n="$1"
    _v="$2"
    [ -n "$_v" ] || return 0
    _cur="$(resetprop "$_n" 2>/dev/null)"
    [ "$_cur" = "$_v" ] && return 0
    resetprop -n "$_n" "$_v" >/dev/null 2>&1 || resetprop "$_n" "$_v" >/dev/null 2>&1 || return 0
    CHANGED=$((CHANGED + 1))
}

# --- تحميل الهوية ---
load_identity() {
    FP="$(pval FINGERPRINT)"
    PRODUCT="$(pval PRODUCT)"
    ID_RAW="$(pval ID)"
    PATCH_RAW="$(pval SECURITY_PATCH)"
    TYPE_RAW="$(pval TYPE)"
    TAGS_RAW="$(pval TAGS)"

    # ⛔ أولوية للهوية المحفوظة من واجهة FALCON TRICKY إن وُجدت:
    #    هي أحدث من custom.pif.prop، فاستخدامها يمنع أي تعارض معها.
    if [ -s "$ID_JSON" ]; then
        _jfp="$(jget fingerprint)"
        [ -n "$_jfp" ] && FP="$_jfp"
        _jid="$(jget buildId)"
        [ -n "$_jid" ] && ID_RAW="$_jid"
        _jsp="$(jget securityPatch)"
        [ -n "$_jsp" ] && PATCH_RAW="$_jsp"
        _jpr="$(jget product)"
        [ -n "$_jpr" ] && PRODUCT="$_jpr"
    fi

    # ⛔ استخراج النوع والوسوم من نص البصمة نفسها:
    #    بصمة البناء = brand/product/device:release/id/incremental:type/tags
    #    ⇒ اتساق مضمون مع محرك PIF (يستعمل نفس البصمة).
    if [ -n "$FP" ]; then
        _fp_t="$(printf '%s' "$FP" | awk -F'/' '{print $NF}')"
        _fp_ty="$(printf '%s' "$FP" | awk -F'/' '{print $(NF-1)}' | cut -d':' -f2)"
        [ -n "$_fp_t" ] && TAGS_RAW="$_fp_t"
        [ -n "$_fp_ty" ] && TYPE_RAW="$_fp_ty"
    fi

    # تعقيم القيم: نقبل فقط القيم المعروفة، والباقي => الافتراضي الآمن
    case "$TYPE_RAW" in
        user|userdebug|eng|test) TYPE_VAL="$TYPE_RAW" ;;
        *) TYPE_VAL="user" ;;
    esac
    case "$TAGS_RAW" in
        release-keys|dev-keys|test-keys) TAGS_VAL="$TAGS_RAW" ;;
        *) TAGS_VAL="release-keys" ;;
    esac

    [ -n "$PATCH_RAW" ] || PATCH_RAW="2026-10-05"
}

apply_props() {
    load_identity

    # --- 1) وسوم ونوع البناء: العلامة الأوضح للروم المعدّل ---
    set_prop ro.build.tags            "$TAGS_VAL"
    set_prop ro.build.type            "$TYPE_VAL"
    set_prop ro.system.build.tags     "$TAGS_VAL"
    set_prop ro.system.build.type     "$TYPE_VAL"
    set_prop ro.vendor.build.tags     "$TAGS_VAL"
    set_prop ro.vendor.build.type     "$TYPE_VAL"
    set_prop ro.odm.build.tags        "$TAGS_VAL"
    set_prop ro.odm.build.type        "$TYPE_VAL"
    set_prop ro.bootimage.build.tags  "$TAGS_VAL"
    set_prop ro.bootimage.build.type  "$TYPE_VAL"

    # --- 2) أعلام أمان البناء ---
    set_prop ro.debuggable 0
    set_prop ro.secure     1
    set_prop ro.adb.secure 1

    # --- 3) بصمات الأجزاء: يجب أن تطابق البصمة الرئيسية المموَّهة ---
    if [ -n "$FP" ]; then
        set_prop ro.system.build.fingerprint    "$FP"
        set_prop ro.vendor.build.fingerprint    "$FP"
        set_prop ro.odm.build.fingerprint       "$FP"
        set_prop ro.product.build.fingerprint   "$FP"
        set_prop ro.bootimage.build.fingerprint "$FP"
    fi

    # --- 4) معرّفات البناء في الأجزاء ---
    if [ -n "$ID_RAW" ]; then
        set_prop ro.system.build.id  "$ID_RAW"
        set_prop ro.vendor.build.id  "$ID_RAW"
        set_prop ro.odm.build.id     "$ID_RAW"
        set_prop ro.product.build.id "$ID_RAW"
    fi

    # --- 5) تواريخ الرقعة الأمنية: يجب أن تتطابق مع الرئيسية ---
    if [ -n "$PATCH_RAW" ]; then
        set_prop ro.build.version.security_patch          "$PATCH_RAW"
        set_prop ro.system.build.version.security_patch   "$PATCH_RAW"
        set_prop ro.vendor.build.version.security_patch   "$PATCH_RAW"
        set_prop ro.odm.build.version.security_patch      "$PATCH_RAW"
        set_prop ro.product.build.version.security_patch "$PATCH_RAW"
        set_prop ro.system.build.security_patch           "$PATCH_RAW"
        set_prop ro.vendor.build.security_patch           "$PATCH_RAW"
        set_prop ro.odm.build.security_patch              "$PATCH_RAW"
    fi

    # --- 6) وصف البناء: يكشف اسم الروم إن تركناه كما هو ---
    if [ -n "$PRODUCT" ] && [ -n "$ID_RAW" ]; then
        set_prop ro.build.description "$PRODUCT-$TYPE_VAL $ID_RAW $TAGS_VAL"
    fi

    if [ "$CHANGED" -gt 0 ]; then
        log_line "تم تحديث $CHANGED خاصية لتوافق الروم المعدّل"
    fi
    return 0
}

status_mode() {
    echo "══════════════════════════════════════════════"
    echo " FALCON — توافق الرومات المعدّلة (الحالة)"
    echo "══════════════════════════════════════════════"
    printf "ملف المصدر : %s\n" "$PROP_FILE"
    if [ -f "$OFF_MARK" ]; then printf "الحالة     : معطّل ✖\n"; else printf "الحالة     : مفعّل ✔\n"; fi
    echo "----------------------------------------------"
    for P in ro.build.tags ro.build.type ro.build.fingerprint \
             ro.system.build.tags ro.vendor.build.tags ro.odm.build.tags \
             ro.system.build.fingerprint ro.vendor.build.fingerprint \
             ro.odm.build.fingerprint ro.product.build.fingerprint \
             ro.build.version.security_patch ro.build.description \
             ro.debuggable ro.secure ro.adb.secure; do
        printf "%-38s = %s\n" "$P" "$(resetprop "$P" 2>/dev/null)"
    done
    echo "----------------------------------------------"
    echo "سجل: $LOG_FILE"
}

watch_mode() {
    while true; do
        if [ -f "$OFF_MARK" ]; then
            sleep 60
            continue
        fi
        apply_props >/dev/null 2>&1
        sleep "$INTERVAL"
    done
}

case "${1:-apply}" in
    apply)
        [ -f "$OFF_MARK" ] && exit 0
        apply_props
        ;;
    watch)
        watch_mode
        ;;
    status)
        status_mode
        ;;
    disable)
        mkdir -p "$STATE_DIR" 2>/dev/null
        touch "$OFF_MARK"
        log_line "تم تعطيل طبقة توافق الرومات المعدّلة"
        echo "✔ تم التعطيل — لإعادة التفعيل: sh $0 enable"
        ;;
    enable)
        rm -f "$OFF_MARK" 2>/dev/null
        log_line "تم تفعيل طبقة توافق الرومات المعدّلة"
        echo "✔ تم التفعيل"
        ;;
    help|-h|--help)
        grep -A 6 '^# الاستخدام' "$0" | sed 's/^# \{0,1\}//'
        ;;
    *)
        echo "الاستخدام: sh $0 {apply|watch|status|disable|enable|help}"
        exit 1
        ;;
esac

exit 0
