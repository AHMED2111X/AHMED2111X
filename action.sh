#!/system/bin/sh
MODDIR=${0%/*}

# التأكد من منح صلاحيات التنفيذ
chmod 755 "$MODDIR/action.sh" 2>/dev/null

# بيانات بصمة Pixel 10
FINGERPRINT="google/frankel/frankel:15/BP1A.250305.002/12500000:user/release-keys"
MODEL="Pixel 10"
BRAND="google"
DEVICE="frankel"
PRODUCT="frankel"
MANUFACTURER="Google"

echo "[*] جاري بدء الخطوات..."
sleep 1

# 1. تزييف حالة الجهاز والموديل على كافة الأقسام
for PREFIX in "" "system." "system_ext." "vendor." "odm." "product." "bootimage."; do
    resetprop -n "ro.product.${PREFIX}model" "$MODEL"
    resetprop -n "ro.product.${PREFIX}brand" "$BRAND"
    resetprop -n "ro.product.${PREFIX}name" "$PRODUCT"
    resetprop -n "ro.product.${PREFIX}device" "$DEVICE"
    resetprop -n "ro.product.${PREFIX}manufacturer" "$MANUFACTURER"
done

resetprop -n ro.build.fingerprint "$FINGERPRINT"
resetprop -n ro.system.build.fingerprint "$FINGERPRINT"
resetprop -n ro.vendor.build.fingerprint "$FINGERPRINT"
resetprop -n ro.bootimage.build.fingerprint "$FINGERPRINT"
resetprop -n ro.odm.build.fingerprint "$FINGERPRINT"
resetprop -n ro.build.type "user"
resetprop -n ro.build.tags "release-keys"

echo "[✓] تم تزييف حالة الجهاز"
sleep 1

# 2. إخفاء وتزييف حالة البوت لودر لتخطي SafetyNet / Play Integrity
resetprop -n ro.boot.flash.locked 1
resetprop -n ro.boot.verifiedbootstate green
resetprop -n ro.boot.veritymode enforcing
resetprop -n ro.boot.vbmeta.device_state locked
resetprop -n ro.boot.warranty_bit 0
resetprop -n ro.warranty_bit 0
resetprop ro.debuggable 0
resetprop ro.secure 1
resetprop -n ro.product.first_api_level 25

echo "[✓] تم عمل إخفاء البوت لودر"
sleep 1

# 3. تزييف وتحديث حالة متجر جوجل بلاي
echo "$FINGERPRINT" > "$MODDIR/current_fingerprint" 2>/dev/null
echo "$MODEL" > "$MODDIR/current_model" 2>/dev/null

am force-stop com.google.android.gms >/dev/null 2>&1
am force-stop com.google.android.gms.unstable >/dev/null 2>&1
am force-stop com.android.vending >/dev/null 2>&1
pm clear com.android.vending >/dev/null 2>&1

echo "[✓] تم تزييف حالة جوجل بلاي"
sleep 1

echo "[★] اكتملت جميع العمليات بنجاح!"