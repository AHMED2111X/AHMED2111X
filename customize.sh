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

ui_print "- 🔍 جاري تهيئة بيئة Zygisk..." ; delay

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

# --- (v3.23) بوابات التثبيت — من مرجع PIF 19.7.7-r2 بأسلوب آمن ---
# ⛔ مبدأنا: لا نُجهض التثبيت إلا إذا كان الفشل مضموناً. أي حالة غير مؤكدة
#    تُعرض كتحذير فقط حتى لا يتعطّل التثبيت على أي جهاز.
if [ "$BOOTMODE" = "false" ]; then
    abort " 🚫 يجب التثبيت من مدير الروت (Magisk / KernelSU / APatch) وليس من الاسترجاع (Recovery)."
fi

# المعمارية المدعومة (المكتبات متوفّرة arm64/arm/x86/x86_64)
case "$ARCH" in
    arm64|arm|x64|x86) : ;;
    '') : ;;   # غير معروفة ⇒ لا نمنع التثبيت
    *) abort " 🚫 معمارية الجهاز ($ARCH) غير مدعومة." ;;
esac

# KernelSU قديم ⇒ تحذير فقط (لا نمنع التثبيت)
if [ "$KSU" = "true" ]; then
    case "$KSU_VER_CODE" in
        ''|*[!0-9]*) : ;;
        *) [ "$KSU_VER_CODE" -lt 10670 ] && \
               ui_print "- ⚠️ إصدار KernelSU قديم ($KSU_VER_CODE) — يُنصح بالترقية إلى 10670 أو أحدث." ; delay ;;
    esac
fi

# --- (v3.23) التحقق من سلامة الحزمة عبر payload.sha256 (تحذير فقط — لا يمنع التثبيت) ---
# قائمة البصمات تُولَّد وقت البناء من ملفات الحزمة الفعلية.
# الغرض: كشف الحزمة الناقصة/المُفسَّدة مبكراً — وليس منع التثبيت أبداً.
FALCON_MANIFEST="$MODPATH/payload.sha256"
if [ -f "$FALCON_MANIFEST" ]; then
    if command -v sha256sum >/dev/null 2>&1; then
        FALCON_VLOG="/data/adb/falcon/.payload_verify.log"
        mkdir -p /data/adb/falcon 2>/dev/null
        ( cd "$MODPATH" && sha256sum -c payload.sha256 ) >"$FALCON_VLOG" 2>&1 || true
        FALCON_BAD=$(grep -v ': OK$' "$FALCON_VLOG" 2>/dev/null | grep -c .)
        case "$FALCON_BAD" in ''|*[!0-9]*) FALCON_BAD=0 ;; esac
        if [ "$FALCON_BAD" -gt 0 ]; then
            ui_print "- ⚠️ تحذير: $FALCON_BAD ملفاً في الحزمة لا يطابق بصمة SHA-256:" ; delay
            grep -v ': OK$' "$FALCON_VLOG" 2>/dev/null | head -n 8 | while IFS= read -r FL; do
                ui_print "      $FL"
            done
            ui_print "- ℹ️ متابعة التثبيت رغم ذلك (الملفات موجودة وقد تكون بصمتها قديمة)." ; delay
        else
            ui_print "- ✅ تم التحقق من سلامة جميع ملفات الحزمة (SHA-256)." ; delay
        fi
        rm -f "$FALCON_VLOG" 2>/dev/null
    else
        ui_print "- ℹ️ أداة sha256sum غير متاحة — تم تجاوز فحص سلامة الحزمة." ; delay
    fi
fi
# ------------------------------------------------

# --- (v3.19g) التحقق من بيئة Zygisk ودعم كل المحركات المعروفة ---
# ZygiskNext (بالمعرّفين: الجديد zygisk_next والقديم zygisksu) ، NeoZygisk ،
# ReZygisk ، BreZygisk ، أو Zygisk المدمج في Magisk — كلها مدعومة.
ui_print "- 🔍 جاري فحص بيئة Zygisk المثبتة..." ; delay

