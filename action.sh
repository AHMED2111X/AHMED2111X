#!/system/bin/sh
MODDIR=${0%/*}

# قائمة ببصمات أجهزة Pixel المتنوعة
PIXEL_LIST=(
    "google/redfin/redfin:14/UP1A.231105.001.B2/11057700:user/release-keys|Pixel 5|redfin|google|redfin"
    "google/bluejay/bluejay:14/UQ1A.240205.002/11224168:user/release-keys|Pixel 6a|bluejay|google|bluejay"
    "google/cheetah/cheetah:14/UQ1A.240205.002/11224168:user/release-keys|Pixel 7 Pro|cheetah|google|cheetah"
    "google/husky/husky:14/UQ1A.240205.002/11224168:user/release-keys|Pixel 8 Pro|husky|google|husky"
    "google/tokay/tokay:15/AP3A.240905.015/12271899:user/release-keys|Pixel 9|tokay|google|tokay"
)

# اختيار بصمة عشوائية عند الضغط
RANDOM_INDEX=$((RANDOM % ${#PIXEL_LIST[@]}))
SELECTED="${PIXEL_LIST[$RANDOM_INDEX]}"

IFS='|' read -r FINGERPRINT MODEL DEVICE BRAND PRODUCT <<< "$SELECTED"

echo "[*] جاري التبديل إلى بصمة عشوائية جديدة: $MODEL"

# 1. تغيير قيم النظام للبصمة والموديل عبر resetprop
resetprop ro.build.fingerprint "$FINGERPRINT"
resetprop ro.product.model "$MODEL"
resetprop ro.product.brand "$BRAND"
resetprop ro.product.name "$PRODUCT"
resetprop ro.product.device "$DEVICE"

resetprop ro.product.system.model "$MODEL"
resetprop ro.product.system.brand "$BRAND"
resetprop ro.product.system.name "$PRODUCT"
resetprop ro.product.system.device "$DEVICE"

# 2. تزييف قفل البوتلودر لإعادة اعتماد Google Play
resetprop ro.boot.flash.locked 1
resetprop ro.boot.verifiedbootstate green
resetprop ro.boot.veritymode enforcing
resetprop ro.boot.warranty_bit 0
resetprop ro.warranty_bit 0
resetprop ro.debuggable 0
resetprop ro.secure 1

# 3. حفظ البصمة المختارة ليتم قراءتها بعد إعادة التشغيل
echo "$FINGERPRINT" > "$MODDIR/current_fingerprint"
echo "$MODEL" > "$MODDIR/current_model"

# 4. إجبار Google Play و GMS على قراءة البصمة الجديدة
am force-stop com.android.vending
am force-stop com.google.android.gms
pm clear com.android.vending >/dev/null 2>&1

echo "[✓] تم تغيير الموديل إلى ($MODEL) وإعادة إظهار البوتلودر كمغلق بنجاح!"