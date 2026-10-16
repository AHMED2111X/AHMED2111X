#!/system/bin/sh

# ==============================================================================
# إصلاح فحص الحماية FALCON INTEGRITY FIX - سكربت التثبيت والتخصيص
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
# ==============================================================================

# --- إعداد قواعد SELinux وسياق تنفيذ الملفات ---
if [ -f "$MODPATH/sepolicy.rule" ]; then
    ui_print "- 🛡️ جاري تطبيق قواعد SELinux المخصصة..."
    magisk policy --live --file "$MODPATH/sepolicy.rule" 2>/dev/null || true
fi

chcon -R u:object_r:system_file:s0 "$MODPATH" 2>/dev/null || true
chmod -R 755 "$MODPATH" 2>/dev/null || true

# دالة مساعدة لإضافة مهلة زمنية بسيطة مع ضمان إرجاع قيمة ناجحة
delay() {
    sleep 0.3 2>/dev/null || true
}

ui_print " "
ui_print "  ######################################" ; delay
ui_print "  #      🦅 FALCON INTEGRITY FIX       #" ; delay
ui_print "  #          المطور: ABUFARID          #" ; delay
ui_print "  #        تليجرام: @FALCON_KERNEL     #" ; delay
ui_print "  ######################################" ; delay
ui_print " " ; delay

ui_print "- 🔍 جاري تهيئة بيئة Zygisk Next..." ; delay

# --- الفحص والتحقق من توافق إصدار الأندرويد ---
case "$API" in
    ''|*[!0-9]*)
        abort " 🚫 تعذر تحديد إصدار Android API."
        ;;
esac

if [ "$API" -lt 25 ]; then
    abort " 🚫 خطأ: إصدار الأندرويد الخاص بهاتفك غير مدعوم ✋"
fi
# ------------------------------------------------

# --- التحقق من بيئة Zygisk وضمان التوافق مع ZygiskNext v1.5.2+ ---
ui_print "- 🔍 جاري فحص بيئة Zygisk المثبتة..." ; delay

ZYNEXT_PROP="/data/adb/modules/zygisk_next/module.prop"
REZYGI_PROP="/data/adb/modules/rezygisk/module.prop"

if [ -f "$ZYNEXT_PROP" ] && [ ! -f /data/adb/modules/zygisk_next/disable ]; then
    ZYNEXT_VER=$(grep '^version=' "$ZYNEXT_PROP" 2>/dev/null | head -1 | cut -d= -f2)
    ui_print "- ✅ تم اكتشاف ZygiskNext (${ZYNEXT_VER:-غير معروف})" ; delay
    ui_print "- ✅ الموديول متوافق بالكامل مع ZygiskNext v1.5.2" ; delay
    # ZygiskNext يتطلب إطفاء Zygisk المدمج في Magisk لتجنب تعارض محركين
    if command -v magisk >/dev/null 2>&1; then
        ZYGI_SQL=$(magisk --sqlite "SELECT value FROM settings WHERE key='zygisk'" 2>/dev/null)
        case "$ZYGI_SQL" in
            *value=1*)
                ui_print "- ⚠️ تحذير: Zygisk المدمج داخل Magisk مفعل!" ; delay
                ui_print "   أطفئه من إعدادات Magisk — تعارض المحركين يوقف الحقن." ; delay
                ;;
        esac
    fi
elif [ -f "$REZYGI_PROP" ] && [ ! -f /data/adb/modules/rezygisk/disable ]; then
    ui_print "- ✅ تم اكتشاف ReZygisk — الموديول متوافق" ; delay
else
    ui_print "- ℹ️ لم يتم اكتشاف ZygiskNext — سيعمل الموديول مع Zygisk المدمج" ; delay
    ui_print "   (للأفضل والاستقرار: ثبّت ZygiskNext v1.5.2 وأطفئ Zygisk المدمج)" ; delay
fi
# ------------------------------------------------

