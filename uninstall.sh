#!/system/bin/sh

# Clean up LeafOS GMS spoofing properties if exists
if [ -f /data/system/gms_certified_props.json ]; then
    resetprop -p --delete persist.sys.spoof.gms
fi

# Clean up temporary integrity fix logs
rm -f /data/adb/modules/integrity_fix/integrity_fix.log