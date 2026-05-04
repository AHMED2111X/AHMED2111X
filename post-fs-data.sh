#!/system/bin/sh
# المحدث التلقائي لملف الكيبوكس من GitHub[cite: 4]

KEYBOX_URL="https://github.com/AHMED2111X/AHMED2111X/raw/main/keybox.xml"[cite: 4]
TARGET_DIR="/data/adb/tricky_store"[cite: 2]
TARGET_FILE="$TARGET_DIR/keybox.xml"[cite: 4]

if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"[cite: 4]
    chmod 755 "$TARGET_DIR"[cite: 4]
fi

(
    while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 5; done[cite: 4]
    sleep 10[cite: 4]

    if command -v curl >/dev/null 2>&1; then
        curl -L -s -o "$TARGET_FILE.tmp" "$KEYBOX_URL"[cite: 4]
    else
        wget -q "$KEYBOX_URL" -O "$TARGET_FILE.tmp"[cite: 4]
    fi

    if [ -f "$TARGET_FILE.tmp" ] && [ $(stat -c%s "$TARGET_FILE.tmp") -gt 100 ]; then
        mv "$TARGET_FILE.tmp" "$TARGET_FILE"[cite: 4]
        chmod 644 "$TARGET_FILE"[cite: 4]
        chown root:root "$TARGET_FILE"[cite: 4]
        log -t FALCON_FIX "Keybox updated successfully."[cite: 4]
    else
        rm -f "$TARGET_FILE.tmp"[cite: 4]
    fi
) &[cite: 4]