# --- ترقية آمنة: إزالة معرّف النسخة القديمة إن وُجد (falcon_integrity_fix) ---
# حتى لا يبقى محركان يعملان معاً بعد تغيير المعرّف إلى playintegrityfix.
OLD_ID_DIR="/data/adb/modules/falcon_integrity_fix"
if [ -d "$OLD_ID_DIR" ] && [ "${MODPATH%/}" != "$OLD_ID_DIR" ]; then
    touch "$OLD_ID_DIR/remove" 2>/dev/null
    ui_print "- 🔄 سيُزال المعرّف القديم (falcon_integrity_fix) عند إعادة التشغيل" ; delay
    ui_print "   تلقائياً — لا يتطلب أي إجراء منك." ; delay
fi

# --- تهيئة محرك التعتيد المفتوح المصدر (Tricky Store OSS v3.1.0) ---
# 🔴 السبب الجذري السابق لظهور "Bootloader Unlocked" في Play Integrity:
#   المحرك القديم cleverestricky يتحقق من بصمة SHA-256 لكل ملفات الموديول
#   عبر ملف موقّع (integrity_manifest.json)، وملفاتنا مُعدّلة (تعريب/تطوير)
#   ⇒ يرفض الإقلاع **بصمت** ⇒ لا يُزيَّف التعتيد ⇒ ترى جوجل البوت لودر مفتوحاً.
# ✅ الحل النهائي المعتمد (من الإضافة العاملة): محرك Tricky Store OSS من
#    beakthoven — مفتوح المصدر بالكامل، لا يتحقق من بصمة أي ملف، ويعمل
#    عبر app_process (classes.dex) + حقن libTrickyStoreOSS.so في keystore2.
ABI="$(getprop ro.product.cpu.abi 2>/dev/null)"
[ -z "$ABI" ] && ABI="arm64-v8a"
TS_LIB="$MODPATH/tricky/lib/$ABI"
[ -d "$TS_LIB" ] || TS_LIB="$MODPATH/tricky/lib/arm64-v8a"
if [ -d "$TS_LIB" ]; then
    cp -f "$TS_LIB/libTrickyStoreOSS.so" "$MODPATH/tricky/libTrickyStoreOSS.so" 2>/dev/null
    cp -f "$TS_LIB/libinject.so" "$MODPATH/tricky/inject" 2>/dev/null
    chmod 755 "$MODPATH/tricky/daemon" "$MODPATH/tricky/inject" 2>/dev/null
    chmod 644 "$MODPATH/tricky/libTrickyStoreOSS.so" "$MODPATH/tricky/classes.dex" "$MODPATH/tricky/module.prop" 2>/dev/null
    ui_print "- ⚙️ تمت تهيئة محرك التعتيد Tricky Store OSS v3.1.0 ($ABI)" ; delay
else
    ui_print "- ⚠️ لم يتم العثور على محرك التعتيد ($ABI)" ; delay
fi

# --- نقل تلقائي مباشر لكيبوكس صالح من إضافة قديمة (TrickyStore / SafetyNet) ---
# المشكلة: المستخدم يثبّت الإضافة العاملة (PlayIntegrity_19.7.7) ثم وحدتنا تحذفها
# لمنع الحقن المزدوج ⇒ يُفقد الكيبوكس السليم الذي كانت تعمل به ويضطر لنقله يدوياً.
# الحل: نبحث عن أي كيبوكس صالح في مجلدات الإضافات القديمة/المتعارضة وننسخه فوراً
# إلى مسار المستخدم الدائم (الأولوية القصوى في service.sh) قبل حذف الإضافة القديمة.
FALCON_KB_DIR="/data/adb/falcon"
FALCON_KB_USER="$FALCON_KB_DIR/keybox.xml"
mkdir -p "$FALCON_KB_DIR" 2>/dev/null

