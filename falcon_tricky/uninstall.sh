#!/system/bin/sh

# ==============================================================================
# FALCON TRICKY - الرابط المزدوج (الاتجاه الثاني)
# (v3.15) حذف هذا الملحق من مدير الروت يحذف الإضافة الأم FALCON INTEGRITY FIX
#          فوراً ونهائياً مع كل تنظيفاتها — لا انتظار إعادة تشغيل.
#
# التسلسل:
#   1) تشغيل سكربت تنظيف الإضافة الأم كاملاً (resetprop + إيقاف المحرك + السجلات)
#      مع علم FALCON_FROM_COMPANION=1 حتى لا يحذف الأم مجلدَنا ونحن نعمل داخله
#   2) حذف مجلد الإضافة الأم حذفاً حقيقياً من المسارين
#   3) تنظيف بيانات الملحق (أرشيف أيقونات التطبيقات)
#
# ⚠️ لا يوجد استدعاء متبادل (recursion): سكربت الإضافة الأم لا يستدعي هذا
#    السكربت بل يحذف المجلد فقط، لذلك ينتهي التنظيف بلا حلقة لا نهائية.
# ⛔ لا نحذف /data/adb/tricky_store (كيبوكس المستخدم + target.txt).
# ==============================================================================

MAIN_ID="playintegrityfix"

# 1) تنظيف الإضافة الأم من داخل نفسها (قبل حذفها) — محصّن ضد أي فشل
for B in /data/adb/modules /data/adb/modules_update; do
    if [ -d "$B/$MAIN_ID" ] && [ -f "$B/$MAIN_ID/uninstall.sh" ]; then
        FALCON_FROM_COMPANION=1 sh "$B/$MAIN_ID/uninstall.sh" >/dev/null 2>&1 || true
    fi
done

# 2) حذف فوري حقيقي لمجلد الإضافة الأم من المسارين
for B in /data/adb/modules /data/adb/modules_update; do
    [ -d "$B/$MAIN_ID" ] || continue
    touch "$B/$MAIN_ID/remove" 2>/dev/null
    rm -rf "$B/$MAIN_ID" 2>/dev/null
done

# 3) بيانات الملحق (أرشيف الأيقونات المستخرجة من تطبيقات الجهاز)
rm -rf /data/adb/falcon_icons 2>/dev/null

exit 0
