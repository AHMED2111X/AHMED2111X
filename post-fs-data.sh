#!/system/bin/sh
# FALCON INTEGRITY FIX - KEYBOX UPDATER
# Optimized for Pixel 10 (Android 16) & Zygisk Next 1.5.0+

KEYBOX_URL="https://github.com/AHMED2111X/AHMED2111X/raw/main/keybox.xml"
TARGET_DIR="/data/adb/tricky_store"
TARGET_FILE="$TARGET_DIR/keybox.xml"
ZYGISK_NEXT_DIR="/data/adb/zygisk_next"
LOG_TAG="FALCON_FIX"

# 1. Initialize required directory and base permissions
if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
    chmod 755 "$TARGET_DIR"
    chown root:root "$TARGET_DIR"
fi

(
    # 2. Wait for system boot completion on Android 16
    while [ "$(getprop sys.boot_completed)" != "1" ]; do 
        sleep 3
    done

    # Additional delay to ensure IPv4/IPv6 network stability on Pixel 10
    sleep 10

    # 3. Download keybox file using available CLI tools
    DOWNLOAD_SUCCESS=0
    TMP_FILE="$TARGET_FILE.tmp"
    
    if command -v curl >/dev/null 2>&1; then
        curl -s -L --connect-timeout 10 --max-time 25 -o "$TMP_FILE" "$KEYBOX_URL"
        [ $? -eq 0 ] && DOWNLOAD_SUCCESS=1
    elif command -v wget >/dev/null 2>&1; then
        wget -q --timeout=15 -O "$TMP_FILE" "$KEYBOX_URL"
        [ $? -eq 0 ] && DOWNLOAD_SUCCESS=1
    fi

    # 4. Validate XML integrity and file size
    if [ "$DOWNLOAD_SUCCESS" -eq 1 ] && [ -f "$TMP_FILE" ]; then
        FILE_SIZE=$(stat -c%s "$TMP_FILE" 2>/dev/null || echo 0)
        
        # Verify file size (>150 bytes) and valid XML header
        if [ "$FILE_SIZE" -gt 150 ] && grep -q "<?xml" "$TMP_FILE"; then
            mv "$TMP_FILE" "$TARGET_FILE"
            chmod 644 "$TARGET_FILE"
            chown root:root "$TARGET_FILE"
            
            # Apply SELinux context compatible with Android 16 on Pixel 10
            chcon u:object_r:system_file:s0 "$TARGET_FILE" 2>/dev/null || chcon u:object_r:adb_data_file:s0 "$TARGET_FILE" 2>/dev/null

            # Mirror to Zygisk Next directory if present
            if [ -d "$ZYGISK_NEXT_DIR" ]; then
                cp -f "$TARGET_FILE" "$ZYGISK_NEXT_DIR/keybox.xml" 2>/dev/null
                chmod 644 "$ZYGISK_NEXT_DIR/keybox.xml"
                chcon u:object_r:system_file:s0 "$ZYGISK_NEXT_DIR/keybox.xml" 2>/dev/null
            fi

            # Kill GMS processes to apply keybox changes immediately without rebooting
            killall com.google.android.gms 2>/dev/null
            killall com.google.android.gms.unstable 2>/dev/null

            log -t "$LOG_TAG" "Keybox updated successfully for Pixel 10 & Zygisk Next 1.5.0."
        else
            rm -f "$TMP_FILE"
            log -t "$LOG_TAG" "Keybox download failed validation (invalid XML structure or too small)."
        fi
    else
        rm -f "$TMP_FILE"
        log -t "$LOG_TAG" "Keybox download failed due to network error."
    fi
) &