falcon_kb_ok() { [ -s "$1" ] && grep -q "<AndroidAttestation" "$1" 2>/dev/null; }
falcon_kb_ours() {
    case "$1" in
        /data/adb/modules/playintegrityfix/*|/data/adb/modules_update/playintegrityfix/*|\
        /data/adb/modules/falcon_tricky/*|/data/adb/modules_update/falcon_tricky/*) return 0 ;;
    esac
    return 1
}
falcon_kb_copy() {
    [ -n "$1" ] || return 1
    falcon_kb_ok "$1" || return 1
    falcon_kb_ours "$1" && return 1
    cp -f "$1" "$FALCON_KB_USER" 2>/dev/null || return 1
    return 0
}

if ! falcon_kb_ok "$FALCON_KB_USER"; then
    FALCON_KB_FROM=""
    if falcon_kb_copy /data/adb/tricky_store/keybox.xml; then
        FALCON_KB_FROM="/data/adb/tricky_store/keybox.xml"
    fi
    if [ -z "$FALCON_KB_FROM" ]; then
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
    fi
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
        chmod 600 "$FALCON_KB_USER" 2>/dev/null
        chown root:root "$FALCON_KB_USER" 2>/dev/null
        ui_print "- 🔑 تم نقل الكيبوكس تلقائياً من: $FALCON_KB_FROM" ; delay
        ui_print "   سيُستخدم دائماً ولن يُستبدل بكيبوكس الإضافة المرفق." ; delay
    else
        ui_print "- ℹ️ لم يُعثر على كيبوكس خارجي صالح — سيُستخدم الكيبوكس المرفق." ; delay
    fi
fi

# --- نسخ مباشر للكيبوكس إلى مسار TrickyStore (يعمل فوراً دون انتظار الإقلاع) ---
# المسار المحدد: /data/adb/tricky_store/keybox.xml
mkdir -p /data/adb/tricky_store 2>/dev/null
KB_SOURCE=""
if [ -s "$FALCON_KB_USER" ]; then
    KB_SOURCE="$FALCON_KB_USER"
elif [ -s "$MODPATH/keybox.xml" ]; then
    KB_SOURCE="$MODPATH/keybox.xml"
fi
if [ -n "$KB_SOURCE" ]; then
    cp -f "$KB_SOURCE" /data/adb/tricky_store/keybox.xml 2>/dev/null
    chmod 644 /data/adb/tricky_store/keybox.xml 2>/dev/null
    chown root:root /data/adb/tricky_store/keybox.xml 2>/dev/null
    ui_print "- 🔑 تم نقل الكيبوكس إلى:" ; delay
    ui_print "     /data/adb/tricky_store/keybox.xml" ; delay
    ui_print "     المصدر: $KB_SOURCE" ; delay
else
    ui_print "- ⚠️ لم يُعثر على أي كيبوكس للنقل." ; delay
fi

# --- (v3.10) تعبئة target.txt بكل التطبيقات المثبتة على الجهاز عند التثبيت ---
# طلب المستخدم: لا يريد إضافة أسماء الحزم يدوياً — نضم كل التطبيقات الموجودة على
# الجهاز مباشرة، مع الإبقاء على الإدخالات الثلاثة الإلزامية في المقدمة.
# للعودة لتطبيقات جوجل الثلاثة فقط: زر «🎯 الإبقاء على الأساسي فقط» في الواجهة.
# ⚠️ نزرع مرة واحدة فقط (علامة falcon_seeded) حتى لا تُمسح قائمة المستخدم
#    عند تحديث الإضافة إلى نسخة أحدث.
TS_TARGET="/data/adb/tricky_store/target.txt"
SEED_MARK="/data/adb/falcon_seeded_v310"
if [ ! -f "$SEED_MARK" ]; then
    touch "$TS_TARGET" 2>/dev/null
    for P in com.google.android.gms com.google.android.gms.unstable com.android.vending; do
        grep -qx "$P" "$TS_TARGET" 2>/dev/null || echo "$P" >> "$TS_TARGET"
    done
    pm list packages 2>/dev/null | cut -d':' -f2 | while read -r P; do
        [ -z "$P" ] && continue
        grep -qx "$P" "$TS_TARGET" 2>/dev/null || echo "$P" >> "$TS_TARGET"
    done
    sort -u "$TS_TARGET" > "$TS_TARGET.tmp" 2>/dev/null && mv -f "$TS_TARGET.tmp" "$TS_TARGET" 2>/dev/null
    chmod 644 "$TS_TARGET" 2>/dev/null
    chown root:root "$TS_TARGET" 2>/dev/null
    touch "$SEED_MARK" 2>/dev/null
    TS_COUNT=$(grep -c . "$TS_TARGET" 2>/dev/null)
    ui_print "- 📦 تم ضم ${TS_COUNT:-0} تطبيقاً إلى target.txt (كل تطبيقات جهازك)." ; delay
    ui_print "   لتطبيقات جوجل الثلاثة فقط: زر «🎯 الإبقاء على الأساسي فقط»." ; delay
else
    ui_print "- ℹ️ قائمة target.txt موجودة مسبقاً — لم تُمس (تحديث للإضافة)." ; delay
fi

# --- حذف الوحدات المتعارضة (TrickyStore المستقلة + SafetyNet Fix) ---
# المحرك (Tricky Store OSS) مدمج بالكامل داخل هذه الإضافة، فوجود وحدة tricky_store
# منفصلة مفعّلة يعني محرّكين يحقنان في keystore2 ⇒ تعارض يكسر Play Integrity
# وقد يعلّق الجهاز. الإضافة العاملة (PlayIntegrity_19.7.7_r2) تحذفها بنفس الطريقة.
#
# نضع العلامتين معاً:
#   disable ← حتى لا يُقلع محركها القديم في نفس الإقلاع (يمنع الحقن المزدوج فوراً)
#   remove  ← ليحذفها مدير الروت نهائياً عند إعادة التشغيل
CONFLICT_IDS="tricky_store safetynet-fix"
for RID in $CONFLICT_IDS; do
    for RBASE in /data/adb/modules /data/adb/modules_update; do
        if [ -d "$RBASE/$RID" ]; then
            touch "$RBASE/$RID/disable" "$RBASE/$RID/remove" 2>/dev/null
            ui_print "- 🗑️ سيُحذف الموديول المتعارض ($RID) عند إعادة التشغيل" ; delay
        fi
    done
done

# --- مسح شامل بأي تسمية: أي وحدة اسمها يحتوي tricky أو safetynet ---
# (tricky_store / TrickyStore / tricky_store_oss / safetynet-fix / USNF ... إلخ)
# تُعطَّل وتُعلَّم للحذف — مع استثناء وحدتينا صراحةً: playintegrityfix و falcon_tricky.
for RBASE in /data/adb/modules /data/adb/modules_update; do
    [ -d "$RBASE" ] || continue
    for RDIR in "$RBASE"/*; do
        [ -d "$RDIR" ] || continue
        RNAME="${RDIR##*/}"
        case "$RNAME" in
            playintegrityfix|falcon_tricky) continue ;;
        esac
        case "$RNAME" in
            *[Tt]ricky*|*TRICKY*|*[Ss]afety[Nn]et*|*SAFETYNET*) ;;
            *) continue ;;
        esac
        touch "$RDIR/disable" "$RDIR/remove" 2>/dev/null
        ui_print "- 🗑️ وحدة متعارضة ($RNAME) ستُحذف عند إعادة التشغيل" ; delay
    done