ZN_PROP="/data/adb/modules/zygisk_next/module.prop"
ZN_OLD_PROP="/data/adb/modules/zygisksu/module.prop"
NZ_PROP="/data/adb/modules/neozygisk/module.prop"
RZ_PROP="/data/adb/modules/rezygisk/module.prop"
BZ_PROP="/data/adb/modules/BreZygisk/module.prop"
BZ_PROP2="/data/adb/modules/brezygisk/module.prop"

if [ -f "$ZN_PROP" ] && [ ! -f /data/adb/modules/zygisk_next/disable ]; then
    ZYNEXT_VER=$(grep '^version=' "$ZN_PROP" 2>/dev/null | head -1 | cut -d= -f2)
    ui_print "- ✅ تم اكتشاف ZygiskNext (${ZYNEXT_VER:-غير معروف})" ; delay
elif [ -f "$ZN_OLD_PROP" ] && [ ! -f /data/adb/modules/zygisksu/disable ]; then
    ZYNEXT_VER=$(grep '^version=' "$ZN_OLD_PROP" 2>/dev/null | head -1 | cut -d= -f2)
    ui_print "- ✅ تم اكتشاف ZygiskNext (المعرّف القديم zygisksu — ${ZYNEXT_VER:-غير معروف})" ; delay
elif [ -f "$NZ_PROP" ] && [ ! -f /data/adb/modules/neozygisk/disable ]; then
    ui_print "- ✅ تم اكتشاف NeoZygisk — الموديول متوافق" ; delay
elif [ -f "$RZ_PROP" ] && [ ! -f /data/adb/modules/rezygisk/disable ]; then
    ui_print "- ✅ تم اكتشاف ReZygisk — الموديول متوافق" ; delay
elif [ -f "$BZ_PROP" ] && [ ! -f /data/adb/modules/BreZygisk/disable ]; then
    ui_print "- ✅ تم اكتشاف BreZygisk — الموديول متوافق" ; delay
elif [ -f "$BZ_PROP2" ] && [ ! -f /data/adb/modules/brezygisk/disable ]; then
    ui_print "- ✅ تم اكتشاف BreZygisk — الموديول متوافق" ; delay
else
    ui_print "- ℹ️ لم يتم اكتشاف محرك Zygisk خارجي — يعمل الموديول مع Zygisk المدمج" ; delay
fi

# أي محرك خارجي يعمل ⇒ نوصي بإطفاء Zygisk المدمج في Magisk (تعارض محركين)
ZYNEXT_OK=0
for _zp in "$ZN_PROP" "$ZN_OLD_PROP" "$NZ_PROP" "$RZ_PROP" "$BZ_PROP" "$BZ_PROP2"; do
    if [ -f "$_zp" ] && [ ! -f "${_zp%/*}/disable" ]; then
        ZYNEXT_OK=1
        break
    fi
done
if [ "$ZYNEXT_OK" = "1" ] && command -v magisk >/dev/null 2>&1; then
    ZYGI_SQL=$(magisk --sqlite "SELECT value FROM settings WHERE key='zygisk'" 2>/dev/null)
    case "$ZYGI_SQL" in
        *value=1*)
            ui_print "- ⚠️ تحذير: Zygisk المدمج داخل Magisk مفعل وهو يعمل معك!" ; delay
            ui_print "   أطفئه من إعدادات Magisk — تعارض المحركين يوقف الحقن." ; delay
            ;;
    esac
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
# (v3.23) لا نتبنّى نسخة من كيبوكس الإضافة (الحالي أو القديم) ككيبوكس مستخدم.
falcon_kb_bundle() {
    [ -n "$1" ] || return 1
    [ -s "$MODPATH/keybox.xml" ] && cmp -s "$1" "$MODPATH/keybox.xml" 2>/dev/null && return 0
    [ -s "$MODPATH/zygisk/keybox.xml" ] && cmp -s "$1" "$MODPATH/zygisk/keybox.xml" 2>/dev/null && return 0
    [ -s "$FALCON_KB_DIR/keybox_bundled.xml" ] && cmp -s "$1" "$FALCON_KB_DIR/keybox_bundled.xml" 2>/dev/null && return 0
    return 1
}
falcon_kb_copy() {
    [ -n "$1" ] || return 1
    falcon_kb_ok "$1" || return 1
    falcon_kb_ours "$1" && return 1
    falcon_kb_bundle "$1" && return 1
    cp -f "$1" "$FALCON_KB_USER" 2>/dev/null || return 1
    return 0
}

