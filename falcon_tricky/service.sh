#!/system/bin/sh

# ==============================================================================
# FALCON TRICKY - ملحق وحدة مرئية في مدير الروت
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
#
# ⚠️ هذا الملحق لا يحمل نسخة ثانية من محرك Tricky Store:
#    المحرك مملوك للإضافة الأم (playintegrityfix) ويُشغَّل منها فقط.
#    تشغيل المحرك مرتين يحقن keystore2 مرتين ويجمّد الجهاز بالكامل،
#    لذلك هذا الملحق لا يشغّل شيئاً إطلاقاً.
#
# غرضه:
#    1) الظهور في قائمة مدير الروت باسم FALCON TRICKY.
#    2) ضمان الرابط المزدوج الصارم: حذف أحدهما يحذف الآخر إجبارياً.
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

exit 0
