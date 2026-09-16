#!/system/bin/sh
# FALCON KERNEL FIX - KEYBOX UPDATER (Tricky Store Integration)

KEYBOX_URL="https://github.com/AHMED2111X/AHMED2111X/raw/main/keybox.xml"
TARGET_DIR="/data/adb/tricky_store"
TARGET_FILE="$TARGET_DIR/keybox.xml"
LOG_TAG="FALCON_FIX"

# 1. Ensure Tricky Store path exists with proper permissions
if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
    chmod 755 "$TARGET_DIR"
    chown root:root "$TARGET_DIR"
fi

(
    # 2. Wait for system boot completion
    while [ "$(getprop sys.boot_completed)" != "1" ]; do 
        sleep 5
    done

    # Additional delay to ensure network and DNS stability
    sleep 15

    # 3. Attempt download with timeout
    DOWNLOAD_SUCCESS=0
    
    if command -v curl >/dev/null 2>&1; then
        curl -s -L --connect-timeout 10 --max-time 30 -o "$TARGET_FILE.tmp" "$KEYBOX_URL"
        [ $? -eq 0 ] && DOWNLOAD_SUCCESS=1
    elif command -v wget >/dev/null 2>&1; then
        wget -q --timeout=15 -O "$TARGET_FILE.tmp" "$KEYBOX_URL"
        [ $? -eq 0 ] && DOWNLOAD_SUCCESS=1
    fi

    # 4. Verify and apply downloaded keybox file
    if [ "$DOWNLOAD_SUCCESS" -eq 1 ] && [ -f "$TARGET_FILE.tmp" ] && [ $(stat -c%s "$TARGET_FILE.tmp") -gt 100 ]; then
        mv "$TARGET_FILE.tmp" "$TARGET_FILE"
        chmod 644 "$TARGET_FILE"
        chown root:root "$TARGET_FILE"
        
        # Apply SELinux context for compatibility
        chcon u:object_r:system_file:s0 "$TARGET_FILE" 2>/dev/null
        
        log -t "$LOG_TAG" "Keybox updated successfully and SELinux context applied."
    else
        rm -f "$TARGET_FILE.tmp"
        log -t "$LOG_TAG" "Keybox update failed or file invalid."
    fi
) &