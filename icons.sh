#!/system/bin/sh
# ==============================================================================
# FALCON INTEGRITY FIX — استخراج أيقونات التطبيقات المخفية
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
#
# الغرض:
#   تُنشئ أيقونة PNG لكل تطبيق مخفي، بحيث تعرضها واجهة FALCON TRICKY كصورة
#   حقيقية بدل الحرف الأول — ليستطيع المستخدم التعرف على التطبيق من شكله.
#
# أين تُكتب الأيقونات؟
#   1) webroot الوحدة المرافقة  ← تقرأها الواجهة مباشرة عبر HTTP (بلا جسر وبلا تعليق)
#      /data/adb/modules/falcon_tricky/webroot/icons/
#   2) نسخة أرشيفية في /data/adb/falcon_icons
#
# طريقة العمل:
#   1) pm path <الحزمة>  ← مسار ملف APK
#   2) نبحث داخل الـ APK عن مورد أيقونة المشغّل (ic_launcher)
#   3) نفضّل أعلى دقة متاحة، ونفضّل PNG على WEBP
#   4) نستخرجها إلى مجلد الأيقونات ثم نحدّث ملف الفهرس
#
# الاستخدام:
#   sh icons.sh                  ← لكل التطبيقات الموجودة في target.txt
#   sh icons.sh pkg1 pkg2 ...    ← لحزم محددة
#
# (v3.14) الفهرس _index.txt يجعل الواجهة تعرف أي أيقونة موجودة فعلاً
#         فلا تطلب صوراً غير موجودة ولا تحتاج أي استدعاء للجسر.
# ==============================================================================

ICON_DIR="/data/adb/falcon_icons"
ICON_WEB="/data/adb/modules/falcon_tricky/webroot/icons"
TARGET_FILE="/data/adb/tricky_store/target.txt"

mkdir -p "$ICON_DIR" 2>/dev/null
if [ -d "/data/adb/modules/falcon_tricky/webroot" ]; then
    mkdir -p "$ICON_WEB" 2>/dev/null
else
    ICON_WEB=""
fi

extract_one() {
    _pkg="$1"
    [ -n "$_pkg" ] || return 0
    _out="$ICON_DIR/$_pkg.png"
    [ -s "$_out" ] && return 0

    _apk=$(pm path "$_pkg" 2>/dev/null | head -1 | sed 's/package://' | tr -d '\r')
    [ -n "$_apk" ] || return 1
    [ -f "$_apk" ] || return 1

    # نختار أفضل أيقونة مشغّل متاحة (أعلى دقة، ونفضّل PNG)
    _icon=$(unzip -l "$_apk" 2>/dev/null \
        | grep -oE 'res/[A-Za-z0-9_]+/ic_launcher[A-Za-z0-9_]*\.(png|webp)' \
        | awk '{
            p = $NF
            s = (p ~ /xxxhdpi/ ? 6 : p ~ /xxhdpi/ ? 5 : p ~ /xhdpi/ ? 4 : p ~ /hdpi/ ? 3 : p ~ /mdpi/ ? 2 : p ~ /ldpi/ ? 1 : 0)
            s += (p ~ /[.]png$/ ? 10 : 5)
            s += (p ~ /foreground/ ? 3 : 0)
            print s "\t" p
        }' \
        | sort -rn | head -1 | cut -f2-)

    [ -n "$_icon" ] || return 1

    unzip -p "$_apk" "$_icon" > "$_out" 2>/dev/null
    if [ -s "$_out" ]; then
        chmod 644 "$_out" 2>/dev/null
        return 0
    fi

    rm -f "$_out" 2>/dev/null
    return 1
}

# نسخ الأيقونات إلى webroot الوحدة المرافقة + كتابة الفهرس للواجهة
publish_icons() {
    [ -n "$ICON_WEB" ] || return 0
    for _f in "$ICON_DIR"/*.png; do
        [ -s "$_f" ] || continue
        _b=$(basename "$_f")
        [ -s "$ICON_WEB/$_b" ] && continue
        cp -f "$_f" "$ICON_WEB/$_b" 2>/dev/null
    done
    # الفهرس: أسماء الحزم التي لها أيقونة فعلية (من ملفات .png فقط)
    {
        echo "# falcon-icons-index"
        for _g in "$ICON_WEB"/*.png; do
            [ -s "$_g" ] || continue
            basename "$_g" .png
        done
    } > "$ICON_WEB/.idx.tmp" 2>/dev/null
    mv -f "$ICON_WEB/.idx.tmp" "$ICON_WEB/_index.txt" 2>/dev/null || cp -f "$ICON_WEB/.idx.tmp" "$ICON_WEB/_index.txt" 2>/dev/null
    chmod 644 "$ICON_WEB/_index.txt" 2>/dev/null
    chmod 755 "$ICON_WEB" 2>/dev/null
}

# وضع الحزم المحددة
if [ "$#" -gt 0 ]; then
    for _p in "$@"; do
        extract_one "$_p"
    done
    publish_icons
    echo "ICONS_DONE"
    exit 0
fi

# الوضع الكامل: كل التطبيقات الموجودة في target.txt
if [ -f "$TARGET_FILE" ]; then
    while read -r _line; do
        case "$_line" in
            ''|'#'*) continue ;;
        esac
        _line="${_line%!}"
        extract_one "$_line"
    done < "$TARGET_FILE"
fi

publish_icons
echo "ICONS_DONE"