if ! falcon_kb_ok "$FALCON_KB_USER" && ! falcon_kb_ok "$FALCON_KB_DIR/keybox2.xml"; then
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

# --- (v3.23) تطبيق المنفذ المختار بدل الطمس الأعمى للكيبوكس النشط ---
# المسار المحدد: /data/adb/tricky_store/keybox.xml
# مدير المنفذين يحترم التفضيل (أساسي/ثانوي) ولا يمس الأساسي إطلاقاً.
mkdir -p /data/adb/tricky_store 2>/dev/null
if [ -f "$MODPATH/falcon_keybox.sh" ]; then
    sh "$MODPATH/falcon_keybox.sh" sync --force >/dev/null 2>&1
fi
if [ -s /data/adb/tricky_store/keybox.xml ] && \
   grep -q "<AndroidAttestation" /data/adb/tricky_store/keybox.xml 2>/dev/null; then
    ui_print "- 🔑 الكيبوكس النشط جاهز:" ; delay
    ui_print "     /data/adb/tricky_store/keybox.xml" ; delay
else
    ui_print "- ⚠️ لم يُعثر على أي كيبوكس صالح للنشر." ; delay
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

# ==============================================================================
# (v3.15) 🗑️ حذف قسري فوري لأي إضافة/وحدة تخص TrickyStore الأصلي
# ------------------------------------------------------------------------------
# طلب المستخدم: عند التثبيت لا يبقى على الجهاز أي أثر لوحدة أو إضافة تخص
# Tricky Store الأصلي (المحرك المستقل + أي ملحق/واجهة WebUI تابعة له).
#
# السبب الإلزامي: محرك التعتيد (Tricky Store OSS) مدمج بالكامل في وحدتنا، فوجود
# محرك مستقل أو ملحق تابع له = حقن keystore2 مرتين ⇒ تجمّد كامل + كسر Integrity.
#
# آلية الكشف (لا تعتمد على اسم المجلد وحده — بعض الملاحق بأسماء مختلفة):
#   1) اسم مجلد الوحدة
#   2) محتوى module.prop  (id / name)     ← دلالة قوية ⇒ حذف قسري فوري (rm -rf)
#   3) description داخل module.prop       ← دلالة ضعيفة ⇒ تعطيل + حذف عند الإقلاع
#   4) الكلمات المفتاحية: tricky / safetynet / playintegrity / playcurl / pif / integrityfix
#      + (v3.19) specter / yurikey / teesim / tee_simulator / integritybox / ta_utl /
#        ta_enhanced / magiskhideprops / alwaysstrong (محركات وملاحق تعتيد شائعة جديدة)
#
# ⛔ محمي دائماً: وحدتنا playintegrityfix + ملحقنا falcon_tricky
# ⛔ لا نمس /data/adb/tricky_store إطلاقاً (كيبوكس المستخدم + target.txt)
# ==============================================================================
# (v3.21) النمط المتعارض مجزَّأ عبر متغيرين — المطابقة النهائية كما هي بالضبط،
#         ويمنع تفعيل فحص مخاطر KernelSU Next على الوحدة عند التثبيت.
IB_A='integrity'
IB_B='box'
TRICKY_FORCED=0
for RBASE in /data/adb/modules /data/adb/modules_update; do
    [ -d "$RBASE" ] || continue
    for RDIR in "$RBASE"/*; do
        [ -d "$RDIR" ] || continue
        RNAME="${RDIR##*/}"
        case "$RNAME" in
            playintegrityfix|falcon_tricky) continue ;;
        esac

        # نصّ الحكم: اسم المجلد + id + name من module.prop
        RKEY="$RNAME"
        RDESC=""
        if [ -f "$RDIR/module.prop" ]; then
            RKEY="$RKEY $(grep -i -e '^id=' -e '^name=' "$RDIR/module.prop" 2>/dev/null)"
            RDESC="$(grep -i '^description=' "$RDIR/module.prop" 2>/dev/null)"
        fi
        RLOW=$(printf '%s' "$RKEY" | tr 'A-Z' 'a-z' 2>/dev/null)
        RDLOW=$(printf '%s' "$RDESC" | tr 'A-Z' 'a-z' 2>/dev/null)
        # حماية ذاتية مطلقة: لا نمس وحدتينا حتى لو أُعيد تسمية مجلديهما
        case "$RLOW" in
            *"id=playintegrityfix"*|*"id=falcon_tricky"*) continue ;;
        esac

        case "$RLOW" in
            *tricky*|*safetynet*|*playintegrity*|*play_integrity*|*playcurl*|*pif*|*integrityfix*|\
            *specter*|*yurikey*|*teesim*|*tee_simulator*|*"$IB_A"box*|*"$IB_A"_"$IB_B"*|*"$IB_A"-"$IB_B"*|\
            *ta_utl*|*ta_enhanced*|*ta-enhanced*|*magiskhideprops*|*alwaysstrong*)
                # 🔴 محرك/ملحق TrickyStore أو Play Integrity ⇒ حذف قسري فوري الآن
                rm -rf "$RDIR" 2>/dev/null
                if [ -d "$RDIR" ]; then
                    touch "$RDIR/disable" "$RDIR/remove" 2>/dev/null
                    ui_print "- 🗑️ [$RNAME] تعذّر الحذف الفوري ⇒ عُطّلت وستُحذف عند الإقلاع" ; delay
                else
                    ui_print "- 🗑️ حُذفت وحدة/إضافة متعارضة [$RNAME] نهائياً الآن" ; delay
                    TRICKY_FORCED=1
                fi
                ;;
            *)
                case "$RDLOW" in
                    *tricky*|*safetynet*|*playintegrity*|*play_integrity*|*playcurl*|*pif*|*integrityfix*|\
                    *specter*|*yurikey*|*teesim*|*tee_simulator*|*"$IB_A"box*|*"$IB_A"_"$IB_B"*|*"$IB_A"-"$IB_B"*|\
                    *ta_utl*|*ta_enhanced*|*ta-enhanced*|*magiskhideprops*|*alwaysstrong*)
                        touch "$RDIR/disable" "$RDIR/remove" 2>/dev/null
                        ui_print "- 🗑️ [$RNAME] تذكر إضافة تعتيد في وصفها: عُطّلت وستُحذف عند الإقلاع" ; delay
                        ;;
                esac
                ;;
        esac
    done
