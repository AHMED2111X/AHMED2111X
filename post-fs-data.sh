#!/system/bin/sh

# ==============================================================================
# إصلاح فحص الحماية FALCON INTEGRITY FIX - سكربت الإقلاع المبكر (POST-FS-DATA)
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
# ==============================================================================

MODPATH="${0%/*}"

# --- تطبيق سياسات وأحكام SELinux والسياق المبكر ---
if [ -f "$MODPATH/sepolicy.rule" ]; then
    magisk policy --live --file "$MODPATH/sepolicy.rule" 2>/dev/null || true
fi

chcon u:object_r:system_file:s0 "$MODPATH/post-fs-data.sh" 2>/dev/null || true
chmod 755 "$MODPATH/post-fs-data.sh" 2>/dev/null || true

# تحميل الدوال المشتركة إن وجدت
if [ -f "$MODPATH/common_func.sh" ]; then
    . "$MODPATH/common_func.sh"
fi

# دوال مساعدة احتياطية في حال عدم توفرها
if ! command -v resetprop_if_diff >/dev/null 2>&1; then
    resetprop_if_diff() {
        local PROP="$1"
        local EXPECTED="$2"
        local CURRENT=$(getprop "$PROP")
        if [ -n "$CURRENT" ] && [ "$CURRENT" != "$EXPECTED" ]; then
            resetprop -n "$PROP" "$EXPECTED"
        fi
    }
fi

if ! command -v delprop_if_exist >/dev/null 2>&1; then
    delprop_if_exist() {
        local NAME="$1"
        [ -n "$(getprop "$NAME")" ] && resetprop --delete "$NAME" 2>/dev/null
    }
fi

# --- 1. التوافق مع Magisk DenyList و Zygisk و Shamiko ---
if [ -d "$MODPATH/zygisk" ]; then
    # وضع Zygisk: إزالة خدمات جوجل ومتجر بلاي من قائمة العزل ليتمكن Zygisk من الحقن
    if magisk --denylist status >/dev/null 2>&1; then
        magisk --denylist rm com.google.android.gms >/dev/null 2>&1
        magisk --denylist rm com.android.vending >/dev/null 2>&1
    fi
    [ -f "$MODPATH/common_setup.sh" ] && . "$MODPATH/common_setup.sh"
else
    # وضع السكربتات فقط / التوافق مع Shamiko
    if magisk --denylist status >/dev/null 2>&1; then
        magisk --denylist add com.google.android.gms com.google.android.gms.unstable >/dev/null 2>&1
        magisk --denylist add com.android.vending com.android.vending >/dev/null 2>&1
    elif [ -d "/data/adb/modules/zygisk_shamiko" ] && [ ! -f "/data/adb/shamiko/whitelist" ]; then
        magisk --denylist add com.google.android.gms com.google.android.gms >/dev/null 2>&1
        magisk --denylist add com.google.android.gms com.google.android.gms.unstable >/dev/null 2>&1
        magisk --denylist add com.android.vending com.android.vending >/dev/null 2>&1
    fi
fi

# --- 2. تزوير خصائص الأمان والحماية المبكرة للشركات (OEM Spoofing) ---

# إصلاح مؤشر الضمان لهواتف سامسونج (Samsung Knox / Warranty Bit)
resetprop_if_diff ro.boot.warranty_bit 0
resetprop_if_diff ro.vendor.boot.warranty_bit 0
resetprop_if_diff ro.vendor.warranty_bit 0
resetprop_if_diff ro.warranty_bit 0

# إصلاح حالة الإقلاع لهواتف ريلمي (Realme)
resetprop_if_diff ro.boot.realmebootstate green

# إصلاح تحذير الشاشة البرتقالية لهواتف ون بلس (OnePlus)
resetprop_if_diff ro.is_ever_orange 0

# تنظيف خصائص خطافات Play Integrity القديمة
resetprop --delete persist.sys.pihooks.first_api_level 2>/dev/null

# تعيين وسم بناء النظام إلى release-keys
for PROP in $(resetprop | grep -oE 'ro.*.build.tags'); do
    resetprop_if_diff "$PROP" release-keys
done

# تعيين نوع بناء النظام إلى user وإغلاق وضع التصحيح
for PROP in $(resetprop | grep -oE 'ro.*.build.type'); do
    resetprop_if_diff "$PROP" user
done

resetprop_if_diff ro.adb.secure 1
resetprop_if_diff ro.debuggable 0
resetprop_if_diff ro.force.debuggable 0
resetprop_if_diff ro.secure 1
resetprop_if_diff ro.boot.veritymode.managed yes

# حذف أعلام أخطاء التحقق إن وجد
if [ "$SKIPDELPROP" != "true" ]; then
    delprop_if_exist ro.boot.verifiedbooterror
    delprop_if_exist ro.boot.verifyerrorpart
fi