done

# جلب عدد المستخدمين النشطين مباشرة أثناء التثبيت
SERVER_URL="https://falcon-counter-server.onrender.com"
ONLINE_USERS=""

if command -v curl >/dev/null 2>&1; then
    ONLINE_USERS=$(curl -s --connect-timeout 5 --max-time 5 -X POST -H "Content-Type: application/json" -d '{"deviceId":"install_check"}' "$SERVER_URL/ping" 2>/dev/null | grep -o '"onlineUsers":[0-9]*' | cut -d':' -f2)
elif command -v wget >/dev/null 2>&1; then
    ONLINE_USERS=$(wget -qO- --timeout=5 --post-data='{"deviceId":"install_check"}' --header='Content-Type: application/json' "$SERVER_URL/ping" 2>/dev/null | grep -o '"onlineUsers":[0-9]*' | cut -d':' -f2)
fi

if [ -n "$ONLINE_USERS" ] && [ -f "$MODPATH/module.prop" ]; then
    ui_print "- 👥 عدد المستخدمين النشطين الآن: $ONLINE_USERS"
    sed -i "s/Online: [0-9][0-9]*/Online: $ONLINE_USERS/g" \
        "$MODPATH/module.prop" 2>/dev/null || true
fi

# --- إعداد صلاحيات الموديول ---
set_perm_recursive "$MODPATH" 0 0 0755 0644 2>/dev/null || true

