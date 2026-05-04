#!/system/bin/sh
# FALCON KERNEL FIX - KEYBOX UPDATER

KEYBOX_URL="https://github.com/AHMED2111X/AHMED2111X/raw/main/keybox.xml"
TARGET_DIR="/data/adb/tricky_store"
TARGET_FILE="$TARGET_DIR/keybox.xml"

# التأكد من وجود المسار الأصلي فقط دون أي مجلدات مرقمة
if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
    chmod 755 "$TARGET_DIR"
fi

(
    # الانتظار حتى اكتمال إقلاع النظام لضمان استقرار الشبكة
    while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 5; done
    sleep 10

    # تحميل ملف الكيبوكس الجديد بأمان
    if command -v curl >/dev/null 2>&1; then
        curl -L -s -o "$TARGET_FILE.tmp" "$KEYBOX_URL"
    else
        wget -q "$KEYBOX_URL" -O "$TARGET_FILE.tmp"
    fi

    # التحقق من سلامة الملف المحمل قبل استبداله
    if [ -f "$TARGET_FILE.tmp" ] && [ $(stat -c%s "$TARGET_FILE.tmp") -gt 100 ]; then
        mv "$TARGET_FILE.tmp" "$TARGET_FILE"
        chmod 644 "$TARGET_FILE"
        chown root:root "$TARGET_FILE"
        log -t FALCON_FIX "Keybox updated successfully."
    else
        rm -f "$TARGET_FILE.tmp"
    fi
) &