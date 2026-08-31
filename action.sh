#!/system/bin/sh
MODDIR="${0%/*}"

echo "***************************************************"
echo "*            FALCON INTEGRITY FIX                 *"
echo "*           Pixel 10 Fingerprint Update           *"
echo "*               Author: ABUFARID                  *"
echo "***************************************************"
echo ""

PIF_JSON="$MODDIR/pif.json"
CUSTOM_PROP="$MODDIR/custom.pif.prop"

echo "[*] Applying Google Pixel 10 Fingerprint..."

# كتابة pif.json الخاصة بـ Pixel 10
cat <<EOF > "$PIF_JSON"
{
  "PRODUCT": "komodo",
  "DEVICE": "komodo",
  "MANUFACTURER": "Google",
  "BRAND": "google",
  "MODEL": "Pixel 10",
  "FINGERPRINT": "google/komodo/komodo:15/AP3A.241005.015/12500000:user/release-keys",
  "SECURITY_PATCH": "2026-08-05",
  "FIRST_API_LEVEL": "32"
}
EOF

# تحديث custom.pif.prop إذا كان موجوداً
if [ -f "$CUSTOM_PROP" ]; then
    cat <<EOF > "$CUSTOM_PROP"
MANUFACTURER=Google
MODEL=Pixel 10
FINGERPRINT=google/komodo/komodo:15/AP3A.241005.015/12500000:user/release-keys
BRAND=google
PRODUCT=komodo
DEVICE=komodo
SECURITY_PATCH=2026-08-05
FIRST_API_LEVEL=32
EOF
fi

chmod 0644 "$PIF_JSON"
[ -f "$CUSTOM_PROP" ] && chmod 0644 "$CUSTOM_PROP"

# تطبيق التعديل الفوري عبر resetprop
echo "[*] Setting system properties via resetprop..."
resetprop ro.product.model "Pixel 10"
resetprop ro.product.brand "google"
resetprop ro.product.name "komodo"
resetprop ro.product.device "komodo"
resetprop ro.build.fingerprint "google/komodo/komodo:15/AP3A.241005.015/12500000:user/release-keys"
resetprop ro.build.version.security_patch "2026-08-05"

# إرغام خدمات جوجل على إعادة التشغيل لتطبيق البصمة فوراً
echo "[*] Restarting Google Play Services..."
for proc in com.google.android.gms.unstable com.google.android.gms com.android.vending; do
    killall "$proc" 2>/dev/null
    pkill -f "$proc" 2>/dev/null
done

echo ""
echo "[✓] Successfully updated fingerprint to Pixel 10!"
echo "[✓] Action completed successfully."
exit 0