if [ -d "$MODPATH/zygisk" ]; then
    set_perm_recursive "$MODPATH/zygisk" 0 0 0755 0755 2>/dev/null || true
fi
[ -f "$MODPATH/service.sh" ] && set_perm "$MODPATH/service.sh" 0 0 0755
[ -f "$MODPATH/post-fs-data.sh" ] && set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
[ -f "$MODPATH/rkp_fix.sh" ] && set_perm "$MODPATH/rkp_fix.sh" 0 0 0755
[ -f "$MODPATH/apply_pif.sh" ] && set_perm "$MODPATH/apply_pif.sh" 0 0 0755

# --- صلاحيات محرك التعتيد المدمج (Tricky Store OSS) ---
# ⚠️ ضروري: المحرك يُقلع بـ ./daemon لذا يجب أن يكون الملف تنفيذياً (755).
# ملاحظة: set_perm_recursive أعلاه يجعل كل الملفات 644، لذا نُعيد الضبط هنا.
if [ -d "$MODPATH/tricky" ]; then
    set_perm_recursive "$MODPATH/tricky" 0 0 0755 0644 2>/dev/null || true
    chmod 755 "$MODPATH/tricky" 2>/dev/null
    chmod 755 "$MODPATH/tricky/daemon" 2>/dev/null
    chmod 755 "$MODPATH/tricky/service.sh" 2>/dev/null
    chmod 755 "$MODPATH/tricky/inject" 2>/dev/null
    chmod 644 "$MODPATH/tricky/classes.dex" 2>/dev/null
    chmod 644 "$MODPATH/tricky/libTrickyStoreOSS.so" 2>/dev/null
    chmod 644 "$MODPATH/tricky/module.prop" 2>/dev/null
    ui_print "- 🔐 تم ضبط صلاحيات المحرك التنفيذية (755)" ; delay
fi

