#!/system/bin/sh

# ==============================================================================
# إصلاح فحص الحماية FALCON INTEGRITY FIX - أداة التشخيص الشاملة
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
# التشغيل: su -c 'sh /data/adb/modules/falcon_integrity_fix/falcon_diag.sh'
# يطبع التقرير على الشاشة ويحفظه أيضاً في /sdcard/falcon_diag.txt
# ==============================================================================

set +o standalone 2>/dev/null
unset ASH_STANDALONE 2>/dev/null

MODDIR="$(dirname "$0")"
if [ -d /data/adb/modules/falcon_integrity_fix ]; then
    MODDIR=/data/adb/modules/falcon_integrity_fix
fi

OUT=/sdcard/falcon_diag.txt
rm -f "$OUT" 2>/dev/null

P() { printf '%s\n' "$*"; printf '%s\n' "$*" >> "$OUT" 2>/dev/null; }
H() {
    P ""
    P "=========================================================="
    P "  $*"
    P "=========================================================="
}

H "FALCON INTEGRITY FIX - تقرير التشخيص"
P "التاريخ/الوقت : $(date 2>/dev/null)"

# ------------------------------------------------------------------ 1
H "1) معلومات الجهاز"
P "MANUFACTURER : $(getprop ro.product.manufacturer)"
P "MODEL        : $(getprop ro.product.model)"
P "DEVICE       : $(getprop ro.product.device)"
P "BRAND        : $(getprop ro.product.brand)"
P "RELEASE      : $(getprop ro.build.version.release)   SDK=$(getprop ro.build.version.sdk)"
P "SEC_PATCH    : $(getprop ro.build.version.security_patch)"
P "VENDOR_PATCH : $(getprop ro.vendor.build.security_patch)"
P "FINGERPRINT  : $(getprop ro.build.fingerprint)"
P "BUILD_TAGS   : $(getprop ro.build.tags)   TYPE=$(getprop ro.build.type)"
P "BOOT.LOCKED  : $(getprop ro.boot.flash.locked)   VBSTATE=$(getprop ro.boot.verifiedbootstate)"

# ------------------------------------------------------------------ 2
H "2) الروت و Zygisk (شرط عمل PIF)"
P "KSU=${KSU:-?}  KSU_NEXT=${KSU_NEXT:-?}  KSU_VER=${KSU_VER:-?}  APATCH=${APATCH:-?}  MMRL=${MMRL:-?}"
P "root         : $(id 2>/dev/null | head -1)"

ZINMAPS=0
for pid in $(pidof zygote zygote64 2>/dev/null); do
    if grep -qiE "zygisk|rezygisk" /proc/$pid/maps 2>/dev/null; then ZINMAPS=1; break; fi
done
P "zygisk in zygote maps : $ZINMAPS"

for s in /dev/socket/zygisk /dev/socket/zygiskd /dev/socket/rezygisk; do
    [ -e "$s" ] && P "socket موجودة : $s"
done

