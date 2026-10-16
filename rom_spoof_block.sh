#!/system/bin/sh

# ==============================================================================
# FALCON INTEGRITY FIX — حجب محركات تزييف الرومات المخصصة (ROM Spoof Engines)
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
#
# الرومات المخصصة (LineageOS / EvolutionX / PixelOS …) تشحن محركات تزييف خاصة
# بها (pixelprops / pihooks / entryhooks) تتصارع مع محركنا وتعيد كتابة
# Build.* عند كل إقلاع فتُفسد سلسلة التعتيد. هذا السكربت يعطّل تلك المحركات
# حتى يبقى محرك FALCON المصدر الوحيد للبصمة المزيفة.
# (مقتبس ومُعدّل من dpejoh/specter — مفتوح المصدر)
#
# بوابة أمان: لا يفعل شيئاً على الرومات الرسمية (لا يتحرك إلا إذا اكتشف
# محرك تزييف فعلاً). وللإيقاف نهائياً: touch /data/adb/falcon/no_rom_spoof_block
# يُستدعى من post-fs-data.sh مبكراً (قبل تشغيل GMS).
# ==============================================================================

MODDIR="${0%/*}"
[ -n "$MODDIR" ] && [ -d "$MODDIR" ] || MODDIR="/data/adb/modules/playintegrityfix"

CFG="/data/adb/falcon"
[ -f "$CFG/no_rom_spoof_block" ] && exit 0

GMS_PROPS_FILE="/data/system/gms_certified_props.json"

# --- بوابة الكشف: لا نتحرك إلا إذا وُجد محرك تزييف فعلاً ---
gate=0
resetprop 2>/dev/null | grep -qE 'persist\.sys\.(pihooks|entryhooks|pixelprops)' && gate=1
[ -f "$GMS_PROPS_FILE" ] && gate=1
[ -n "$(getprop ro.lineage.build.version 2>/dev/null)" ] && gate=1
[ "$gate" = "0" ] && exit 0

# --- هل يوجد محرك PixelProps فعلاً؟ (نلتقط الحالة قبل التنظيف) ---
HAS_PP=0
[ -n "$(getprop persist.sys.pixelprops.pi 2>/dev/null)" ] && HAS_PP=1

# --- احترام خيار تخطي الحذف (skipdelprop) ---
SKIPDP=false
[ -f "$MODDIR/skipdelprop" ] && SKIPDP=true

# --- 1) تنظيف بقايا/علامات محركات التزييف القديمة أولاً ---
if [ "$SKIPDP" != "true" ]; then
    resetprop 2>/dev/null | grep -E '(pihook|pixelprops)' | sed 's/^\[\(.*\)\]:.*/\1/' | \
    while IFS= read -r prop; do
        [ -z "$prop" ] && continue
        resetprop -p --delete "$prop" 2>/dev/null || true
    done
fi

# --- 2) بذر خانات الخطافات بقيم فارغة (يرى المحرك الخانة مشغولة فيتراجع) ---
for hook in persist.sys.pihooks.first_api_level persist.sys.pihooks.security_patch; do
    resetprop 2>/dev/null | grep -q "$hook" || resetprop -n -p "$hook" "" 2>/dev/null
done

# --- 3) تعطيل مفاتيح محركات التزييف المعروفة ---
resetprop -n -p persist.sys.pihooks.disable.gms_props true 2>/dev/null
resetprop -n -p persist.sys.pihooks.disable.gms_key_attestation_block true 2>/dev/null
resetprop -n -p persist.sys.entryhooks_enabled false 2>/dev/null
resetprop -n -p persist.sys.pixelprops.google false 2>/dev/null
resetprop -n -p persist.sys.pixelprops.vending false 2>/dev/null
resetprop -n -p persist.sys.pihooks.enabled_features 0 2>/dev/null
resetprop -n -p persist.sys.pihooks.disable 1 2>/dev/null
resetprop -n -p persist.sys.kihooks.disable 1 2>/dev/null
if [ "$HAS_PP" = "1" ]; then
    resetprop -n -p persist.sys.pixelprops.pi false 2>/dev/null
    resetprop -n -p persist.sys.pixelprops.gapps false 2>/dev/null
    resetprop -n -p persist.sys.pixelprops.gms false 2>/dev/null
fi

# --- 4) إسكات مزامنة gms_certified_props الخاصة بالروم ---
if [ -f "$GMS_PROPS_FILE" ] && [ "$(getprop persist.sys.spoof.gms 2>/dev/null)" != "false" ]; then
    resetprop persist.sys.spoof.gms false 2>/dev/null || true
fi

# --- 5) إزالة بصمات رومات LineageOS من الخصائص (علامة مكشوفة لفحوصات جوجل) ---
if [ -n "$(getprop ro.lineage.build.version 2>/dev/null)" ]; then
    LV=$(getprop ro.product.vendor.name 2>/dev/null)
    case "$LV" in
        lineage_*) resetprop -n ro.product.vendor.name "${LV#lineage_}" 2>/dev/null ;;
    esac
    for LP in vendor.camera.aux.packagelist persist.vendor.camera.privapp.list; do
        LCV=$(getprop "$LP" 2>/dev/null)
        case "$LCV" in
            *org.lineageos.aperture*)
                LCV=$(printf '%s' "$LCV" | sed -e 's/,org\.lineageos\.aperture//g' -e 's/org\.lineageos\.aperture,//g' -e 's/^org\.lineageos\.aperture$//')
                resetprop -n "$LP" "$LCV" 2>/dev/null
                ;;
        esac
    done
    if [ -n "$(getprop init.svc.vendor.lineage_health 2>/dev/null)" ]; then
        stop vendor.lineage_health 2>/dev/null
        resetprop --delete init.svc.vendor.lineage_health 2>/dev/null
    fi
fi

log -t "FALCON_FIX" "🛡️ rom_spoof_block: تم تعطيل محركات تزييف الروم" 2>/dev/null
exit 0
