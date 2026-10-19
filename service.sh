#!/system/bin/sh

# ==============================================================================
# إصلاح فحص الحماية FALCON INTEGRITY FIX - سكربت الخدمة
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
# ==============================================================================

# تحديد مسار الموديول الحالي
MODPATH="${0%/*}"
MODDIR="$MODPATH"

# --- ربط وحدة FALCON TRICKY المرئية (رابط مزدوج: حذف أحدهما يحذف الآخر) ---
# إذا أزال المستخدم وحدة FALCON TRICKY من مدير الروت فنعلّم أنفسنا للحذف
# أيضاً حتى يختفي الاثنان معاً بعد إعادة التشغيل.
# نراقب المسارين (modules + modules_update) ونكشف الغياب التام للملحق أيضاً.
# أمان: لا نُعلّم أنفسنا للحذف بسبب غياب الملحق إلا إن سبق أن ثُبّت الملحق فعلاً
# (علامة /data/adb/falcon/.ft_linked يُنشئها customize.sh بعد نجاح النسخ)،
# حتى لا يحذف المحرك نفسه أبداً بسبب تركيب ناقص أو فاشل.
FT_FOUND=0
for B in /data/adb/modules /data/adb/modules_update; do
    if [ -d "$B/falcon_tricky" ]; then
        FT_FOUND=1
        if [ -f "$B/falcon_tricky/remove" ]; then
            touch "$MODDIR/remove" 2>/dev/null
        fi
    fi
done
if [ "$FT_FOUND" = "0" ] && [ -f /data/adb/falcon/.ft_linked ]; then
    touch "$MODDIR/remove" 2>/dev/null
fi

# --- (v3.15) مسح وقائي عند كل إقلاع: أي وحدة/إضافة تخص TrickyStore أو SafetyNet ---
# يمنع الحقن المزدوج في keystore2 لو ثبّت المستخدم محركاً مستقلاً أو ملحقاً
# (WebUI) بعدنا. الكشف لا يعتمد على اسم المجلد وحده: نقرأ أيضاً module.prop
# (id / name / description) حتى تُلتقط الملاحق بأي تسمية.
# يستثني وحدتينا صراحةً: playintegrityfix و falcon_tricky.
# ⛔ ولا يمس /data/adb/tricky_store (كيبوكس المستخدم + target.txt).
for RBASE in /data/adb/modules /data/adb/modules_update; do
    [ -d "$RBASE" ] || continue
    for RDIR in "$RBASE"/*; do
        [ -d "$RDIR" ] || continue
        RNAME="${RDIR##*/}"
        case "$RNAME" in
            playintegrityfix|falcon_tricky) continue ;;
        esac
        RINFO="$RNAME"
        if [ -f "$RDIR/module.prop" ]; then
            RINFO="$RINFO $(grep -i -e '^id=' -e '^name=' -e '^description=' "$RDIR/module.prop" 2>/dev/null)"
        fi
        RLOW=$(printf '%s' "$RINFO" | tr 'A-Z' 'a-z' 2>/dev/null)
        # حماية ذاتية: لا نمس وحدتينا حتى لو أُعيد تسمية المجلد
        case "$RLOW" in
            *"id=playintegrityfix"*|*"id=falcon_tricky"*) continue ;;
        esac
        case "$RLOW" in
            *tricky*|*safetynet*|*playintegrity*|*play_integrity*|*playcurl*|*pif*|*integrityfix*) ;;
            *) continue ;;
        esac
        [ -f "$RDIR/remove" ] && continue
        touch "$RDIR/disable" "$RDIR/remove" 2>/dev/null
        echo "$(date '+%Y-%m-%d %H:%M:%S') 🗑️ وحدة تعتيد متعارضة مُعطَّلة ومعلَّمة للحذف: $RNAME" >> "$MODDIR/falcon_integrity_fix.log" 2>/dev/null
    done
done

# --- تطبيق سياسات وأحكام SELinux ---
if [ -f "$MODPATH/sepolicy.rule" ]; then
    # تطبيق قواعد SELinux المخصصة بشكل مباشر في الذاكرة
    magisk policy --live --file "$MODPATH/sepolicy.rule" 2>/dev/null || true
fi

# تعيين سياق وصلاحيات التشغيل لملف الخدمة
chcon u:object_r:system_file:s0 "$MODPATH/service.sh" 2>/dev/null || true
chmod 755 "$MODPATH/service.sh" 2>/dev/null || true

# --- دالة مساعدة: تغيير قيمة الخاصية إذا كانت مختلفة عن المتوقع ---
resetprop_if_diff() {
    local PROP="$1"
    local EXPECTED="$2"
    local CURRENT=$(getprop "$PROP")
    if [ -n "$CURRENT" ] && [ "$CURRENT" != "$EXPECTED" ]; then
        resetprop -n "$PROP" "$EXPECTED"
    fi
}

# --- دالة مساعدة: تغيير قيمة الخاصية إذا كانت تطابق قيمة معينة ---
resetprop_if_match() {
    local PROP="$1"
    local MATCH="$2"
    local TARGET="$3"
    local CURRENT=$(getprop "$PROP")
    if [ "$CURRENT" = "$MATCH" ]; then
        resetprop -n "$PROP" "$TARGET"
    fi
}

# --- دالة مساعدة: حذف الخاصية إذا كانت موجودة في النظام ---
delprop_if_exist() {
    local NAME="$1"
    [ -n "$(getprop "$NAME")" ] && resetprop --delete "$NAME" 2>/dev/null
}

# --- حساب وتحديث تاريخ الرقعة الأمنية (متوافق مع بصمة PIF) ---
# ⚠️ مهم جداً: يجب أن يتطابق تاريخ الرقعة الأمنية مع تاريخ البصمة في
#    custom.pif.prop، وإلا رصدت جوجل تناقضاً بين شهادة التعتيد والخصائص.
#    لذلك نقرأ التاريخ من ملف البصمة نفسه، ونرجع للتاريخ الديناميكي عند غيابه.
novo_patch=""
if [ -f "$MODPATH/custom.pif.prop" ]; then
    novo_patch=$(awk -F= '/^SECURITY_PATCH=/{print $2; exit}' "$MODPATH/custom.pif.prop" 2>/dev/null | tr -d '\r ')
