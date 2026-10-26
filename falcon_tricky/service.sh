#!/system/bin/sh

# ==============================================================================
# FALCON TRICKY - ملحق وحدة مرئية في مدير الروت
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
#
# ⚠️ هذا الملحق لا يحمل نسخة ثانية من محرك Tricky Store:
#    المحرك مملوك للإضافة الأم (playintegrityfix) ويُشغَّل منها فقط.
#    تشغيل المحرك مرتين يحقن keystore2 مرتين ويجمّد الجهاز بالكامل،
#    لذلك هذا الملحق لا يشغّل المحرك أبداً.
#
# غرضه:
#    1) الظهور في قائمة مدير الروت باسم FALCON TRICKY.
#    2) ضمان الرابط المزدوج الصارم: حذف أحدهما يحذف الآخر إجبارياً.
#    3) (v3.22.9) تحديث وصف الوحدة دورياً: ⚙️ المحرك + حماية Google X/3
#       + 🔑 حالة الكيبوكس — نفس بيانات FALCON TRICKY WebUI (بلا 👤 Online).
# ==============================================================================

MODDIR="${0%/*}"
MAIN_ID="playintegrityfix"
MAIN_FOUND=0

# 1) نراقب الإضافة الأم في المسارين (modules + modules_update):
#    إن وُجدت معلَّمة للحذف (remove) → نعلّم أنفسنا للحذف فوراً.
for B in /data/adb/modules /data/adb/modules_update; do
    if [ -d "$B/$MAIN_ID" ]; then
        MAIN_FOUND=1
        if [ -f "$B/$MAIN_ID/remove" ]; then
            touch "$MODDIR/remove" 2>/dev/null
            exit 0
        fi
    fi
done

# 2) إذا اختفت الإضافة الأم تماماً → نزيل أنفسنا حتى لا يبقى ملحق يتيم.
#    (لا يُستخدم الملحق أبداً بدون الإضافة الأم)
if [ "$MAIN_FOUND" = "0" ]; then
    touch "$MODDIR/remove" 2>/dev/null
    exit 0
fi

# 3) (v3.22.9) تحديث وصف FALCON TRICKY في مدير الروت — نفس بيانات الواجهة:
#    ⚙️ حالة المحرك | حماية Google X/3 | 🔑 حالة الكيبوكس (بلا 👤 Online)
TARGET_TXT="/data/adb/tricky_store/target.txt"
PROP="$MODDIR/module.prop"
while true; do
    if pidof TrickyStoreOSS >/dev/null 2>&1; then
        ENGINE_TAG="⚙️ Engine: Running"
    else
        ENGINE_TAG="⚙️ Engine: Stopped"
    fi

    GOOGLE_PROT=0
    for _pkg in com.google.android.gms com.google.android.gms.unstable com.android.vending; do
        grep -qx "$_pkg" "$TARGET_TXT" 2>/dev/null && GOOGLE_PROT=$((GOOGLE_PROT + 1))
    done

    KB_TAG=""
    if [ -s /data/adb/falcon_keysync/kb_state ]; then
        KB_ST=$(head -n 1 /data/adb/falcon_keysync/kb_state 2>/dev/null | tr -d ' \t\r\n')
        case "$KB_ST" in
            OK*) KB_TAG="🔑 KB OK" ;;
            REVOKED*) KB_TAG="🔑 KB REVOKED" ;;
        esac
    fi
    if [ -z "$KB_TAG" ]; then
        if [ -s /data/adb/tricky_store/keybox.xml ] && grep -q "<AndroidAttestation" /data/adb/tricky_store/keybox.xml 2>/dev/null; then
            KB_TAG="🔑 KB Attached"
        else
            KB_TAG="🔑 KB Missing"
        fi
    fi

    NEW_DESC="$ENGINE_TAG | Google: $GOOGLE_PROT/3 | $KB_TAG"

    if [ -f "$PROP" ]; then
        CUR=$(grep '^description=' "$PROP" 2>/dev/null | head -n 1)
        if [ "$CUR" != "description=$NEW_DESC" ]; then
            sed -i "s@^description=.*@description=$NEW_DESC@" "$PROP" 2>/dev/null
        fi
    fi

    sleep 4
done

exit 0
