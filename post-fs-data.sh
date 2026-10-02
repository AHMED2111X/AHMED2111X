#!/system/bin/sh
# FALCON KERNEL FIX - INTEGRATED POST-FS-DATA SCRIPT

MODPATH="${0%/*}"

# --- Early SELinux Policy & Context Initialization ---
if [ -f "$MODPATH/sepolicy.rule" ]; then
    magisk policy --live --file "$MODPATH/sepolicy.rule" 2>/dev/null || true
fi

chcon u:object_r:system_file:s0 "$MODPATH/post-fs-data.sh" 2>/dev/null || true
chmod 755 "$MODPATH/post-fs-data.sh" 2>/dev/null || true

# Load common functions if available
if [ -f "$MODPATH/common_func.sh" ]; then
    . "$MODPATH/common_func.sh"
fi

# Fallback helper functions if missing
if ! command -v resetprop_if_diff >/dev/null 2>&1; then
    resetprop_if_diff() {
        local PROP="$1"
        local EXPECTED="$2"
        local CURRENT=$(getprop "$PROP")
        if [ -n "$CURRENT" ] && [ "$CURRENT" != "$EXPECTED" ]; then
            resetprop -n "$PROP" "$EXPECTED"
        fi
    }
fi

if ! command -v delprop_if_exist >/dev/null 2>&1; then
    delprop_if_exist() {
        local NAME="$1"
        [ -n "$(getprop "$NAME")" ] && resetprop --delete "$NAME" 2>/dev/null
    }
fi

# --- 1. Magisk DenyList, Zygisk & Shamiko Compatibility ---
if [ -d "$MODPATH/zygisk" ]; then
    # Zygisk mode: remove Play Services and Store from DenyList so Zygisk can inject
    if magisk --denylist status >/dev/null 2>&1; then
        magisk --denylist rm com.google.android.gms >/dev/null 2>&1
        magisk --denylist rm com.android.vending >/dev/null 2>&1
    fi
    [ -f "$MODPATH/common_setup.sh" ] && . "$MODPATH/common_setup.sh"
else
    # Scripts-only mode / Shamiko fallback
    if magisk --denylist status >/dev/null 2>&1; then
        magisk --denylist add com.google.android.gms com.google.android.gms.unstable >/dev/null 2>&1
        magisk --denylist add com.android.vending com.android.vending >/dev/null 2>&1
    elif [ -d "/data/adb/modules/zygisk_shamiko" ] && [ ! -f "/data/adb/shamiko/whitelist" ]; then
        magisk --denylist add com.google.android.gms com.google.android.gms >/dev/null 2>&1
        magisk --denylist add com.google.android.gms com.google.android.gms.unstable >/dev/null 2>&1
        magisk --denylist add com.android.vending com.android.vending >/dev/null 2>&1
    fi
fi

# --- 2. Early Sensitive Properties & OEM Spoofing ---

# Samsung Warranty Bit Fixes
resetprop_if_diff ro.boot.warranty_bit 0
resetprop_if_diff ro.vendor.boot.warranty_bit 0
resetprop_if_diff ro.vendor.warranty_bit 0
resetprop_if_diff ro.warranty_bit 0

# Realme Boot State Fix
resetprop_if_diff ro.boot.realmebootstate green

# OnePlus Orange State Warning Fix
resetprop_if_diff ro.is_ever_orange 0

# Cleanup Play Integrity Pihooks
resetprop --delete persist.sys.pihooks.first_api_level 2>/dev/null

# Set System Build Tags to release-keys
for PROP in $(resetprop | grep -oE 'ro.*.build.tags'); do
    resetprop_if_diff "$PROP" release-keys
done

# Set System Build Types to user and disable debugging
for PROP in $(resetprop | grep -oE 'ro.*.build.type'); do
    resetprop_if_diff "$PROP" user
done

resetprop_if_diff ro.adb.secure 1
resetprop_if_diff ro.debuggable 0
resetprop_if_diff ro.force.debuggable 0
resetprop_if_diff ro.secure 1
resetprop_if_diff ro.boot.veritymode.managed yes

# Delete verification error flags if allowed
if [ "$SKIPDELPROP" != "true" ]; then
    delprop_if_exist ro.boot.verifiedbooterror
    delprop_if_exist ro.boot.verifyerrorpart
fi

# Custom ROM Conflicts Fixes (AOSPA, PixelPropsUtils, LeafOS)
if [ -n "$(getprop ro.aospa.version)" ]; then
    for PROP in persist.sys.pihooks.first_api_level persist.sys.pihooks.security_patch; do
        resetprop | grep -q "\[$PROP\]" || resetprop -n -p "$PROP" ""
    done
fi

if [ -n "$(getprop persist.sys.pixelprops.pi)" ]; then
    resetprop -n -p persist.sys.pixelprops.pi false
    resetprop -n -p persist.sys.pixelprops.gapps false
    resetprop -n -p persist.sys.pixelprops.gms false
fi

if [ -f /data/system/gms_certified_props.json ] && [ "$(getprop persist.sys.spoof.gms)" != "false" ]; then
    resetprop persist.sys.spoof.gms false
fi

# --- 3. Keybox Directory Setup (Tricky Store Integration) ---
KEYBOX_URL="https://github.com/AHMED2111X/AHMED2111X/raw/main/keybox.xml"
TARGET_DIR="/data/adb/tricky_store"
TARGET_FILE="$TARGET_DIR/keybox.xml"
LOG_TAG="FALCON_FIX"

if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
    chmod 755 "$TARGET_DIR"
    chown root:root "$TARGET_DIR"
fi

# --- 4. Background Keybox Online Updater ---
(
    while [ "$(getprop sys.boot_completed)" != "1" ]; do 
        sleep 5
    done

    sleep 15

    DOWNLOAD_SUCCESS=0
    
    if command -v curl >/dev/null 2>&1; then
        curl -s -L --connect-timeout 10 --max-time 30 -o "$TARGET_FILE.tmp" "$KEYBOX_URL"
        [ $? -eq 0 ] && DOWNLOAD_SUCCESS=1
    elif command -v wget >/dev/null 2>&1; then
        wget -q --timeout=15 -O "$TARGET_FILE.tmp" "$KEYBOX_URL"
        [ $? -eq 0 ] && DOWNLOAD_SUCCESS=1
    fi

    if [ "$DOWNLOAD_SUCCESS" -eq 1 ] && [ -f "$TARGET_FILE.tmp" ] && [ $(stat -c%s "$TARGET_FILE.tmp") -gt 100 ]; then
        mv "$TARGET_FILE.tmp" "$TARGET_FILE"
        chmod 644 "$TARGET_FILE"
        chown root:root "$TARGET_FILE"
        chcon u:object_r:system_file:s0 "$TARGET_FILE" 2>/dev/null
        log -t "$LOG_TAG" "Keybox updated successfully and SELinux context applied."
    else
        rm -f "$TARGET_FILE.tmp"
        log -t "$LOG_TAG" "Keybox update failed or file invalid."
    fi
) &