#!/system/bin/sh

# ==============================================================================
# إصلاح فحص الحماية FALCON INTEGRITY FIX - سكربت إنهاء عمليات خدمات وجوجل بلاي
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
# ==============================================================================

# التحقق من صلاحيات الروت باستخدام id -u بدقة
if [ "$(id -u 2>/dev/null)" != "0" ]; then
    echo "killpi: تتطلب العملية صلاحيات الروت (Root)"
    exit 1
fi

# تحديد العمليات وحزم جوجل المستهدفة بالإغلاق
TARGET_PACKAGES="com.google.android.gms.unstable com.android.vending"

# حلقة إنهاء العمليات مع التحقق من توفر الأوامر تفادياً لأي فشل
for PKG in $TARGET_PACKAGES; do
    if command -v killall >/dev/null 2>&1; then
        killall "$PKG" 2>/dev/null
    elif command -v pkill >/dev/null 2>&1; then
        pkill -f "$PKG" 2>/dev/null
    elif command -v am >/dev/null 2>&1; then
        am force-stop "$PKG" 2>/dev/null
    fi
done