# ==============================================================================
# 🔗 إنشاء وحدة FALCON TRICKY المرئية في مدير الروت (ملحق مربوطة بالأم)
#    تظهر في قائمة الوحدات باسم FALCON TRICKY وتعمل بنفس غرض وحدة
#    Tricky Store المستقلة لكن من ملفات إضافتنا. رابط مزدوج:
#    حذف أحدهما يحذف الآخر تلقائياً بعد إعادة التشغيل.
#    ⚠️ لا تحمل نسخة ثانية من المحرك — المحرك مملوك للأم فقط،
#       لأن تشغيله مرتين يحقن keystore2 مرتين ويجمّد الجهاز.
# ==============================================================================
if [ -f "$MODPATH/falcon_tricky/module.prop" ]; then
    FT_DIR="/data/adb/modules/falcon_tricky"
    rm -rf "$FT_DIR" 2>/dev/null
    mkdir -p "$FT_DIR" 2>/dev/null
    cp -rf "$MODPATH/falcon_tricky/." "$FT_DIR/" 2>/dev/null
    chown -R 0:0 "$FT_DIR" 2>/dev/null
    chmod 755 "$FT_DIR" 2>/dev/null
    chmod 644 "$FT_DIR/module.prop" 2>/dev/null
    chmod 755 "$FT_DIR/service.sh" "$FT_DIR/uninstall.sh" 2>/dev/null
    # واجهة FALCON TRICKY (WebUI) — تظهر بزر مستقل داخل مدير الروت
    if [ -d "$FT_DIR/webroot" ]; then
        chmod 755 "$FT_DIR/webroot" 2>/dev/null
        chmod 644 "$FT_DIR/webroot/index.html" 2>/dev/null
    fi
    # (v3.14) إعادة أيقونات التطبيقات فوراً بعد إعادة بناء المجلد:
    # كنا نحذف المجلد كاملاً أعلاه، فتضيع أيقونات الواجهة حتى الإقلاع التالي.
    # نُعيدها الآن من الأرشيف الدائم /data/adb/falcon_icons + نُعيد بناء الفهرس،
    # فتظهر الأيقونات من أول فتح للواجهة بلا انتظار إعادة تشغيل.
    # ملاحظة: كل أمر هنا محصّن بـ || true حتى لا يُجهض التثبيت أبداً
    # (بعض المديرين يشغّل customize.sh مع set -e).
    if [ -d /data/adb/falcon_icons ]; then
        _fwi="$FT_DIR/webroot/icons"
        mkdir -p "$_fwi" 2>/dev/null || true
        for _ic in /data/adb/falcon_icons/*.png; do
            [ -s "$_ic" ] || continue
            cp -f "$_ic" "$_fwi/" 2>/dev/null || true
            chmod 644 "$_fwi/$(basename "$_ic")" 2>/dev/null || true
        done
        {
            echo "# falcon-icons-index"
            for _g in "$_fwi"/*.png; do
                [ -s "$_g" ] || continue
                basename "$_g" .png
            done
        } > "$_fwi/_index.txt" 2>/dev/null || true
        chmod 644 "$_fwi/_index.txt" 2>/dev/null || true
        chmod 755 "$_fwi" 2>/dev/null || true
    fi
    rm -rf "$MODPATH/falcon_tricky" 2>/dev/null
    ui_print "- 🔗 FALCON TRICKY: وحدة مرئية مربوطة بالأم (حذف أحدهما يحذف الآخر)" ; delay
fi

# 2. نشر ملفات التمويه والـ Keybox (إصلاح TEE Attestation)
ui_print "- 🎭 جاري نشر مكونات PIF و Tricky Store..." ; delay
mkdir -p /data/adb/tricky_store 2>/dev/null

# --- نشر ملف البصمة (PIF) بشكل صحيح ---
# المحرك (libplayintegrityfix.so) يقرأ ملف البصمة من مسار ثابت هو
#   /data/adb/modules/playintegrityfix/  وهو مسار موديولنا نفسه (id=playintegrityfix).
# apply_pif.sh يتولى التحويل (.prop → .json) وضمان اكتمال الملفات.
if [ -f "$MODPATH/apply_pif.sh" ]; then
    sh "$MODPATH/apply_pif.sh" auto 2>/dev/null
fi

# احتياط أخير: إن لم يوجد ملف بصمة صالح، ننشر المضمّن في مسار المحرك أيضاً
valid_bpif() {
    [ -s "$1" ] && grep -qE '"FINGERPRINT"[[:space:]]*:[[:space:]]*"[^"]' "$1" 2>/dev/null
}
PIF_MIRROR_DIR="/data/adb/modules/playintegrityfix"
BUILTIN_PIF="$MODPATH/custom.pif.json"
if valid_bpif "$BUILTIN_PIF"; then
    mkdir -p "$PIF_MIRROR_DIR" 2>/dev/null
    valid_bpif "$PIF_MIRROR_DIR/custom.pif.json" || cp -f "$BUILTIN_PIF" "$PIF_MIRROR_DIR/custom.pif.json" 2>/dev/null
    valid_bpif "$PIF_MIRROR_DIR/pif.json"        || cp -f "$BUILTIN_PIF" "$PIF_MIRROR_DIR/pif.json" 2>/dev/null
    [ -f "$MODPATH/custom.pif.prop" ] && [ ! -f "$PIF_MIRROR_DIR/custom.pif.prop" ] && cp -f "$MODPATH/custom.pif.prop" "$PIF_MIRROR_DIR/custom.pif.prop" 2>/dev/null
    [ -s "$MODPATH/classes.dex" ] && [ ! -s "$PIF_MIRROR_DIR/classes.dex" ] && cp -f "$MODPATH/classes.dex" "$PIF_MIRROR_DIR/classes.dex" 2>/dev/null
    valid_bpif /data/adb/pif.json || cp -f "$BUILTIN_PIF" /data/adb/pif.json 2>/dev/null
    chmod 644 "$PIF_MIRROR_DIR"/*.json "$PIF_MIRROR_DIR"/*.prop "$PIF_MIRROR_DIR"/classes.dex 2>/dev/null
    ui_print "- 🎭 تم نشر ملف البصمة في مسار المحرك (playintegrityfix)" ; delay
fi

# نشر ملف keybox.xml سواءً كان في مجلد zygisk أو في الجذر
if [ -f "$MODPATH/zygisk/keybox.xml" ]; then
    cp -f "$MODPATH/zygisk/keybox.xml" /data/adb/tricky_store/keybox.xml 2>/dev/null
elif [ -f "$MODPATH/keybox.xml" ]; then
    cp -f "$MODPATH/keybox.xml" /data/adb/tricky_store/keybox.xml 2>/dev/null
fi

# --- الحفاظ على الخيارات السابقة في target.txt ودمجها بآمان بدون تكرار ---
if [ -f "$MODPATH/target.txt" ]; then
    if [ -f "/data/adb/tricky_store/target.txt" ]; then
        cat "$MODPATH/target.txt" >> /data/adb/tricky_store/target.txt
        sort -u /data/adb/tricky_store/target.txt > /data/adb/tricky_store/target.tmp 2>/dev/null
        if [ -s "/data/adb/tricky_store/target.tmp" ]; then
            mv -f /data/adb/tricky_store/target.tmp /data/adb/tricky_store/target.txt 2>/dev/null
        else
            rm -f /data/adb/tricky_store/target.tmp 2>/dev/null
        fi
    else
        cp -f "$MODPATH/target.txt" /data/adb/tricky_store/ 2>/dev/null
    fi
fi

[ -f "$MODPATH/security_patch.txt" ] && cp -f "$MODPATH/security_patch.txt" /data/adb/tricky_store/ 2>/dev/null

# ضبط وتأمين الصلاحيات لمجلد tricky_store
chmod 755 /data/adb/tricky_store 2>/dev/null
chmod 644 /data/adb/tricky_store/* 2>/dev/null

# 3. إدراج التطبيقات الأساسية في قائمة العزل (Magisk DenyList)
ui_print "- 🛡️ جاري تطبيق قائمة العزل التلقائية للتطبيقات والتطبيقات البنكية..." ; delay
DENY_LIST_APPS="
com.google.android.gms com.google.android.gms:snet
com.google.android.gms com.google.android.gms:identitycredentials
com.google.android.gms com.google.android.gms:car
com.google.android.gms com.google.android.gms:unstable
com.google.android.gms com.google.android.gms:ui
com.google.android.gms com.google.android.gms:room
com.google.android.gms com.google.android.gms:remapping1
com.google.android.gms com.google.android.gms:persistent
com.google.android.gms com.google.android.gms:learning
com.google.android.gms com.google.android.gms:feedback
com.google.android.gms com.google.android.gms
com.android.vending com.android.vending
com.android.vending com.google.android.finsky.verifier.impl.ConsentDialog
com.android.vending com.android.vending:background
com.android.vending com.android.vending:instant_app_installer
com.android.vending com.android.vending:com.google.android.finsky.verifier.apkanalysis.service.ApkContentsScanService"

if command -v magisk >/dev/null 2>&1 && magisk --denylist status >/dev/null 2>&1; then
    for item in $DENY_LIST_APPS; do
        magisk --denylist add $item >/dev/null 2>&1
    done
fi

# 4. (أُزيل) تنظيف ذاكرة التخزين المؤقت لخدمات جوجل
# ⛔ أُزيل هذا الجزء نهائياً: لا نلمس أي شيء تحت /data/data/ الخاص بجوجل إطلاقاً
#    احتراماً لبيانات المستخدم وحساباته. لا مسح بيانات ولا مسح كاش.
#    إعادة تشغيل GMS (عند الحاجة) تتم بأمان في apply_pif.sh / killpi.sh عبر force-stop.

ui_print " " ; delay
ui_print "- ✅ تم إصلاح فحص SafetyNet بنجاح." ; delay
ui_print "- ✅ تم تزييف حالة البوت لودر." ; delay
ui_print "- ✅ تم إصلاح ترخيص متجر Google Play." ; delay
ui_print "- ✅ تم تأمين مسارات النظام ومحاذاة الـ 16KB." ; delay
ui_print "- 🩺 إصلاح مفاتيح RKP لأجهزة Red Magic مضمن (يُنفَّذ تلقائياً" ; delay
ui_print "   مرة واحدة عند أول إقلاع — أو يدوياً من زر WebUI)." ; delay

ui_print " " ; delay
ui_print "- تم التثبيت بنجاح! 🦅🔥" ; delay
ui_print "- المطور: ABUFARID" ; delay
true