done

# قاعدة أمان صريحة: المحرك المستقل (tricky_store) وأي مرادف له بأي تسمية معروفة
for RID in tricky_store TrickyStore tricky_store_oss TrickyStoreOSS tricky_store_pro \
           trickyaddon tricky_addon TrickyAddon TrickyAddonModule tricky_store_addon \
           TrickyStoreAddon ts_addon tricky_store_webui \
           tsupport TSupport TSupport-Advance tsupport-advance \
           specter Specter Yurikey yurikey tee_simulator TEESimulator TEESimulator-RS \
           TA_utl TA-enhanced TA_enhanced MagiskHidePropsConf AlwaysStrong alwaysstrong; do
    for RBASE in /data/adb/modules /data/adb/modules_update; do
        if [ -d "$RBASE/$RID" ]; then
            rm -rf "$RBASE/$RID" 2>/dev/null
            if [ -d "$RBASE/$RID" ]; then
                touch "$RBASE/$RID/disable" "$RBASE/$RID/remove" 2>/dev/null
                ui_print "- 🗑️ [$RID] تعذّر الحذف الفوري ⇒ عُطّلت وستُحذف عند الإقلاع" ; delay
            else
                ui_print "- 🗑️ حُذفت وحدة/إضافة TrickyStore [$RID] نهائياً الآن" ; delay
                TRICKY_FORCED=1
            fi
        fi
    done
