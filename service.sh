#!/system/bin/sh
MODDIR=${0%/*}

# إعداد ملف pif.json
cp $MODDIR/pif.json /data/adb/pif.json
chown root:root /data/adb/pif.json
chmod 644 /data/adb/pif.json

# إعداد مسار TrickyStore (للملف الذي ستضيفه لاحقاً)
mkdir -p /data/adb/tricky_store
if [ -f "$MODDIR/keybox.xml" ]; then
    cp $MODDIR/keybox.xml /data/adb/tricky_store/keybox.xml
    chown root:root /data/adb/tricky_store/keybox.xml
    chmod 644 /data/adb/tricky_store/keybox.xml
fi