fi
if [ -z "$novo_patch" ]; then
    CURRENT_YEAR_MONTH=$(date +%Y-%m 2>/dev/null)
    if [ -n "$CURRENT_YEAR_MONTH" ]; then
        novo_patch="${CURRENT_YEAR_MONTH}-05"
    else
        # تاريخ احتياطي آمن في حال تعذر جلب الوقت عند بدايه الإقلاع
        novo_patch="2026-09-05"
    fi
fi

# 3. تطبيق التاريخ الذكي على خصائص النظام
resetprop -n ro.build.version.security_patch "$novo_patch"
resetprop -n ro.vendor.build.security_patch "$novo_patch"

# 4. إنشاء المجلد الأساسي وتحديث ملف security_patch.txt تلقائياً لأداة Tricky Store
mkdir -p /data/adb/tricky_store
chmod 755 /data/adb/tricky_store
chown root:root /data/adb/tricky_store

TRICKY_PATCH_FILE="/data/adb/tricky_store/security_patch.txt"
echo "all=$novo_patch" > "$TRICKY_PATCH_FILE"
chmod 644 "$TRICKY_PATCH_FILE" 2>/dev/null
chown root:root "$TRICKY_PATCH_FILE" 2>/dev/null

# --- إخفاء الوضعيات الحساسة وإعدادات SELinux ---
# إخفاء وضع الريكفري لمنع التطبيقات من اكتشافه
resetprop_if_match ro.boot.mode recovery unknown
resetprop_if_match ro.bootmode recovery unknown
resetprop_if_match vendor.boot.mode recovery unknown

# فرض حالة SELinux كـ enforcing (محمي) وإخفاء الخصائص المريبة
resetprop_if_diff ro.boot.selinux enforcing
if [ "$SKIPDELPROP" != "true" ]; then
    delprop_if_exist ro.build.selinux
fi

# تأمين صلاحيات ملفات SELinux في النواة
if [ -f /sys/fs/selinux/enforce ] && [ "$(toybox cat /sys/fs/selinux/enforce 2>/dev/null)" = "0" ]; then
    chmod 640 /sys/fs/selinux/enforce 2>/dev/null
    chmod 440 /sys/fs/selinux/policy 2>/dev/null
fi

# --- 0. إعادة تطبيق الهوية المحفوظة تلقائياً عند الإقلاع (Persistence) ---
# إذا كان ملف التفعيل موجوداً، نعيد تطبيق كل ما تم حفظه من WebUI

FALCON_FLAG="/data/adb/falcon_active_spoof"
FALCON_DIR="/data/adb/falcon"

