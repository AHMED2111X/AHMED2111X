#!/system/bin/sh
# 🦅 FALCON KERNEL FIX - Auto Keybox Updater
# المطور: ABUFARID 

# 1. إعداد المسارات والروابط
KEYBOX_URL="https://github.com/AHMED2111X/AHMED2111X/raw/main/keybox.xml"
TARGET_DIR="/data/adb/trickystore"
TARGET_FILE="$TARGET_DIR/keybox.xml"

# 2. إنشاء المجلد إذا لم يكن موجوداً
if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
    chmod 755 "$TARGET_DIR"
fi

# 3. وظيفة التحديث في الخلفية (Background Process)
(
    # الانتظار حتى استقرار النظام والإنترنت
    while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 5; done
    sleep 10

    # محاولة التحميل باستخدام curl أو wget
    if command -v curl >/dev/null 2>&1; then
        curl -L -s -o "$TARGET_FILE.tmp" "$KEYBOX_URL"
    else
        wget -q "$KEYBOX_URL" -O "$TARGET_FILE.tmp"
    fi

    # التأكد من نجاح التحميل قبل استبدال الملف القديم
    if [ -f "$TARGET_FILE.tmp" ] && [ s $(stat -c%s "$TARGET_FILE.tmp") -gt 100 ]; then
        mv "$TARGET_FILE.tmp" "$TARGET_FILE"
        chmod 644 "$TARGET_FILE"
        chown root:root "$TARGET_FILE"
        
        # اختيار اختياري: إرسال إشعار للنظام (Log)
        log -t FALCON_FIX "Keybox updated successfully from GitHub."
    else
        rm -f "$TARGET_FILE.tmp"
        log -t FALCON_FIX "Keybox update failed (No Internet or URL error)."
    fi
) &