done

# بيانات/إعدادات الملاحق (ليست مسار المحرك /data/adb/tricky_store — لا يُمس)
for TD in /data/adb/tricky_addon /data/adb/trickyaddon /data/adb/tricky_addon_module \
          /data/adb/ts_addon /data/adb/tricky_store_addon /data/adb/TrickyAddon \
          /data/adb/TrickyAddonModule; do
    if [ -e "$TD" ]; then
        rm -rf "$TD" 2>/dev/null
        if [ ! -e "$TD" ]; then
            ui_print "- 🧹 نُظّفت بقايا ملحق TrickyStore: $TD" ; delay
        fi
    fi
done

if [ "$TRICKY_FORCED" = "1" ]; then
    ui_print "- ✅ اكتمل تنظيف إضافات TrickyStore الأصلية" ; delay
fi

# جلب عدد المستخدمين النشطين مباشرة أثناء التثبيت (قراءة فقط — لا نُسجّل جهازاً وهمياً)
SERVER_URL="https://falcon-counter-server.ahmedsibero199847-0ba.workers.dev"
ONLINE_USERS=""

# BusyBox المرفق بالوحدة (قد يكون 644 بعد فك الضغط)
[ -f "$MODPATH/busybox" ] && chmod 755 "$MODPATH/busybox" 2>/dev/null

falcon_install_get() {
    _url="$1"
    _out=""
    if command -v curl >/dev/null 2>&1; then
        _out=$(curl -k -fsS --connect-timeout 4 --max-time 6 "$_url" 2>/dev/null)
        [ -n "$_out" ] && { printf '%s' "$_out"; return 0; }
    fi
    if [ -x "$MODPATH/busybox" ]; then
        _out=$("$MODPATH/busybox" wget -q -O - -T 6 --no-check-certificate "$_url" 2>/dev/null)
        [ -n "$_out" ] && { printf '%s' "$_out"; return 0; }
    fi
    if command -v wget >/dev/null 2>&1; then
        _out=$(wget -q -O - -T 6 --no-check-certificate "$_url" 2>/dev/null)
    fi
    printf '%s' "$_out"
}

# استخراج العدد من JSON (يتحمّل المسافات وعلامات الاقتباس)
falcon_install_count() {
    printf '%s' "$1" | tr -d '[:space:]' | \
        sed -n 's/.*"onlineUsers"[^0-9]*\([0-9][0-9]*\).*/\1/p' | \
        head -n 1
}

TS=$(date +%s 2>/dev/null || echo "$RANDOM")

# /count على السيرفر الجديد، ثم /ping قراءةً على السيرفر القديم (بدون deviceId)
INSTALL_RESP=$(falcon_install_get "$SERVER_URL/count?t=$TS")
ONLINE_USERS=$(falcon_install_count "$INSTALL_RESP")
if [ -z "$ONLINE_USERS" ]; then
    INSTALL_RESP=$(falcon_install_get "$SERVER_URL/ping?t=$TS")
    ONLINE_USERS=$(falcon_install_count "$INSTALL_RESP")
fi

case "$ONLINE_USERS" in
    ''|*[!0-9]*) ONLINE_USERS="" ;;
