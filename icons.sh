#!/system/bin/sh
# ==============================================================================
# FALCON INTEGRITY FIX — استخراج أيقونات التطبيقات المخفية
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
#
# الغرض:
#   تُنشئ /data/adb/falcon_icons/<package>.png لكل تطبيق مخفي، بحيث تعرضه
#   واجهة FALCON TRICKY كصورة حقيقية بدل الحرف الأول — ليستطيع المستخدم
#   التعرف على التطبيق من شكله لا من اسم الحزمة.
#
# طريقة العمل:
#   1) pm path <الحزمة>  ← مسار ملف APK
#   2) نبحث داخل الـ APK عن مورد أيقونة المشغّل (ic_launcher)
#   3) نفضّل أعلى دقة متاحة، ونفضّل PNG على WEBP
#   4) نستخرجها إلى مجلد الأيقونات
#
# الاستخدام:
#   sh icons.sh                  ← لكل التطبيقات الموجودة في target.txt
#   sh icons.sh pkg1 pkg2 ...    ← لحزم محددة
# ==============================================================================

ICON_DIR="/data/adb/falcon_icons"
TARGET_FILE="/data/adb/tricky_store/target.txt"

mkdir -p "$ICON_DIR" 2>/dev/null

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

# وضع الحزم المحددة
if [ "$#" -gt 0 ]; then
    for _p in "$@"; do
        extract_one "$_p"
    done
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

echo "ICONS_DONE"