# حل تعارضات الرومات المخصصة (AOSPA و PixelPropsUtils و LeafOS)
if [ -n "$(getprop ro.aospa.version)" ]; then
    for PROP in persist.sys.pihooks.first_api_level persist.sys.pihooks.security_patch; do
        resetprop | grep -q "\[$PROP\]" || resetprop -n -p "$PROP" ""
    done
fi

if [ -n "$(getprop persist.sys.pixelprops.pi)" ]; then
    resetprop -n -p persist.sys.pixelprops.pi false
    resetprop -n -p persist.sys.pixelprops.gapps false
    resetprop -n -p persist.sys.pixelprops.gms false
fi

if [ -f /data/system/gms_certified_props.json ] && [ "$(getprop persist.sys.spoof.gms)" != "false" ]; then
    resetprop persist.sys.spoof.gms false
fi

# --- 2.5 إعادة تطبيق هوية الجهاز المزيفة قبل تشغيل Zygote (جوجل بلاي) ---
# ملاحظة حرجة: قيم Build.FINGERPRINT وخصائص ro.build.* تُهيّأ في ذاكرة Zygote
# مرة واحدة عند الإقلاع وتُورَّث لكل العمليات (جوجل بلاي وغيره). إذا طُبقت
# الخصائص لاحقاً (service.sh) تبقى العمليات القديمة على القيم الأصلية.
# لذلك نطبقها هنا قبل بدء Zygote حتى يرى الجميع البصمة المزيفة.
if [ -f /data/adb/falcon_active_spoof ] && [ -f /data/adb/falcon/applied_identity.json ]; then
    ID_J="/data/adb/falcon/applied_identity.json"
    json_get() {
        python3 -c "
import sys, json
try:
    with open('${ID_J}', 'r', encoding='utf-8') as f:
        d = json.load(f)
    k = sys.argv[1]
    v = d.get(k, '')
    if v is None:
        v = ''
    print(v)
except Exception:
    pass
" "$1" 2>/dev/null
    }
    ID_FP=$(json_get fingerprint)
    ID_DEV=$(json_get device)
    ID_MOD=$(json_get model)
    ID_BRAND=$(json_get brand)
    ID_MAN=$(json_get manufacturer)
    ID_HW=$(json_get hardware)
    ID_PRODUCT=$(json_get product)
    ID_AV=$(json_get androidVersion)
    ID_SP=$(json_get securityPatch)
    ID_BID=$(json_get buildId)
    ID_INC=$(json_get incremental)

    if [ -n "$ID_FP" ]; then
        for P in ro.build.fingerprint ro.system.build.fingerprint ro.vendor.build.fingerprint ro.bootimage.build.fingerprint ro.odm.build.fingerprint; do
            resetprop -n "$P" "$ID_FP" 2>/dev/null
        done
    fi
    if [ -n "$ID_DEV" ]; then
        for P in ro.product.device ro.product.system.device ro.product.vendor.device ro.product.product.device ro.product.odm.device; do
            resetprop -n "$P" "$ID_DEV" 2>/dev/null
        done
    fi
    if [ -n "$ID_MOD" ]; then
        for P in ro.product.model ro.product.system.model ro.product.vendor.model ro.product.product.model ro.product.odm.model ro.product.system_ext.model; do
            resetprop -n "$P" "$ID_MOD" 2>/dev/null
        done
    fi
    if [ -n "$ID_PRODUCT" ]; then
        for P in ro.product.name ro.product.system.name ro.product.vendor.name ro.product.product.name ro.product.odm.name ro.product.system_ext.name; do
            resetprop -n "$P" "$ID_PRODUCT" 2>/dev/null
        done
    elif [ -n "$ID_MOD" ]; then
        for P in ro.product.name ro.product.system.name ro.product.vendor.name; do
            resetprop -n "$P" "$ID_MOD" 2>/dev/null
        done
    fi
    if [ -n "$ID_MAN" ]; then
        for P in ro.product.manufacturer ro.product.system.manufacturer ro.product.vendor.manufacturer; do
            resetprop -n "$P" "$ID_MAN" 2>/dev/null
        done
    fi
    if [ -n "$ID_BRAND" ]; then
        for P in ro.product.brand ro.product.system.brand ro.product.vendor.brand ro.product.product.brand ro.product.odm.brand; do
            resetprop -n "$P" "$ID_BRAND" 2>/dev/null
        done
    fi
    if [ -n "$ID_HW" ]; then
        resetprop -n ro.hardware "$ID_HW" 2>/dev/null
        resetprop -n ro.boot.hardware "$ID_HW" 2>/dev/null
    fi
    if [ -n "$ID_AV" ]; then
        resetprop -n ro.build.version.release "$ID_AV" 2>/dev/null
        resetprop -n ro.build.version.release_or_codename "$ID_AV" 2>/dev/null
    fi
    if [ -n "$ID_SP" ]; then
        resetprop -n ro.build.version.security_patch "$ID_SP" 2>/dev/null
        resetprop -n ro.vendor.build.security_patch "$ID_SP" 2>/dev/null
    fi
    if [ -n "$ID_BID" ]; then
        resetprop -n ro.build.id "$ID_BID" 2>/dev/null
        resetprop -n ro.build.display.id "$ID_BID" 2>/dev/null
    fi
    if [ -n "$ID_INC" ]; then
        resetprop -n ro.build.version.incremental "$ID_INC" 2>/dev/null
    fi
    log -t "FALCON_FIX" "🛡️ تم تطبيق الهوية المزيفة قبل Zygote (سيراها جوجل بلاي بعد الإقلاع)"