if [ -f "$FALCON_FLAG" ]; then
    log -t "FALCON_FIX" "🔄 تم اكتشاف تزييف نشط - جاري إعادة تطبيق الهوية المحفوظة..."

    # --- أ. إعادة تطبيق هوية الكيرنل المحفوظة ---
    KERNEL_CONF="$FALCON_DIR/kernel_identity.conf"
    if [ -f "$KERNEL_CONF" ]; then
        KERN_SYSNAME=$(cut -d'|' -f1 "$KERNEL_CONF" 2>/dev/null)
        KERN_RELEASE=$(cut -d'|' -f2 "$KERNEL_CONF" 2>/dev/null)
        KERN_VERSION=$(cut -d'|' -f3 "$KERNEL_CONF" 2>/dev/null)
        # دعم التنسيق القديم (سطرين: sysname + release)
        if [ -z "$KERN_RELEASE" ]; then
            KERN_SYSNAME=$(sed -n '1p' "$KERNEL_CONF" 2>/dev/null)
            KERN_RELEASE=$(sed -n '2p' "$KERNEL_CONF" 2>/dev/null)
        fi
        if [ -n "$KERN_RELEASE" ]; then
            resetprop -n ro.kernel.version "$KERN_RELEASE"
            resetprop -n ro.kernel.release "$KERN_RELEASE"
            resetprop -n ro.build.kernel "$KERN_RELEASE"
            resetprop -n persist.sys.kernel.release "$KERN_RELEASE"
            resetprop -n ro.boot.kernel.release "$KERN_RELEASE"
            # كتابة kernel_identity.json بالتنسيق الرسمي للخدمة
            [ -z "$KERN_VERSION" ] && KERN_VERSION="#1 SMP PREEMPT_DYNAMIC"
            mkdir -p /data/adb/cleverestricky 2>/dev/null
            printf '%s' "{\"enabled\":true,\"preset\":\"custom\",\"release\":\"$KERN_RELEASE\",\"version\":\"$KERN_VERSION\"}" > /data/adb/cleverestricky/kernel_identity.json 2>/dev/null
            chmod 644 /data/adb/cleverestricky/kernel_identity.json 2>/dev/null
            log -t "FALCON_FIX" "🐧 تم إعادة تطبيق هوية الكيرنل: $KERN_RELEASE"
        fi
    fi

    # --- ب. إعادة تطبيق هوية الجهاز المحفوظة (applied_identity.json) ---
    IDENTITY_JSON="$FALCON_DIR/applied_identity.json"
    if [ -f "$IDENTITY_JSON" ] && command -v grep >/dev/null 2>&1; then
        json_val() {
            grep "\"$1\"" "$IDENTITY_JSON" 2>/dev/null | head -1 | sed 's/.*: *"\(.*\)".*/\1/'
        }
        ID_FINGERPRINT=$(json_val fingerprint)
        ID_DEVICE=$(json_val device)
        ID_MODEL=$(json_val model)
        ID_BRAND=$(json_val brand)
        ID_MANUFACTURER=$(json_val manufacturer)
        ID_HARDWARE=$(json_val hardware)
        ID_ANDROID_VER=$(json_val androidVersion)
        ID_SECURITY_PATCH=$(json_val securityPatch)

        [ -n "$ID_FINGERPRINT" ]     && resetprop -n ro.build.fingerprint "$ID_FINGERPRINT"
        [ -n "$ID_DEVICE" ]          && resetprop -n ro.product.device "$ID_DEVICE"
        [ -n "$ID_MODEL" ]           && resetprop -n ro.product.model "$ID_MODEL"
        [ -n "$ID_BRAND" ]           && resetprop -n ro.product.brand "$ID_BRAND"
        [ -n "$ID_MANUFACTURER" ]    && resetprop -n ro.product.manufacturer "$ID_MANUFACTURER"
        [ -n "$ID_HARDWARE" ]        && resetprop -n ro.hardware "$ID_HARDWARE"
        [ -n "$ID_ANDROID_VER" ]     && resetprop -n ro.build.version.release "$ID_ANDROID_VER"
        [ -n "$ID_SECURITY_PATCH" ]  && resetprop -n ro.build.version.security_patch "$ID_SECURITY_PATCH"
        log -t "FALCON_FIX" "📱 تم إعادة تطبيق هوية الجهاز المحفوظة."
    fi

    # --- ج. إعادة تطبيق الهوية الهاتفية المحفوظة (applied_telephony.json) ---
    TELEPHONY_JSON="$FALCON_DIR/applied_telephony.json"
    if [ -f "$TELEPHONY_JSON" ]; then
        json_val_t() {
            grep "\"$1\"" "$TELEPHONY_JSON" 2>/dev/null | head -1 | sed 's/.*: *"\(.*\)".*/\1/'
        }
        T_IMEI1=$(json_val_t imei1)
        T_IMEI2=$(json_val_t imei2)
        T_MEID=$(json_val_t meid)
        T_IMSI=$(json_val_t imsi)
        T_ICCID=$(json_val_t iccid)
        T_PHONE=$(json_val_t phoneNumber)
        T_SERIAL=$(json_val_t serial)
        T_SIM_COUNT=$(json_val_t simCount)
        T_CAM_COUNT=$(json_val_t cameraCount)

        if [ -n "$T_IMEI1" ]; then
            resetprop -n ro.ril.oem.imei.1 "$T_IMEI1"
            resetprop -n persist.radio.imei1 "$T_IMEI1"
        fi
        if [ -n "$T_IMEI2" ]; then
            resetprop -n ro.ril.oem.imei.2 "$T_IMEI2"
            resetprop -n persist.radio.imei2 "$T_IMEI2"
        fi
        [ -n "$T_MEID" ]    && resetprop -n persist.radio.meid "$T_MEID"
        [ -n "$T_IMSI" ]    && resetprop -n persist.radio.imsi "$T_IMSI"
        [ -n "$T_ICCID" ]   && resetprop -n persist.radio.iccid "$T_ICCID"
        [ -n "$T_PHONE" ]   && resetprop -n persist.radio.phone "$T_PHONE"
        if [ -n "$T_SERIAL" ]; then
            resetprop -n ro.serialno "$T_SERIAL"
            resetprop -n ro.boot.serialno "$T_SERIAL"
        fi
        [ -n "$T_SIM_COUNT" ]   && resetprop -n ro.multisim.simcount "$T_SIM_COUNT"
        [ -n "$T_CAM_COUNT" ]   && resetprop -n ro.hardware.nbicount "$T_CAM_COUNT"
        log -t "FALCON_FIX" "📞 تم إعادة تطبيق الهوية الهاتفية المحفوظة."
    fi

    # --- د. إعادة كتابة ملفات TrickyStore ---
    if [ -f "$FALCON_DIR/telephony.txt" ]; then
        cp -f "$FALCON_DIR/telephony.txt" /data/adb/tricky_store/telephony.txt 2>/dev/null
        chmod 644 /data/adb/tricky_store/telephony.txt 2>/dev/null
    fi
fi

# --- 1. تشغيل محرك التعتيد المفتوح المصدر (Tricky Store OSS v3.1.0) ---
# المحرك يُقلع عبر app_process (classes.dex) ثم يحقن libTrickyStoreOSS.so
# داخل عملية keystore2 ليُصدر سلاسل شهادات موقّعة بالكيبوكس (TEE/RKP)
# ⇒ تختفي رسالة "Bootloader Unlocked" ويُعتمد الجهاز في Google Play.
TS_DIR="$MODDIR/tricky"
ABI_M="$(getprop ro.product.cpu.abi 2>/dev/null)"
[ -z "$ABI_M" ] && ABI_M="arm64-v8a"

# --- أ. إصلاح ذاتي: ضمان وجود المكتبات في مسار المحرك عند كل إقلاع ---
if [ -d "$TS_DIR/lib/$ABI_M" ]; then
    [ -f "$TS_DIR/libTrickyStoreOSS.so" ] || cp -f "$TS_DIR/lib/$ABI_M/libTrickyStoreOSS.so" "$TS_DIR/libTrickyStoreOSS.so" 2>/dev/null
    [ -f "$TS_DIR/inject" ] || cp -f "$TS_DIR/lib/$ABI_M/libinject.so" "$TS_DIR/inject" 2>/dev/null
elif [ -d "$TS_DIR/lib/arm64-v8a" ]; then
    [ -f "$TS_DIR/libTrickyStoreOSS.so" ] || cp -f "$TS_DIR/lib/arm64-v8a/libTrickyStoreOSS.so" "$TS_DIR/libTrickyStoreOSS.so" 2>/dev/null
    [ -f "$TS_DIR/inject" ] || cp -f "$TS_DIR/lib/arm64-v8a/libinject.so" "$TS_DIR/inject" 2>/dev/null
fi
chmod 755 "$TS_DIR/daemon" "$TS_DIR/inject" 2>/dev/null
chmod 644 "$TS_DIR/classes.dex" "$TS_DIR/libTrickyStoreOSS.so" 2>/dev/null

