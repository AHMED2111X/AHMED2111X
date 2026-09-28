#!/system/bin/sh
# ==============================================================================
# FALCON INTEGRITY FIX - COMMON FUNCTIONS LIBRARY
# Developer: ABUFARID | Telegram: @FALCON_KERNEL
# ==============================================================================

SKIPDELPROP=false
[ -f "$MODPATH/skipdelprop" ] && SKIPDELPROP=true[cite: 9]

RESETPROP="resetprop -n"[cite: 9, 10]
if [ -f /data/adb/magisk/util_functions.sh ]; then[cite: 9, 10]
    if [ "$(grep MAGISK_VER_CODE /data/adb/magisk/util_functions.sh | cut -d= -f2)" -lt 27003 ]; then[cite: 9, 10]
        RESETPROP=resetprop_hexpatch[cite: 9, 10]
    fi
fi

# delprop_if_exist <prop name>
delprop_if_exist() {
    local NAME="$1"[cite: 9]
    [ -n "$(resetprop "$NAME")" ] && resetprop --delete "$NAME"[cite: 9]
}

# persistprop <prop name> <new value>
persistprop() {
    local NAME="$1"[cite: 9]
    local NEWVALUE="$2"[cite: 9]
    local CURVALUE="$(resetprop "$NAME")"[cite: 9]

    if ! grep -q "$NAME" "$MODPATH/uninstall.sh" 2>/dev/null; then[cite: 9]
        if [ "$CURVALUE" ]; then[cite: 9]
            [ "$NEWVALUE" = "$CURVALUE" ] || echo "resetprop -n -p \"$NAME\" \"$CURVALUE\"" >> "$MODPATH/uninstall.sh"[cite: 9]
        else
            echo "resetprop -p --delete \"$NAME\"" >> "$MODPATH/uninstall.sh"[cite: 9]
        fi
    fi
    resetprop -n -p "$NAME" "$NEWVALUE"[cite: 9]
}

# resetprop_hexpatch [-f|--force] <prop name> <new value>
resetprop_hexpatch() {
    case "$1" in
        -f|--force) local FORCE=1; shift;;[cite: 9, 10]
    esac 

    local NAME="$1"[cite: 9, 10]
    local NEWVALUE="$2"[cite: 9, 10]
    local CURVALUE="$(resetprop "$NAME")"[cite: 9, 10]

    [ ! "$NEWVALUE" -o ! "$CURVALUE" ] && return 1[cite: 9, 10]
    [ "$NEWVALUE" = "$CURVALUE" -a ! "$FORCE" ] && return 2[cite: 9, 10]

    local NEWLEN=${#NEWVALUE}[cite: 9, 10]
    if [ -f /dev/__properties__ ]; then[cite: 9, 10]
        local PROPFILE=/dev/__properties__[cite: 9, 10]
    else
        local PROPFILE="/dev/__properties__/$(resetprop -Z "$NAME")"[cite: 9, 10]
    fi
    [ ! -f "$PROPFILE" ] && return 3[cite: 9, 10]
    local NAMEOFFSET=$(echo $(strings -t d "$PROPFILE" | grep "$NAME") | cut -d ' ' -f 1)[cite: 10]

    # <hex 2-byte change counter><flags byte><hex length of prop value><prop value + nul padding to 92 bytes><prop name>
    local NEWHEX="$(printf '%02x' "$NEWLEN")$(printf "$NEWVALUE" | od -A n -t x1 -v | tr -d ' \n')$(printf "%$((92-NEWLEN))s" | sed 's/ /00/g')"[cite: 9, 10]

    printf "Patch '$NAME' to '$NEWVALUE' in '$PROPFILE' @ 0x%08x -> \n[0000??$NEWHEX]\n" $((NAMEOFFSET-96))[cite: 9, 10]

    echo -ne "\x00\x00" \
        | dd obs=1 count=2 seek=$((NAMEOFFSET-96)) conv=notrunc of="$PROPFILE"[cite: 9, 10]
    echo -ne "$(printf "$NEWHEX" | sed -e 's/.\{2\}/&\\x/g' -e 's/^/\\x/' -e 's/\\x$//')" \
        | dd obs=1 count=93 seek=$((NAMEOFFSET-93)) conv=notrunc of="$PROPFILE"[cite: 9, 10]
}

# resetprop_if_diff <prop name> <expected value>
resetprop_if_diff() {
    local NAME="$1"[cite: 9, 10]
    local EXPECTED="$2"[cite: 9, 10]
    local CURRENT="$(resetprop "$NAME")"[cite: 9, 10]

    [ -z "$CURRENT" ] || [ "$CURRENT" = "$EXPECTED" ] || $RESETPROP "$NAME" "$EXPECTED"[cite: 9, 10]
}

# resetprop_if_match <prop name> <value match string> <new value>
resetprop_if_match() {
    local NAME="$1"[cite: 9, 10]
    local CONTAINS="$2"[cite: 9, 10]
    local VALUE="$3"[cite: 9, 10]

    [[ "$(resetprop "$NAME")" = *"$CONTAINS"* ]] && $RESETPROP "$NAME" "$VALUE"[cite: 9, 10]
}

# Stub for boot-time logging
ui_print() { return; }[cite: 9, 10]