fi

# --- 3. تهيئة مجلد Keybox الخاص بـ Tricky Store ---
KEYBOX_URL="https://github.com/AHMED2111X/AHMED2111X/raw/main/keybox.xml"
TARGET_DIR="/data/adb/tricky_store"
TARGET_FILE="$TARGET_DIR/keybox.xml"
LOG_TAG="FALCON_FIX"

if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
    chmod 755 "$TARGET_DIR"
    chown root:root "$TARGET_DIR"
fi

# --- 4. التحديث التلقائي لملف Keybox من الإنترنت في الخلفية ---
(
    # الانتظار حتى يكتمل إقلاع النظام
    while [ "$(getprop sys.boot_completed)" != "1" ]; do 
        sleep 5
    done

    sleep 15

    # ⛔ حماية كيبوكس المستخدم الصالح: لا نستبدل ملفاً موجوداً وصالحاً
    #    إلا عند غيابه/تلفه، أو عند وجود طلب صريح عبر force_keybox_update
    FORCE_UPDATE=0
    [ -f /data/adb/falcon/force_keybox_update ] && FORCE_UPDATE=1

    HAD_VALID=0
    if [ -s "$TARGET_FILE" ]; then
        # نعتبر الكيبوكس الحالي صالحاً إذا احتوى على هيكل AndroidAttestation
        if grep -q "<AndroidAttestation" "$TARGET_FILE" 2>/dev/null; then
            HAD_VALID=1
        fi
    fi

    if [ "$HAD_VALID" -eq 1 ] && [ "$FORCE_UPDATE" -eq 0 ]; then
        rm -f "$TARGET_FILE.tmp" 2>/dev/null
        log -t "$LOG_TAG" "كيبوكس صالح موجود — تم تخطي التحديث التلقائي حفاظاً عليه." \
            " (للتحديث يدوياً: touch /data/adb/falcon/force_keybox_update ثم أعد التشغيل)"
        exit 0
    fi

    DOWNLOAD_SUCCESS=0
    
    # محاولة التحميل عبر curl أو wget
    if command -v curl >/dev/null 2>&1; then
        curl -s -L --connect-timeout 10 --max-time 30 -o "$TARGET_FILE.tmp" "$KEYBOX_URL"
        [ $? -eq 0 ] && DOWNLOAD_SUCCESS=1
    elif command -v wget >/dev/null 2>&1; then
        wget -q --timeout=15 -O "$TARGET_FILE.tmp" "$KEYBOX_URL"
        [ $? -eq 0 ] && DOWNLOAD_SUCCESS=1
    fi

    # قياس حجم الملف المنزّل بآمان
    FILE_SIZE=0
    if [ -f "$TARGET_FILE.tmp" ]; then
        FILE_SIZE="$(stat -c '%s' "$TARGET_FILE.tmp" 2>/dev/null || echo 0)"
    fi

    # التحقق من نجاح التحميل وجودة الملف وحجمه
    if [ "$DOWNLOAD_SUCCESS" -eq 1 ] && \
       [ -f "$TARGET_FILE.tmp" ] && \
       [ "${FILE_SIZE:-0}" -gt 100 ]; then
        mv "$TARGET_FILE.tmp" "$TARGET_FILE"
        chmod 644 "$TARGET_FILE"
        chown root:root "$TARGET_FILE"
        chcon u:object_r:system_file:s0 "$TARGET_FILE" 2>/dev/null
        log -t "$LOG_TAG" "تم تحديث Keybox بنجاح وتطبيق سياق SELinux."
    else
        rm -f "$TARGET_FILE.tmp" 2>/dev/null
        log -t "$LOG_TAG" "فشل تحديث Keybox أو أن الملف غير صالح."
    fi
) &

# --- 5. ضمان وجود ملف البصمة في مسار المحرك قبل بدء Zygote ---
# المحرك (libplayintegrityfix.so) يقرأ ملف البصمة حصراً من
#   /data/adb/modules/playintegrityfix/  وهو مسار موديولنا نفسه الآن.
# نضمن هنا أن الملف موجود ومكتمل مبكراً قبل تشغيل Zygote (بلا إيقاف GMS).
if [ -f "$MODPATH/apply_pif.sh" ]; then
    sh "$MODPATH/apply_pif.sh" ensure >/dev/null 2>&1
fi