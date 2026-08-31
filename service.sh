#!/system/bin/sh
MODDIR=${0%/*}

# الانتظار حتى اكتمال إقلاع النظام
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 2
done

# ----------------------------------------------------
# 1. إخفاء البوت لودر المفتوح (Play Integrity Fix)
# ----------------------------------------------------
resetprop -n ro.boot.verifiedbootstate "green"
resetprop -n ro.boot.flash.locked "1"
resetprop -n ro.boot.veritymode "enforcing"
resetprop -n ro.boot.vbmeta.device_state "locked"
resetprop -n ro.boot.warrantybit "0"
resetprop -n ro.warranty_bit "0"
resetprop -n ro.debuggable "0"
resetprop -n ro.secure "1"

# خصائص الـ Vendor
resetprop -n vendor.boot.verifiedbootstate "green"
resetprop -n vendor.boot.flash.locked "1"

# ----------------------------------------------------
# 2. إعدادات وتوافقية SUSFS (KernelSU)
# ----------------------------------------------------
if [ -d "/data/adb/susfs4ksu" ] || [ -f "/data/adb/ksu/bin/susfs" ] || [ -d "/data/adb/sufs" ]; then
    resetprop -n ksu.susfs.enabled "1"
    
    if [ -f "/data/adb/susfs4ksu/sus_path.txt" ]; then
        chmod 0644 /data/adb/susfs4ksu/sus_path.txt
    fi
fi

# ----------------------------------------------------
# 3. دعم Zygisk Next 1.5.0 و Keybox
# ----------------------------------------------------
if [ -d "/data/adb/modules/zygisk_next" ]; then
    resetprop -n zygisk.next.version "1.5.0"
fi

if [ -f "$MODDIR/pif.json" ]; then
    chmod 0644 $MODDIR/pif.json
    chmod 0644 $MODDIR/keybox.xml 2>/dev/null
fi