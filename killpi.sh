#!/system/bin/sh

# ==============================================================================
# إصلاح فحص الحماية FALCON INTEGRITY FIX - سكربت إنهاء عمليات خدمات وجوجل بلاي
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
# ==============================================================================

# التحقق من توفر صلاحيات الروت (الجذر) لتنفيذ الأمر
if [ "$USER" != "root" ] && [ "$(whoami 2>/dev/null)" != "root" ]; then
  echo "killpi: تتطلب العملية صلاحيات الروت (Root)";
  exit 1;
fi;

# تحديد العمليات وحزم جوجل المستهدفة بالإغلاق (خدمات الفحص ومتجر بلاي)
TARGET_PACKAGES="com.google.android.gms.unstable com.android.vending"

# حلقة إنهاء وإغلاق العمليات بطرق متعددة لضمان تطبيق التمويه فوراً
for PKG in $TARGET_PACKAGES; do
    killall -v "$PKG" 2>/dev/null || pkill -f "$PKG" 2>/dev/null || am force-stop "$PKG" 2>/dev/null
done