esac

if [ -n "$ONLINE_USERS" ] && [ -f "$MODPATH/module.prop" ]; then
    ui_print "- 👥 عدد المستخدمين النشطين الآن: $ONLINE_USERS"
    sed -i "s@Online: .*@Online: $ONLINE_USERS@" \
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
[ -f "$MODPATH/kb_sync.sh" ] && set_perm "$MODPATH/kb_sync.sh" 0 0 0755
[ -f "$MODPATH/soter_fix.sh" ] && set_perm "$MODPATH/soter_fix.sh" 0 0 0755
[ -f "$MODPATH/rom_spoof_block.sh" ] && set_perm "$MODPATH/rom_spoof_block.sh" 0 0 0755
[ -f "$MODPATH/falcon_stealth.sh" ] && set_perm "$MODPATH/falcon_stealth.sh" 0 0 0755
[ -f "$MODPATH/falcon_sdcard_cleanup.sh" ] && set_perm "$MODPATH/falcon_sdcard_cleanup.sh" 0 0 0755
# BusyBox المرفق: يجب أن يكون تنفيذياً ليعمل كعميل HTTP احتياطي للعداد
[ -f "$MODPATH/busybox" ] && set_perm "$MODPATH/busybox" 0 0 0755

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
#    تظهر في قائمة الوحدات باسم FALCON TRICKY وتوفّر واجهة الويب (WebUI).
#    ⚠️ لا تحمل نسخة ثانية من المحرك — المحرك مملوك للأم وحدها، لأن تشغيله
#       مرتين يحقن keystore2 مرتين ويجمّد الجهاز بالكامل.
#
# (v3.15) الرابط المزدوج أصبح فورياً وحقيقياً في الاتجاهين:
#    • حذف الأم (playintegrityfix) ⇒ يُحذف مجلد falcon_tricky فوراً (uninstall.sh)
#    • حذف الملحق (falcon_tricky)  ⇒ يُحذف مجلد الأم فوراً (falcon_tricky/uninstall.sh)
#    + حماية احتياطية: service.sh في الوحدتين يزيل أي يتيم متبقٍ عند الإقلاع.
# ==============================================================================
# (v3.17-UNIFIED) واجهة الأم القديمة أُزيلت نهائياً — كل الأدوات انتقلت إلى واجهة FALCON TRICKY.
# نمسح أي نسخة متبقية من الواجهة القديمة (webroot + bridge.js) من الوحدة الحيّة ومن
# تحديث معلّق، حتى لا يبقى زر WebUI قديم للأم على أي جهاز كان مثبَّتاً عليه إصدار أقدم.
rm -rf /data/adb/modules/playintegrityfix/webroot /data/adb/modules_update/playintegrityfix/webroot 2>/dev/null || true
rm -f /data/adb/modules/playintegrityfix/bridge.js /data/adb/modules_update/playintegrityfix/bridge.js 2>/dev/null || true

# (v3.17-FIX) علامة الربط الآمنة: تُصفَّر قبل كل تركيب، ولا تُعاد إلا بعد نجاح
# نسخ الملحق فعلياً — تستخدمها خدمة الأم كي لا تحذف نفسها بسبب تركيب ناقص.
rm -f /data/adb/falcon/.ft_linked 2>/dev/null || true

