#!/system/bin/sh

# ==============================================================================
# إصلاح فحص الحماية FALCON INTEGRITY FIX - سكربت الخدمة
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
# ==============================================================================

# تحديد مسار الموديول الحالي
MODPATH="${0%/*}"
MODDIR="$MODPATH"

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

# --- حساب وتحديث تاريخ الرقعة الأمنية تلقائياً وبشكل ذكي (Smart Auto-Patch) ---
# 1. جلب السنة والشهر الحاليين تلقائياً من التاريخ الداخلي للجهاز
CURRENT_YEAR_MONTH=$(date +%Y-%m 2>/dev/null)

# 2. إنشاء تاريخ الرقعة الأمنية المتوافق مع معايير جوجل (اليوم 05 من الشهر الحالي)
if [ -n "$CURRENT_YEAR_MONTH" ]; then
    novo_patch="${CURRENT_YEAR_MONTH}-05"
else
    # تاريخ احتياطي آمن في حال تعذر جلب الوقت عند بدايه الإقلاع
    novo_patch="2026-10-05"
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

# --- 1. تشغيل محرك الحقن ---
if [ -f "$MODDIR/inject" ]; then
    chmod 755 "$MODDIR/inject"
    "$MODDIR/inject" &
fi

# --- 2. تنظيف وإدارة ملفات Keybox ---
# حذف الملفات المؤقتة والنسخ الاحتياطية القديمة
rm -f /data/adb/tricky_store/keybox.xml.bak 2>/dev/null
rm -f /data/adb/tricky_store/*.bak 2>/dev/null
rm -f /data/adb/tricky_store/*.tmp 2>/dev/null

# البحث عن ملف keybox.xml المرفق ونسخه للمسار المطلوب
KEYBOX_SRC=""
if [ -f "$MODDIR/keybox.xml" ]; then
    KEYBOX_SRC="$MODDIR/keybox.xml"
elif [ -f "$MODDIR/zygisk/keybox.xml" ]; then
    KEYBOX_SRC="$MODDIR/zygisk/keybox.xml"
fi

if [ -n "$KEYBOX_SRC" ]; then
    cp -f "$KEYBOX_SRC" /data/adb/tricky_store/keybox.xml
    chmod 644 /data/adb/tricky_store/keybox.xml
    chown root:root /data/adb/tricky_store/keybox.xml
    chcon u:object_r:system_file:s0 /data/adb/tricky_store/keybox.xml 2>/dev/null
fi

# --- 3. الإخفاء التلقائي للتطبيقات المثبتة حديثاً وتنظيف الملفات ---
(
    # الانتظار حتى يكتمل إقلاع النظام بالكامل
    while [ "$(getprop sys.boot_completed)" != "1" ]; do 
        sleep 3
    done

    TARGET_FILE="/data/adb/tricky_store/target.txt"
    touch "$TARGET_FILE"

    # جلب قائمة الحزم والتطبيقات المثبتة حالياً وتخزينها
    KNOWN_PACKAGES_FILE="/data/adb/falcon_known_packages.txt"
    pm list packages | cut -d':' -f2 | sort -u > "$KNOWN_PACKAGES_FILE"

    # إضافة كافة التطبيقات الحالية إلى ملف target.txt وإزالة التكرار
    cat "$KNOWN_PACKAGES_FILE" >> "$TARGET_FILE"
    sort -u "$TARGET_FILE" > "$TARGET_FILE.tmp" 2>/dev/null
    if [ -s "$TARGET_FILE.tmp" ]; then
        mv -f "$TARGET_FILE.tmp" "$TARGET_FILE"
    else
        rm -f "$TARGET_FILE.tmp" 2>/dev/null
    fi

    # حلقة مراقبة مستمرة للتطبيقات الجديدة
    while true; do
        sleep 10

        # تنظيف أي ملفات مؤقتة تُنشأ بواسطة TrickyStore
        rm -f /data/adb/tricky_store/*.bak 2>/dev/null
        rm -f /data/adb/tricky_store/*.tmp 2>/dev/null

        # جلب قائمة التطبيقات الحالية ومقارنتها بالقائمة السابقة
        CURRENT_PACKAGES=$(pm list packages | cut -d':' -f2 | sort -u)
        NEW_PACKAGES=$(comm -13 "$KNOWN_PACKAGES_FILE" <(echo "$CURRENT_PACKAGES"))

        # إذا تم كشف تطبيق جديد، يُضاف تلقائياً لملف التمويه target.txt
        if [ -n "$NEW_PACKAGES" ]; then
            for pkg in $NEW_PACKAGES; do
                if ! grep -q "^$pkg$" "$TARGET_FILE"; then
                    echo "$pkg" >> "$TARGET_FILE"
                fi
            done
            # تحديث قائمة التطبيقات المعروفة
            echo "$CURRENT_PACKAGES" > "$KNOWN_PACKAGES_FILE"
            chmod 644 "$TARGET_FILE" 2>/dev/null
        fi
    done
) &

# --- 4. فحص حالة النظام والتمويه وعدد المستخدمين النشطين ---
SERVER_URL="https://falcon-counter-server.onrender.com"

# إنشاء معرّف فريد للجهاز لإحصائيات الاتصال
DEVICE_ID_FILE="/data/adb/falcon_device_id"
if [ ! -f "$DEVICE_ID_FILE" ]; then
    cat /proc/sys/kernel/random/uuid > "$DEVICE_ID_FILE" 2>/dev/null || echo "dev_$RANDOM" > "$DEVICE_ID_FILE"
fi
DEVICE_ID=$(cat "$DEVICE_ID_FILE")

(
    # الانتظار لحين اكتمال الإقلاع
    while [ "$(getprop sys.boot_completed)" != "1" ]; do 
        sleep 2
    done

    # إصلاح وتزييف خصائص البوتلودر لجميع الشركات (OEMS) لتظهر كأنها مقفلة آمنة
    resetprop_if_diff ro.secureboot.lockstate locked
    resetprop_if_diff ro.boot.flash.locked 1
    resetprop_if_diff ro.boot.realme.lockstate 1
    resetprop_if_diff ro.boot.vbmeta.device_state locked
    resetprop_if_diff vendor.boot.vbmeta.device_state locked
    resetprop_if_diff vendor.boot.verifiedbootstate green
    resetprop_if_diff ro.boot.verifiedbootstate green
    resetprop_if_diff ro.boot.veritymode enforcing
    resetprop_if_diff sys.oem_unlock_allowed 0

    LOOP_COUNTER=0
    ONLINE_USERS="1"

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

        # تعيين نص حالة الحقن
        if [ "$ZYGISK_FOUND" = "true" ]; then
            ZYGISK_STATUS="🟢 Zygisk Injected"
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

        # جلب عدد المتصلين بالسيرفر كل 30 ثانية
        if [ $((LOOP_COUNTER % 6)) -eq 0 ]; then
            RESPONSE=""
            if command -v curl >/dev/null 2>&1; then
                RESPONSE=$(curl -s --connect-timeout 8 --max-time 12 -X POST -H "Content-Type: application/json" -d "{\"deviceId\":\"$DEVICE_ID\"}" "$SERVER_URL/ping" 2>/dev/null)
            elif command -v wget >/dev/null 2>&1; then
                RESPONSE=$(wget -qO- --timeout=12 --post-data="{\"deviceId\":\"$DEVICE_ID\"}" --header="Content-Type: application/json" "$SERVER_URL/ping" 2>/dev/null)
            fi

            FETCHED_COUNT=$(echo "$RESPONSE" | grep -o '"onlineUsers":[0-9]*' | cut -d':' -f2)
            if [ -n "$FETCHED_COUNT" ] && [ "$FETCHED_COUNT" -gt 0 ] 2>/dev/null; then
                ONLINE_USERS="$FETCHED_COUNT"
            fi
        fi

        # تحديث الوصف التفاعلي في ملف module.prop
        NEW_DESC="$ZYGISK_STATUS | $BL_STATUS | 👤 Online: $ONLINE_USERS"

        for prop_file in "$MODDIR/module.prop" "/data/adb/modules/falcon_integrity_fix/module.prop" "/data/adb/modules/FALCON_INTEGRITY_FIX/module.prop"; do
            if [ -f "$prop_file" ]; then
                sed -i "s|^description=.*|description=$NEW_DESC|g" "$prop_file"
            fi
        done

        LOOP_COUNTER=$((LOOP_COUNTER + 1))
        sleep 5
    done
) &

# --- 5. المزامنة التلقائية لملف KeyBox من GitHub كل 30 دقيقة ---
(
    while [ "$(getprop sys.boot_completed)" != "1" ]; do 
        sleep 5
    done

    KEYBOX_BASE_URL="https://raw.githubusercontent.com/AHMED2111X/AHMED2111X/main/keybox.xml"
    TARGET_KEYBOX="/data/adb/tricky_store/keybox.xml"
    TMP_KEYBOX="/data/adb/tricky_store/keybox.xml.tmp"

    while true; do
        # تحميل أحدث ملف keybox وتجاوز التخزين المؤقت (Cache)
        TIMESTAMP=$(date +%s 2>/dev/null || echo "$RANDOM")
        FRESH_KEYBOX_URL="${KEYBOX_BASE_URL}?t=${TIMESTAMP}"

        if command -v curl >/dev/null 2>&1; then
            curl -sSL -H "Cache-Control: no-cache" --connect-timeout 5 --max-time 10 -o "$TMP_KEYBOX" "$FRESH_KEYBOX_URL"
        elif command -v wget >/dev/null 2>&1; then
            wget -q --no-cache --timeout=10 -O "$TMP_KEYBOX" "$FRESH_KEYBOX_URL"
        fi

        # التحقق من صحة الملف المستلم واستبداله إذا كان متغيراً
        if [ -s "$TMP_KEYBOX" ] && grep -qi "keybox" "$TMP_KEYBOX" 2>/dev/null; then
            if ! cmp -s "$TMP_KEYBOX" "$TARGET_KEYBOX"; then
                rm -f "$TARGET_KEYBOX"
                mv -f "$TMP_KEYBOX" "$TARGET_KEYBOX"
                chmod 644 "$TARGET_KEYBOX"
                chown root:root "$TARGET_KEYBOX"
                chcon u:object_r:system_file:s0 "$TARGET_KEYBOX" 2>/dev/null
            else
                rm -f "$TMP_KEYBOX"
            fi
        else
            rm -f "$TMP_KEYBOX"
        fi

        # الانتظار لمدة 30 دقيقة قبل الفحص التالي
        sleep 1800
    done
) &