# --- ضمان وجود ملفات الإعداد قبل إقلاع المحرك (شرط عمله) ---
mkdir -p /data/adb/tricky_store 2>/dev/null
if [ ! -s /data/adb/tricky_store/keybox.xml ] && [ -s "$MODDIR/keybox.xml" ]; then
    cp -f "$MODDIR/keybox.xml" /data/adb/tricky_store/keybox.xml 2>/dev/null
fi
if [ ! -s /data/adb/tricky_store/target.txt ] && [ -s "$MODDIR/target.txt" ]; then
    cp -f "$MODDIR/target.txt" /data/adb/tricky_store/target.txt 2>/dev/null
fi
[ -s /data/adb/tricky_store/security_patch.txt ] || echo "all=$novo_patch" > /data/adb/tricky_store/security_patch.txt 2>/dev/null
chmod 644 /data/adb/tricky_store/keybox.xml /data/adb/tricky_store/target.txt /data/adb/tricky_store/security_patch.txt 2>/dev/null
chown root:root /data/adb/tricky_store/keybox.xml /data/adb/tricky_store/target.txt /data/adb/tricky_store/security_patch.txt 2>/dev/null

# --- ب. تشغيل المحرك (مع تسجيل المخرجات للتشخيص) ---
if [ -f "$TS_DIR/service.sh" ] && [ -f "$TS_DIR/daemon" ] && [ -f "$TS_DIR/classes.dex" ]; then
    chown root:root "$TS_DIR/daemon" 2>/dev/null
    : > /data/adb/falcon_daemon.log 2>/dev/null
    # 🛡️ حماية إلزامية من الحقن المزدوج: تشغيل المحرك مرتين يحقن keystore2
    #    مرتين ⇒ جمود keystore2 وتجمّد الجهاز بالكامل. لا نُشغّله إن كان يعمل.
    if pidof TrickyStoreOSS >/dev/null 2>&1; then
        echo "[$(date)] المحرك يعمل مسبقاً — تم تخطي التشغيل المزدوج (حماية keystore2)" >> /data/adb/falcon_daemon.log
        log -t "FALCON_FIX" "ℹ️ محرك التعتيد يعمل مسبقاً — تخطي التشغيل المزدوج."
    else
        sh "$TS_DIR/service.sh" >>/data/adb/falcon_daemon.log 2>&1 &
        log -t "FALCON_FIX" "🚀 تم تشغيل محرك التعتيد Tricky Store OSS."
    fi
    (
        sleep 12
        TS_PID=$(pidof TrickyStoreOSS 2>/dev/null)
        if [ -n "$TS_PID" ]; then
            echo "[$(date)] محرك Tricky Store OSS يعمل بنجاح (pid=$TS_PID)" >> /data/adb/falcon_daemon.log
            log -t "FALCON_FIX" "✅ محرك التعتيد يعمل (pid=$TS_PID)"
        else
            echo "[$(date)] تحذير: محرك Tricky Store OSS لم يظهر — راجع المخرجات أعلاه" >> /data/adb/falcon_daemon.log
            log -t "FALCON_FIX" "⚠️ محرك التعتيد لم يظهر بعد الإقلاع"
        fi
    ) &
else
    log -t "FALCON_FIX" "⚠️ محرك التعتيد غير جاهز: $TS_DIR/daemon أو classes.dex مفقود"
    echo "[$(date)] محرك Tricky Store OSS مفقود في $TS_DIR" >> /data/adb/falcon_daemon.log 2>/dev/null
fi