P "موديولات Zygisk المثبتة:"
FOUND=0
for d in /data/adb/modules/*; do
    [ -d "$d" ] || continue
    if [ -f "$d/zygisk/arm64-v8a.so" ] || [ -f "$d/zygisk/armeabi-v7a.so" ]; then
        ST="ENABLED"
        [ -f "$d/disable" ] && ST="DISABLED"
        P "   - $(basename "$d")  [$ST]"
        FOUND=1
    fi
done
[ "$FOUND" = "0" ] && P "   (لا يوجد أي موديول Zygisk!)"

P "مجلد Zygisk Next : $([ -d /data/adb/modules/zygisksu ] && echo موجود || echo غير موجود)"

# ------------------------------------------------------------------ 3
H "3) إعداد بصمة PIF (القلب)"
P "المجلد القديم /data/adb/modules/playintegrityfix : $([ -d /data/adb/modules/playintegrityfix ] && echo 'لا يزال موجوداً (سيُحذف تلقائياً)' || echo 'محذوف — جيد')"
if [ -d /data/adb/falcon_pif ]; then
    P "المجلد موجود. المحتوى:"
    ls -la /data/adb/falcon_pif 2>/dev/null
else
    P "!!! المجلد /data/adb/falcon_pif غير موجود — المكتبة لن تقرأ أي إعداد !!!"
fi

P ""
P "--- custom.pif.prop  (الملف المتوقّع) ---"
cat /data/adb/falcon_pif/custom.pif.prop 2>/dev/null || P "(غير موجود)"

P ""
P "--- pif.prop  (إن وُجد قد يتقدّم على custom) ---"
cat /data/adb/falcon_pif/pif.prop 2>/dev/null || P "(غير موجود - جيد)"

P ""
P "--- custom.pif.json ---"
cat /data/adb/falcon_pif/custom.pif.json 2>/dev/null || P "(غير موجود)"

P ""
P "--- pif.json ---"
cat /data/adb/falcon_pif/pif.json 2>/dev/null || P "(غير موجود)"

P ""
P "--- classes.dex (EntryPoint) ---"
if [ -s /data/adb/falcon_pif/classes.dex ]; then
    P "موجود، الحجم=$(stat -c '%s' /data/adb/falcon_pif/classes.dex 2>/dev/null)"
    P "محتوى EntryPoint: $(grep -c 'EntryPoint' /data/adb/falcon_pif/classes.dex 2>/dev/null) تطابق"
else
    P "(غير موجود!)"
fi

P ""
P "--- سجل /data/adb/falcon_pif.log ---"
if [ -f /data/adb/falcon_pif.log ]; then
    cat /data/adb/falcon_pif.log 2>/dev/null
else
    P "(لا يوجد سجل — لم يعمل pif_setup بعد)"
fi

P ""
P "--- مسارات قديمة (تحقّق من التعارض) ---"
for f in /data/adb/pif.prop /data/adb/pif.json; do
    if [ -f "$f" ]; then
        P "$f : موجود ($(stat -c '%s' "$f" 2>/dev/null) بايت)"
    else
        P "$f : غير موجود"
    fi
done

# ------------------------------------------------------------------ 4
H "4) Tricky Store (الكيبوكس)"
KB=/data/adb/tricky_store/keybox.xml
if [ -s "$KB" ]; then
    P "keybox.xml : موجود  size=$(stat -c '%s' "$KB" 2>/dev/null)  keys=$(grep -c '<Key>' "$KB" 2>/dev/null)"
    if grep -q '<AndroidAttestation' "$KB" 2>/dev/null; then
        P "البنية      : سليمة (AndroidAttestation)"
    else
        P "البنية      : غير سليمة!"
    fi
    P "DeviceID    : $(grep -o 'DeviceID[^<]*' "$KB" 2>/dev/null | head -1)"
else
    P "keybox.xml : مفقود! (لن ينجح STRONG)"
fi
P "security_patch.txt : $(cat /data/adb/tricky_store/security_patch.txt 2>/dev/null)"
P "target.txt سطور : $(wc -l < /data/adb/tricky_store/target.txt 2>/dev/null)"
P "إدخالات جوجل المهمة:"
grep -E 'gms|vending' /data/adb/tricky_store/target.txt 2>/dev/null || P "   (لا يوجد gms/vending!)"
P "hidelist/my.package لغير جوجل (أول 10):"
grep -vE 'gms|vending' /data/adb/tricky_store/target.txt 2>/dev/null | head -10

# ------------------------------------------------------------------ 5
H "5) FALCON (تزييف الهوية العام)"
if [ -f /data/adb/falcon_active_spoof ]; then
    P "!!! /data/adb/falcon_active_spoof موجود — التزييف العام مُفعَّل !!!"
    P "    هذا يغيّر بصمة الجهاز لكل التطبيقات (بما فيها المتجر) وقد يتعارض مع PIF."
    P "    لإلغائه: su -c 'rm -f /data/adb/falcon_active_spoof' ثم أعد التشغيل."
    P ""
    P "الهوية المطبّقة (applied_identity.json):"
    cat /data/adb/falcon/applied_identity.json 2>/dev/null | head -c 800
    P ""
else
    P "falcon_active_spoof : غير موجود (جيد)"
fi
P "kernel_identity.conf : $([ -f /data/adb/falcon/kernel_identity.conf ] && echo موجود || echo غير موجود)"
P ""
P "وصف الموديول الحالي:"
grep '^description=' "$MODDIR/module.prop" 2>/dev/null

# ------------------------------------------------------------------ 6
H "6) تطبيقات جوجل"
for p in com.google.android.gms com.android.vending com.google.android.gsf; do
    V="$(dumpsys package "$p" 2>/dev/null | grep -m1 versionName | tr -d ' ')"
    [ -z "$V" ] && V="(غير مثبّت)"
    P "$p : $V"
done
P "معرّف أندرويد (android_id) : $(settings get secure android_id 2>/dev/null)"

# ------------------------------------------------------------------ 7
H "7) آخر رسائل السجل (logcat)"
logcat -d -t 300 2>/dev/null | grep -iE 'FALCON_FIX|playintegrityfix|chiteroman|integrityfix' | tail -25
P "(إن ظهر فراغ أعلاه فهذا يعني أن المكتبة لم تُحمّل)"

H "انتهى التقرير"
P "تم حفظ نسخة في: /sdcard/falcon_diag.txt"
P "أرسل هذا الملف للمطوّر."

exit 0
