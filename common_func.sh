#!/system/bin/sh

# ==============================================================================
# إصلاح فحص الحماية FALCON INTEGRITY FIX - مكتبة الدوال والوظائف المشتركة
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
# ==============================================================================

# التحقق من وجود خيار تخطي حذف الخصائص
SKIPDELPROP=false
[ -f "$MODPATH/skipdelprop" ] && SKIPDELPROP=true

# تحديد أمر التعديل المناسب بناءً على إصدار Magisk
RESETPROP="resetprop -n"
if [ -f /data/adb/magisk/util_functions.sh ]; then
    if [ "$(grep MAGISK_VER_CODE /data/adb/magisk/util_functions.sh | cut -d= -f2)" -lt 27003 ]; then
        RESETPROP=resetprop_hexpatch
    fi
fi

# دالة حذف الخاصية إذا كانت موجودة في النظام
delprop_if_exist() {
    local NAME="$1"
    [ -n "$(resetprop "$NAME")" ] && resetprop --delete "$NAME"
}

# دالة تعيين الخصائص الدائمة وتوثيق أمر إلغائها في ملف uninstall.sh
persistprop() {
    local NAME="$1"
    local NEWVALUE="$2"
    local CURVALUE="$(resetprop "$NAME")"

    if ! grep -q "$NAME" "$MODPATH/uninstall.sh" 2>/dev/null; then
        if [ "$CURVALUE" ]; then
            [ "$NEWVALUE" = "$CURVALUE" ] || echo "resetprop -n -p \"$NAME\" \"$CURVALUE\"" >> "$MODPATH/uninstall.sh"
        else
            echo "resetprop -p --delete \"$NAME\"" >> "$MODPATH/uninstall.sh"
        fi
    fi
    resetprop -n -p "$NAME" "$NEWVALUE"
}

# دالة التعديل والترقيع المباشر عبر البايتات الست عشرية لخصائص ذاكرة النظام
resetprop_hexpatch() {
    case "$1" in
        -f|--force) local FORCE=1; shift;;
    esac 

    local NAME="$1"
    local NEWVALUE="$2"
    local CURVALUE="$(resetprop "$NAME")"

    [ ! "$NEWVALUE" -o ! "$CURVALUE" ] && return 1
    [ "$NEWVALUE" = "$CURVALUE" -a ! "$FORCE" ] && return 2

    local NEWLEN=${#NEWVALUE}
    if [ -f /dev/__properties__ ]; then
        local PROPFILE=/dev/__properties__
    else
        local PROPFILE="/dev/__properties__/$(resetprop -Z "$NAME")"
    fi
    [ ! -f "$PROPFILE" ] && return 3
    local NAMEOFFSET=$(echo $(strings -t d "$PROPFILE" | grep "$NAME") | cut -d ' ' -f 1)

    # هيكلية الترقيع: <عدد التغييرات ست عشري><بايت الأعلام><طول الخاصية ست عشري><قيمة الخاصية مع حشو الأصفار إلى 92 بايت><اسم الخاصية>
    local NEWHEX="$(printf '%02x' "$NEWLEN")$(printf "$NEWVALUE" | od -A n -t x1 -v | tr -d ' \n')$(printf "%$((92-NEWLEN))s" | sed 's/ /00/g')"

    printf "ترقيع '$NAME' إلى '$NEWVALUE' في الملف '$PROPFILE' عند العنوان @ 0x%08x -> \n[0000??$NEWHEX]\n" $((NAMEOFFSET-96))

    echo -ne "\x00\x00" \
        | dd obs=1 count=2 seek=$((NAMEOFFSET-96)) conv=notrunc of="$PROPFILE"
    echo -ne "$(printf "$NEWHEX" | sed -e 's/.\{2\}/&\\x/g' -e 's/^/\\x/' -e 's/\\x$//')" \
        | dd obs=1 count=93 seek=$((NAMEOFFSET-93)) conv=notrunc of="$PROPFILE"
}

# دالة التعديل الشرطي: تعديل الخاصية فقط إذا كانت قيمتها تختلف عن المتوقع
resetprop_if_diff() {
    local NAME="$1"
    local EXPECTED="$2"
    local CURRENT="$(resetprop "$NAME")"

    [ -z "$CURRENT" ] || [ "$CURRENT" = "$EXPECTED" ] || $RESETPROP "$NAME" "$EXPECTED"
}

# دالة التعديل الشرطي عند تطابق النص
resetprop_if_match() {
    local NAME="$1"
    local CONTAINS="$2"
    local VALUE="$3"

    [[ "$(resetprop "$NAME")" = *"$CONTAINS"* ]] && $RESETPROP "$NAME" "$VALUE"
}

# دالة وهمية لمنع حدوث أخطاء الطباعة أثناء مرحلة الإقلاع المبكرة
ui_print() { return; }