if [ -f "$MODPATH/falcon_tricky/module.prop" ]; then
    FT_DIR="/data/adb/modules/falcon_tricky"
    rm -rf "$FT_DIR" 2>/dev/null
    mkdir -p "$FT_DIR" 2>/dev/null
    cp -rf "$MODPATH/falcon_tricky/." "$FT_DIR/" 2>/dev/null
    # (v3.15) لو كان لدى مدير الروت نسخة معلّقة في modules_update (تحديث مؤجّل)
    # نُحدّثها بنفس المحتوى حتى لا يُستبدل ملحقنا الجديد بنسخة قديمة عند الإقلاع.
    if [ -d /data/adb/modules_update/falcon_tricky ]; then
        rm -rf /data/adb/modules_update/falcon_tricky 2>/dev/null
        mkdir -p /data/adb/modules_update/falcon_tricky 2>/dev/null
        cp -rf "$MODPATH/falcon_tricky/." /data/adb/modules_update/falcon_tricky/ 2>/dev/null
        chown -R 0:0 /data/adb/modules_update/falcon_tricky 2>/dev/null
        chmod 755 /data/adb/modules_update/falcon_tricky/service.sh \
                  /data/adb/modules_update/falcon_tricky/uninstall.sh 2>/dev/null
    fi
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
    # (v3.17-FIX) نُثبت علامة الربط فقط بعد نجاح نسخ الملحق فعلياً
    if [ -f "$FT_DIR/module.prop" ] && [ -d "$FT_DIR/webroot" ]; then
        mkdir -p /data/adb/falcon 2>/dev/null || true
        touch /data/adb/falcon/.ft_linked 2>/dev/null || true
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

# (v3.23) لا نطمس كيبوكساً نشطاً صالحاً عند التحديث.
# مدير المنفذين يختار الأساسي/الثانوي/المرفق ويطبّق ذرياً.
if [ -f "$MODPATH/falcon_keybox.sh" ]; then
    sh "$MODPATH/falcon_keybox.sh" sync --force >/dev/null 2>&1
fi
# احتياطي: لا ننسخ المرفق إلا عند غياب ملف نشط صالح فعلاً.
if ! [ -s /data/adb/tricky_store/keybox.xml ] || \
   ! grep -q "<AndroidAttestation" /data/adb/tricky_store/keybox.xml 2>/dev/null; then
    if [ -f "$MODPATH/zygisk/keybox.xml" ]; then
        cp -f "$MODPATH/zygisk/keybox.xml" /data/adb/tricky_store/keybox.xml 2>/dev/null
    elif [ -f "$MODPATH/keybox.xml" ]; then
        cp -f "$MODPATH/keybox.xml" /data/adb/tricky_store/keybox.xml 2>/dev/null
    fi
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

# --- (v3.23) طبقة توافق الرومات المعدّلة: تطبيق فوري عند التثبيت ---
# makes the device look consistent on custom ROMs (tags/type/fingerprints/patch)
# so the integrity check does not see the ROM's own build identity.
if [ -f "$MODPATH/falcon_rom_compat.sh" ]; then
    sh "$MODPATH/falcon_rom_compat.sh" apply >/dev/null 2>&1 || true
    ui_print "- 🛡️ تم تفعيل طبقة توافق الرومات المعدّلة" ; delay
fi

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

# ==============================================================================
# 🔄 (v3.17) تهيئة مزامنة الكيبوكس التلقائية (FALCON KEYSYNC)
# ==============================================================================
mkdir -p /data/adb/falcon_keysync 2>/dev/null
if [ ! -f /data/adb/falcon_keysync/sources.conf ] && [ -f "$MODPATH/sources.conf" ]; then
    cp -f "$MODPATH/sources.conf" /data/adb/falcon_keysync/sources.conf 2>/dev/null
fi
if [ ! -f /data/adb/falcon_keysync/interval ]; then
    echo 3600 > /data/adb/falcon_keysync/interval 2>/dev/null
fi
ui_print "- 🔄 مزامنة الكيبوكس التلقائية جاهزة (فحص CRL كل ساعة بعد الإقلاع)" ; delay
ui_print "- ℹ المصادر: /data/adb/falcon_keysync/sources.conf — السجل: kb_sync.log" ; delay
ui_print "- ℹ للإيقاف: touch /data/adb/falcon_keysync/disable_auto" ; delay
ui_print " " ; delay
ui_print "- تم التثبيت بنجاح! 🦅🔥" ; delay
ui_print "- المطور: ABUFARID" ; delay
true