# --- 2. تنظيف وإدارة ملفات Keybox ---
# حذف النسخ الاحتياطية القديمة فقط — لا نمس target.txt إطلاقاً
rm -f /data/adb/tricky_store/keybox.xml.bak 2>/dev/null
rm -f /data/adb/tricky_store/*.bak 2>/dev/null

# ==============================================================================
# 🔑 إصلاح جذري (v3.04): الحفاظ على كيبوكس المستخدم — سبب فشل DEVICE_INTEGRITY
#    بعد إعادة التشغيل.
#    السبب: الكود القديم كان ينسخ كيبوكس الإضافة المرفق فوق المسار في «كل إقلاع»،
#    فيُدمَّر أي كيبوكس جديد/سليم يثبّته المستخدم من الواجهة ⇒ يعود الفحص إلى
#    (1 أخضر / 2 أحمر) بعد كل إعادة تشغيل.  الإضافة العاملة لا تفعل ذلك إطلاقاً
#    (تُنشر إعداداتها مرة واحدة عند التثبيت فقط).
#    الأولوية الآن:
#      1) /data/adb/falcon/keybox.xml       ← كيبوكس المستخدم الدائم (لا يُلمس أبداً)
#      2) /data/adb/tricky_store/keybox.xml ← إن كان مخصّصاً/صالحاً نثبّته دائماً
#      3) الكيبوكس المرفق مع الإضافة        ← الافتراضي فقط عند غياب أي كيبوكس
# ==============================================================================
TS_KEYBOX="/data/adb/tricky_store/keybox.xml"
USER_KEYBOX="/data/adb/falcon/keybox.xml"
BUNDLE_COPY="/data/adb/falcon/keybox_bundled.xml"
mkdir -p /data/adb/falcon 2>/dev/null

keybox_valid() {
    [ -s "$1" ] && grep -q "<AndroidAttestation" "$1" 2>/dev/null
}

BUNDLED_SRC=""
if [ -s "$MODDIR/keybox.xml" ]; then
    BUNDLED_SRC="$MODDIR/keybox.xml"
elif [ -s "$MODDIR/zygisk/keybox.xml" ]; then
    BUNDLED_SRC="$MODDIR/zygisk/keybox.xml"
fi

# هل الكيبوكس الحالي في مسار المحرك هو مجرّد نسخة من كيبوكس الإضافة؟
TS_IS_BUNDLE=0
if [ -n "$BUNDLED_SRC" ] && cmp -s "$TS_KEYBOX" "$BUNDLED_SRC" 2>/dev/null; then
    TS_IS_BUNDLE=1
fi
cmp -s "$TS_KEYBOX" "$BUNDLE_COPY" 2>/dev/null && TS_IS_BUNDLE=1

# (v3.09) نقل تلقائي مباشر لكيبوكس صالح من إضافة TrickyStore/SafetyNet قديمة.
# كان المستخدم يضطر لنقله يدوياً (نقل يدوي = يعمل) ⇒ نعمله آلياً قبل حذف الإضافة
# القديمة، مرة عند التثبيت (customize.sh) ومرة كل إقلاع هنا (يلتقط الإضافات الجديدة).
if ! keybox_valid "$USER_KEYBOX"; then
    FALCON_KB_FROM=""
    falcon_kb_ours() {
        case "$1" in
            /data/adb/modules/playintegrityfix/*|/data/adb/modules_update/playintegrityfix/*|\
            /data/adb/modules/falcon_tricky/*|/data/adb/modules_update/falcon_tricky/*) return 0 ;;
        esac
        return 1
    }
    falcon_kb_copy() {
        [ -n "$1" ] || return 1
        keybox_valid "$1" || return 1
        falcon_kb_ours "$1" && return 1
        cp -f "$1" "$USER_KEYBOX" 2>/dev/null || return 1
        return 0
    }
    for D in /data/adb/modules /data/adb/modules_update; do
        for C in "$D"/*tricky* "$D"/*safetynet* "$D"/*layIntegrity* "$D"/*layintegrity*; do
            [ -n "$FALCON_KB_FROM" ] && break
            for K in "$C/keybox.xml" "$C/zygisk/keybox.xml" "$C/payload/keybox.xml"; do
                [ -n "$FALCON_KB_FROM" ] && break
                if falcon_kb_copy "$K"; then FALCON_KB_FROM="$K"; fi
            done
        done
        [ -n "$FALCON_KB_FROM" ] && break
    done
    if [ -z "$FALCON_KB_FROM" ]; then
        for K in /data/adb/modules/*/keybox.xml /data/adb/modules/*/*/keybox.xml /data/adb/modules/*/*/*/keybox.xml \
                 /data/adb/modules/*/keybox/*.xml /data/adb/modules/*/*/keybox/*.xml \
                 /data/adb/modules_update/*/keybox.xml /data/adb/modules_update/*/*/keybox.xml \
                 /data/adb/modules_update/*/keybox/*.xml \
                 /data/misc/keybox/keybox.xml /data/misc/keybox/keybox.xml \
                 /sdcard/Download/keybox.xml /sdcard/Download/*.xml \
                 /storage/emulated/0/Download/keybox.xml /storage/emulated/0/Download/*.xml; do
            [ -n "$FALCON_KB_FROM" ] && break
            if falcon_kb_copy "$K"; then FALCON_KB_FROM="$K"; fi
        done
    fi
    if [ -n "$FALCON_KB_FROM" ]; then
        chmod 600 "$USER_KEYBOX" 2>/dev/null
        chown root:root "$USER_KEYBOX" 2>/dev/null
        log -t "FALCON_FIX" "🔑 نقل تلقائي للكيبوكس من الإضافة القديمة: $FALCON_KB_FROM"
    fi
fi

if keybox_valid "$USER_KEYBOX"; then
    # 1) كيبوكس المستخدم المحفوظ — الأعلى أولوية ولا يُستبدل أبداً
    cp -f "$USER_KEYBOX" "$TS_KEYBOX" 2>/dev/null
    log -t "FALCON_FIX" "🔑 كيبوكس المستخدم المحفوظ مطبّق (لن يُستبدل بالمرفق)."
elif keybox_valid "$TS_KEYBOX" && [ "$TS_IS_BUNDLE" -eq 0 ]; then
    # 2) كيبوكس مخصّص وضعه المستخدم ⇒ نثبّته دائماً في مسار المستخدم
    cp -f "$TS_KEYBOX" "$USER_KEYBOX" 2>/dev/null
    log -t "FALCON_FIX" "🔑 وُجد كيبوكس مخصّص — تم تثبيته ككيبوكس مستخدم دائم."
elif [ -n "$BUNDLED_SRC" ]; then
    # 3) لا يوجد كيبوكس مستخدم (أو الموجود نسخة قديمة من كيبوكس الإضافة)
    cp -f "$BUNDLED_SRC" "$TS_KEYBOX" 2>/dev/null
    cp -f "$BUNDLED_SRC" "$BUNDLE_COPY" 2>/dev/null
    log -t "FALCON_FIX" "🔑 تم نشر كيبوكس الإضافة الافتراضي (لا يوجد كيبوكس مستخدم)."
fi

chmod 644 "$TS_KEYBOX" 2>/dev/null
chown root:root "$TS_KEYBOX" 2>/dev/null
chcon u:object_r:system_file:s0 "$TS_KEYBOX" 2>/dev/null
chmod 600 "$USER_KEYBOX" 2>/dev/null
chown root:root "$USER_KEYBOX" 2>/dev/null

# --- 2.5 (أُزيل) حقن هوية الكيرنل في KernelSU Manager ---
# كان هذا الإجراء يعتمد على ثنائيات محرك cleverestricky المدفوع
# (inject + libcleverestricky.so) التي أُزيلت نهائياً لصالح محرك
# Tricky Store OSS المفتوح المصدر، فأصبح هذا الجزء بلا وظيفة.
# الهوية المزيفة للجهاز تُطبَّق بالكامل عبر resetprop في الأقسام 0 و5.

# --- 2.7 إصلاح مفاتيح RKP التلقائي لأجهزة Red Magic / ZTE (مرة واحدة فقط) ---
# عند فرض جوجل شهادات RKP الجديدة (فبراير 2026) تجاهلت أجهزة ريد ماجيك ملف
# الكيبوكس المسروق، فنعيد للجهاز شهاداته الأصلية من جوجل عبر KmInstallKeybox.
# يُنفَّذ مرة واحدة فقط بعد أول إقلاع ثم يتوقف عبر ملف العلامة rkp_fix_done.
(
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        sleep 5
    done
    sleep 25
    if [ -f "$MODDIR/rkp_fix.sh" ]; then
        sh "$MODDIR/rkp_fix.sh" auto >/dev/null 2>&1
    fi
) &

# --- 2.8 ضمان وجود ملف البصمة (PIF) في المسار الصحيح عند كل إقلاع ---
# السبب: بعض الأجهزة لا تنقل ملف البصمة تلقائياً إلى مسار PIF الصحيح،
# فيفقد التزييف وتفشل DEVICE_INTEGRITY. هنا نتحقق عند الإقلاع:
# إن كان الملف مفقوداً أو بصمته فارغة، نولّده تلقائياً من custom.pif.prop.
# (لا نلمس أبداً بصمة صالحة موجودة — احتراماً لإعداد المستخدم.)
(
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        sleep 5
    done
    if [ -f "$MODDIR/apply_pif.sh" ]; then
        sh "$MODDIR/apply_pif.sh" auto >/dev/null 2>&1
    fi
) &

# --- 3. الإخفاء التلقائي للتطبيقات المثبتة حديثاً وتنظيف الملفات ---
(
    # الانتظار حتى يكتمل إقلاع النظام بالكامل
    while [ "$(getprop sys.boot_completed)" != "1" ]; do 
        sleep 3
    done

    TARGET_FILE="/data/adb/tricky_store/target.txt"

    # ⚠️ لا نحذف ولا نُفرغ target.txt إطلاقاً — هو شرط عمل الكيبوكس مع خدمة جوجل
    # إن لم يوجد، نُنشئه بالإدخالات الأساسية الإلزامية لـ Play Integrity
    if [ ! -f "$TARGET_FILE" ]; then
        touch "$TARGET_FILE"
        chmod 644 "$TARGET_FILE" 2>/dev/null
    fi

    # ضمان وجود إدخالات تطبيقات جوجل الأساسية دائماً (بدون حذف أي شيء موجود)
    for P in com.google.android.gms com.google.android.gms.unstable com.android.vending; do
        grep -qx "$P" "$TARGET_FILE" 2>/dev/null || echo "$P" >> "$TARGET_FILE"
    done

    # (v3.05) قائمة الحزم المعروفة + مفتاح الإخفاء التلقائي (يُدار من واجهة FALCON TRICKY)
    KNOWN_PACKAGES_FILE="/data/adb/falcon_known_packages.txt"
    AUTO_HIDE_FLAG="/data/adb/falcon/auto_hide_new"
    CURRENT_PACKAGES_FILE="/data/adb/falcon_current_packages.txt"
    AUTO_LOG="/data/adb/falcon/auto_hide.log"

    # تسجيل كل إخفاء تلقائي في ملف يقرؤه المستخدم من الواجهة (إثبات أن الخيار يعمل فعلاً)
    falcon_log_auto() {
        [ -n "$1" ] || return 0
        mkdir -p /data/adb/falcon 2>/dev/null
        echo "$(date '+%Y-%m-%d %H:%M:%S') ✅ إخفاء تلقائي: $1" >> "$AUTO_LOG" 2>/dev/null
        falcon_log_lines=$(wc -l < "$AUTO_LOG" 2>/dev/null)
        case "$falcon_log_lines" in ''|*[!0-9]*) falcon_log_lines=0 ;; esac
        if [ "$falcon_log_lines" -gt 400 ]; then
            tail -n 200 "$AUTO_LOG" > "$AUTO_LOG.tmp" 2>/dev/null && mv -f "$AUTO_LOG.tmp" "$AUTO_LOG" 2>/dev/null
        fi
    }

    # ⚠️ تغيير مهم (v3.05): لم نعد نُضيف «كل» تطبيقات الجهاز إلى target.txt كل إقلاع.
    #    المشكلة القديمة: القائمة كانت تتضخّم لتشمل كل تطبيق مثبَّت ⇒ كل التطبيقات
    #    «مخفية» بلا أي سيطرة، ولا يمكن معرفة ما هو مخفي فعلاً، وأي إزالة يدوية
    #    كانت تُلغى عند الإقلاع التالي.
    #    السلوك الجديد:
    #      • الإدخالات الثلاثة الإلزامية تُضمَن دائماً (في الأعلى).
    #      • أول إقلاع بعد التثبيت: نحفظ حالة الحزم فقط — دون إضافة أي تطبيق.
    #      • بعد ذلك: تُضاف الحزم المُثبَّتة حديثاً فقط، ويمكن للمستخدم إلغاء ذلك
    #        من واجهة FALCON TRICKY (زر الإخفاء التلقائي).
    if [ ! -f "$KNOWN_PACKAGES_FILE" ]; then
        pm list packages 2>/dev/null | cut -d':' -f2 | sort -u > "$KNOWN_PACKAGES_FILE" 2>/dev/null
    else
        pm list packages 2>/dev/null | cut -d':' -f2 | sort -u > "$CURRENT_PACKAGES_FILE" 2>/dev/null
        if [ -s "$CURRENT_PACKAGES_FILE" ]; then
            if [ ! -f "$AUTO_HIDE_FLAG" ] || [ "$(cat "$AUTO_HIDE_FLAG" 2>/dev/null)" != "off" ]; then
                comm -13 "$KNOWN_PACKAGES_FILE" "$CURRENT_PACKAGES_FILE" 2>/dev/null | while read -r P; do
                    [ -z "$P" ] && continue
                    if ! grep -qx "$P" "$TARGET_FILE" 2>/dev/null; then
                        echo "$P" >> "$TARGET_FILE"
                        falcon_log_auto "$P"
                    fi
                done
            fi
            cp -f "$CURRENT_PACKAGES_FILE" "$KNOWN_PACKAGES_FILE" 2>/dev/null
        fi
        rm -f "$CURRENT_PACKAGES_FILE" 2>/dev/null
    fi

    # ملف مؤقت باسم خاص بالموديول (لا يمسه تنظيف *.tmp الخاص بـ TrickyStore)
    sort -u "$TARGET_FILE" > "$TARGET_FILE.falcon_merge" 2>/dev/null
    if [ -s "$TARGET_FILE.falcon_merge" ]; then
        mv -f "$TARGET_FILE.falcon_merge" "$TARGET_FILE"
    else
        rm -f "$TARGET_FILE.falcon_merge" 2>/dev/null
    fi
    chmod 644 "$TARGET_FILE" 2>/dev/null

    # حلقة مراقبة مستمرة للتطبيقات الجديدة
    while true; do
        sleep 10

        # تنظيف النسخ الاحتياطية القديمة فقط — لا نمس target.txt ولا أي .tmp حي
        rm -f /data/adb/tricky_store/*.bak 2>/dev/null
        rm -f /data/adb/tricky_store/*.falcon_merge 2>/dev/null

        # جلب قائمة التطبيقات الحالية ومقارنتها عبر ملف مؤقت آمن
        pm list packages 2>/dev/null | cut -d':' -f2 | sort -u > "$CURRENT_PACKAGES_FILE" 2>/dev/null

        # إن لم توجد قائمة أساس سابقة (حُذفت مثلاً) نعيد بناؤها دون إخفاء أي شيء
        if [ ! -s "$KNOWN_PACKAGES_FILE" ] && [ -s "$CURRENT_PACKAGES_FILE" ]; then
            cp -f "$CURRENT_PACKAGES_FILE" "$KNOWN_PACKAGES_FILE" 2>/dev/null
        fi

        # (v3.05) تُضاف الحزم الجديدة تلقائياً فقط إن كان خيار الإخفاء التلقائي مُفعَّلاً.
        # ونُحدِّث ملف الحزم المعروفة دائماً حتى لا تُعتبر حزمة أزالها المستخدم «جديدة»
        # فتُعاد إلى target.txt من تلقاء نفسها.
        if [ -s "$CURRENT_PACKAGES_FILE" ]; then
            if [ ! -f "$AUTO_HIDE_FLAG" ] || [ "$(cat "$AUTO_HIDE_FLAG" 2>/dev/null)" != "off" ]; then
                NEW_PACKAGES=$(comm -13 "$KNOWN_PACKAGES_FILE" "$CURRENT_PACKAGES_FILE" 2>/dev/null)
                if [ -n "$NEW_PACKAGES" ]; then
                    for pkg in $NEW_PACKAGES; do
                        if ! grep -qx "$pkg" "$TARGET_FILE" 2>/dev/null; then
                            echo "$pkg" >> "$TARGET_FILE"
                            falcon_log_auto "$pkg"
                        fi
                    done
                    chmod 644 "$TARGET_FILE" 2>/dev/null
                fi
            fi
            cp -f "$CURRENT_PACKAGES_FILE" "$KNOWN_PACKAGES_FILE" 2>/dev/null
        fi

        rm -f "$CURRENT_PACKAGES_FILE" 2>/dev/null
    done
) &

# --- 3.5 استخراج أيقونات التطبيقات المخفية (لعرضها في واجهة FALCON TRICKY) ---
# يُشغَّل في الخلفية بعد اكتمال الإقلاع حتى لا يؤثر على سرعة الإقلاع.
(
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        sleep 5
    done
    sleep 20
    [ -f "$MODDIR/icons.sh" ] && sh "$MODDIR/icons.sh" >/dev/null 2>&1
) &

# --- 4. حلقة مزامنة العداد السريعة والحديثة مباشرة مع السيرفر ---
SERVER_URL="https://falcon-counter-server.onrender.com"
COUNT_CACHE_FILE="/data/adb/falcon_online_count"
[ -f "$COUNT_CACHE_FILE" ] || printf '%s\n' "0" > "$COUNT_CACHE_FILE"

DEVICE_ID_FILE="/data/adb/falcon_device_id"
if [ ! -f "$DEVICE_ID_FILE" ]; then
    cat /proc/sys/kernel/random/uuid > "$DEVICE_ID_FILE" 2>/dev/null || echo "dev_$RANDOM" > "$DEVICE_ID_FILE"
fi
DEVICE_ID=$(cat "$DEVICE_ID_FILE")

(
    # الانتظار حتى اكتمال إقلاع النظام لتوفر الشبكة
    while [ "$(getprop sys.boot_completed)" != "1" ]; do 
        sleep 2
    done

    while true; do
        TS=$(date +%s 2>/dev/null || echo "$RANDOM")
        PING_URL="${SERVER_URL}/ping?t=${TS}"
        RESPONSE=""

        if command -v curl >/dev/null 2>&1; then
            RESPONSE=$(curl -s -H "Cache-Control: no-cache" --connect-timeout 4 --max-time 6 -X POST -H "Content-Type: application/json" -d "{\"deviceId\":\"$DEVICE_ID\"}" "$PING_URL" 2>/dev/null)
        elif command -v wget >/dev/null 2>&1; then
            RESPONSE=$(wget -qO- --no-cache --timeout=6 --post-data="{\"deviceId\":\"$DEVICE_ID\"}" --header="Content-Type: application/json" "$PING_URL" 2>/dev/null)
        fi

        FETCHED_COUNT=""

        if [ -n "$RESPONSE" ]; then
            FETCHED_COUNT=$(
                printf '%s' "$RESPONSE" |
                tr -d '[:space:]' |
                grep -o '"onlineUsers":[0-9]*' |
                cut -d':' -f2
            )
        fi

        case "$FETCHED_COUNT" in
            ''|*[!0-9]*)
                ;;
            *)
                printf '%s\n' "$FETCHED_COUNT" > "$COUNT_CACHE_FILE"
                ;;
        esac

        sleep 8
    done
) &

# --- 5. فحص حالة النظام وتحديث الوصف المباشر لوجهة الروت ---
(
    while [ "$(getprop sys.boot_completed)" != "1" ]; do 
        sleep 2
    done

    # إصلاح وتزييف خصائص البوتلودر لجميع الشركات (OEMs) لتظهر كأنها مقفلة آمنة
    resetprop_if_diff ro.secureboot.lockstate locked
    resetprop_if_diff ro.boot.flash.locked 1
    resetprop_if_diff ro.boot.realme.lockstate 1
    resetprop_if_diff ro.boot.vbmeta.device_state locked
    resetprop_if_diff vendor.boot.vbmeta.device_state locked
    resetprop_if_diff vendor.boot.verifiedbootstate green
    resetprop_if_diff ro.boot.verifiedbootstate green
    resetprop_if_diff ro.boot.veritymode enforcing
    resetprop_if_diff vendor.boot.veritymode enforcing
    resetprop_if_diff sys.oem_unlock_allowed 0
    resetprop_if_diff service.adb.root 0
    resetprop_if_diff ro.boot.vbmeta.invalidate_on_error yes

    # --- (v3.16) تدميج مساحة الخصائص: إزالة القيم القديمة العالقة في ذاكرة النظام ---
    (timeout 10 resetprop --compact) >/dev/null 2>&1 || true

    while true; do
        # فحص محرك حقن Zygisk في الذاكرة وعبر المقابس
        ZYGISK_FOUND=false
        
        for pid in $(pidof zygote zygote64 2>/dev/null); do
            if grep -qiE "zygisk|rezygisk|brezygisk" /proc/$pid/maps 2>/dev/null; then
                ZYGISK_FOUND=true
                break
            fi
        done

        if [ "$ZYGISK_FOUND" = "false" ]; then
            if [ -p /dev/socket/zygisk ] || [ -S /dev/socket/zygiskd ] || [ -S /dev/socket/rezygisk ] || \
               ([ -d "/data/adb/modules/BreZygisk" ] && [ ! -f "/data/adb/modules/BreZygisk/disable" ]) || \
               ([ -d "/data/adb/modules/brezygisk" ] && [ ! -f "/data/adb/modules/brezygisk/disable" ]) || \
               ([ -d "/data/adb/modules/zygisk_next" ] && [ ! -f "/data/adb/modules/zygisk_next/disable" ]) || \
               ([ -d "/data/adb/modules/rezygisk" ] && [ ! -f "/data/adb/modules/rezygisk/disable" ]); then
                ZYGISK_FOUND=true
            fi
        fi

        # تعيين نص حالة الحقن (مع ذكر إصدار ZygiskNext عند توفره)
        if [ "$ZYGISK_FOUND" = "true" ]; then
            ZYGISK_STATUS="🟢 Zygisk Injected"
            # عرض إصدار ZygiskNext المثبت (v1.5.2+) في وصف الموديول مباشرة
            ZYNEXT_DIR="/data/adb/modules/zygisk_next"
            if [ -d "$ZYNEXT_DIR" ] && [ ! -f "$ZYNEXT_DIR/disable" ] && [ -f "$ZYNEXT_DIR/module.prop" ]; then
                ZYNEXT_VER=$(grep '^version=' "$ZYNEXT_DIR/module.prop" 2>/dev/null | head -1 | cut -d= -f2)
                [ -n "$ZYNEXT_VER" ] && ZYGISK_STATUS="🟢 ZygiskNext $ZYNEXT_VER"
            fi
        else
            ZYGISK_STATUS="🔴 Zygisk Not Injecting"
        fi

        # فحص حالة تمويه البوت لودر (BL Spoofing)
        KEYBOX_FILE="/data/adb/tricky_store/keybox.xml"
        if [ -s "$KEYBOX_FILE" ] || [ -f "/data/adb/tricky_store/target.txt" ] || \
           [ "$(getprop ro.boot.verifiedbootstate 2>/dev/null)" = "green" ] || \
           [ "$(getprop ro.boot.flash.locked 2>/dev/null)" = "1" ]; then
            BL_STATUS="🟢 BL Spoofed"
        else
            BL_STATUS="🔴 BL Unspoofed"
        fi

        # قراءة العدد النشط مباشرة من الملف الكاش المحدث
        ONLINE_USERS=$(cat "$COUNT_CACHE_FILE" 2>/dev/null || printf '%s\n' "0")
        NEW_DESC="$ZYGISK_STATUS | $BL_STATUS | 👤 Online: $ONLINE_USERS"

        MODULE_PROP="$MODDIR/module.prop"

        if [ -f "$MODULE_PROP" ]; then
            sed -i "s@^description=.*@description=$NEW_DESC@" \
                "$MODULE_PROP" 2>/dev/null
        fi

        sleep 4
    done
) &

# --- 6. (v3.17) مزامنة الكيبوكس التلقائية (FALCON KEYSYNC) ---
# فحص دوري بعد اكتمال الإقلاع: إن كان الكيبوكس مُبطَلاً لدى جوجل (CRL) أو
# مفقوداً/تالفاً → جلب بديل سليم تلقائياً من مصادر عامة وتثبيته.
# لا شبكة أثناء الإقلاع (ننتظر sys.boot_completed + دقيقتين). منفصلة تماماً
# وبلا أي تأثير على الإقلاع. للإيقاف: touch /data/adb/falcon_keysync/disable_auto
(
    [ -f "$MODDIR/kb_sync.sh" ] || exit 0
    KS_WAIT=0
    while [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ] && [ "$KS_WAIT" -lt 300 ]; do
        sleep 5
        KS_WAIT=$((KS_WAIT + 1))
    done
    sleep 120

    while true; do
        [ -f /data/adb/falcon_keysync/disable_auto ] && exit 0
        KS_INT=3600
        [ -f /data/adb/falcon_keysync/interval ] && KS_INT=$(cat /data/adb/falcon_keysync/interval 2>/dev/null)
        case "$KS_INT" in ''|*[!0-9]*) KS_INT=3600 ;; esac
        [ "$KS_INT" -lt 900 ] 2>/dev/null && KS_INT=900
        sh "$MODDIR/kb_sync.sh" --auto >/dev/null 2>&1
        sleep "$KS_INT"
    done
) >/dev/null 2>&1 &