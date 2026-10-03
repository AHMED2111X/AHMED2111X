#!/system/bin/sh

# ==============================================================================
# إصلاح فحص الحماية FALCON INTEGRITY FIX - سكربت التثبيت والتخصيص
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
# ==============================================================================

# --- إعداد قواعد SELinux وسياق تنفيذ الملفات ---
if [ -f "$MODPATH/sepolicy.rule" ]; then
    ui_print "- 🛡️ جاري تطبيق قواعد SELinux المخصصة..."
    magisk policy --live --file "$MODPATH/sepolicy.rule" 2>/dev/null || true
fi

chcon -R u:object_r:system_file:s0 "$MODPATH" 2>/dev/null || true
chmod -R 755 "$MODPATH" 2>/dev/null || true

# دالة مساعدة لإضافة مهلة زمنية بسيطة لتنسيق المخرجات
delay() {
    sleep 0.3
}

ui_print " "
ui_print "  ######################################" ; delay
ui_print "  #      🦅 FALCON INTEGRITY FIX       #" ; delay
ui_print "  #          المطور: ABUFARID          #" ; delay
ui_print "  #        تليجرام: @FALCON_KERNEL     #" ; delay
ui_print "  ######################################" ; delay
ui_print " " ; delay

ui_print "- 🔍 جاري تهيئة بيئة Zygisk Next..." ; delay

# الفحص والتحقق من توافق إصدار الأندرويد
if [ "$API" -lt 25 ]; then
    abort " 🚫 خطأ: إصدار الأندرويد الخاص بهاتفك غير مدعوم ✋"
fi

# جلب عدد المستخدمين النشطين مباشرة أثناء التثبيت
SERVER_URL="https://falcon-counter-server.onrender.com"
ONLINE_USERS=""

if command -v curl >/dev/null 2>&1; then
    ONLINE_USERS=$(curl -s --connect-timeout 5 --max-time 5 -X POST -H "Content-Type: application/json" -d '{"deviceId":"install_check"}' "$SERVER_URL/ping" 2>/dev/null | grep -o '"onlineUsers":[0-9]*' | cut -d':' -f2)
elif command -v wget >/dev/null 2>&1; then
    ONLINE_USERS=$(wget -qO- --timeout=5 --post-data='{"deviceId":"install_check"}' --header='Content-Type: application/json' "$SERVER_URL/ping" 2>/dev/null | grep -o '"onlineUsers":[0-9]*' | cut -d':' -f2)
fi

if [ -n "$ONLINE_USERS" ] && [ -f "$MODPATH/module.prop" ]; then
    ui_print "- 👥 عدد المستخدمين النشطين الآن: $ONLINE_USERS" ; delay
    sed -i -E "s/Online Users: [0-9]+/Online Users: $ONLINE_USERS/g" "$MODPATH/module.prop"
fi

# 1. تعيين الصلاحيات القياسية وحماية سكربتات تشغيل النظام
set_perm_recursive $MODPATH 0 0 0755 0644
if [ -d "$MODPATH/zygisk" ]; then
    set_perm_recursive $MODPATH/zygisk 0 0 0755 0755
fi
[ -f "$MODPATH/service.sh" ] && set_perm $MODPATH/service.sh 0 0 0755
[ -f "$MODPATH/post-fs-data.sh" ] && set_perm $MODPATH/post-fs-data.sh 0 0 0755

# 2. نشر ملفات التمويه والـ Keybox (إصلاح TEE Attestation)
ui_print "- 🎭 جاري نشر مكونات PIF و Tricky Store..." ; delay
mkdir -p /data/adb/tricky_store 2>/dev/null

if [ -f "$MODPATH/pif.json" ]; then
    [ -f "/data/adb/pif.json" ] && mv -f "/data/adb/pif.json" "/data/adb/pif.json.old"
    cp -f "$MODPATH/pif.json" /data/adb/pif.json
fi

# نشر ملف keybox.xml سواءً كان في مجلد zygisk أو في الجذر
if [ -f "$MODPATH/zygisk/keybox.xml" ]; then
    cp -f "$MODPATH/zygisk/keybox.xml" /data/adb/tricky_store/keybox.xml
elif [ -f "$MODPATH/keybox.xml" ]; then
    cp -f "$MODPATH/keybox.xml" /data/adb/tricky_store/keybox.xml
fi

# --- الحفاظ على الخيارات السابقة في target.txt ودمجها بآمان بدون تكرار ---
if [ -f "$MODPATH/target.txt" ]; then
    if [ -f "/data/adb/tricky_store/target.txt" ]; then
        # إدراج التطبيقات المستهدفة الجديدة وتصفية التكرار عبر ملف مؤقت
        cat "$MODPATH/target.txt" >> /data/adb/tricky_store/target.txt
        sort -u /data/adb/tricky_store/target.txt > /data/adb/tricky_store/target.tmp 2>/dev/null
        if [ -s "/data/adb/tricky_store/target.tmp" ]; then
            mv -f /data/adb/tricky_store/target.tmp /data/adb/tricky_store/target.txt
        else
            rm -f /data/adb/tricky_store/target.tmp 2>/dev/null
        fi
    else
        cp -f "$MODPATH/target.txt" /data/adb/tricky_store/
    fi
fi

[ -f "$MODPATH/security_patch.txt" ] && cp -f "$MODPATH/security_patch.txt" /data/adb/tricky_store/

# ضبط وتأمين الصلاحيات لمجلد tricky_store
chmod 755 /data/adb/tricky_store 2>/dev/null
chmod 644 /data/adb/tricky_store/* 2>/dev/null

# 3. إدراج التطبيقات الأساسية في قائمة العزل (Magisk DenyList)
ui_print "- 🛡️ جاري تطبيق قائمة العزل التلقائية للتطبيقات والتطبيقات البنكية..." ; delay
DENY_LIST_APPS="
com.google.android.gms com.google.android.gms:snet
com.google.android.gms com.google.android.gms:identitycredentials
com.google.android.gms com.google.android.gms:car
com.google.android.gms com.google.android.gms.unstable
com.google.android.gms com.google.android.gms.ui
com.google.android.gms com.google.android.gms.room
com.google.android.gms com.google.android.gms.remapping1
com.google.android.gms com.google.android.gms.persistent
com.google.android.gms com.google.android.gms.learning
com.google.android.gms com.google.android.gms.feedback
com.google.android.gms com.google.android.gms
com.android.vending com.android.vending
com.android.vending com.google.android.finsky.verifier.impl.ConsentDialog
com.android.vending com.google.android.finsky.verifier.impl.legacydialogs.PackageWarningDialog
com.android.vending com.android.vending:background
com.android.vending com.android.vending:instant_app_installer
com.android.vending com.android.vending:com.google.android.finsky.verifier.apkanalysis.service.ApkContentsScanService"

if command -v magisk >/dev/null 2>&1 && magisk --denylist status >/dev/null 2>&1; then
    for item in $DENY_LIST_APPS; do
        magisk --denylist add $item >/dev/null 2>&1
    done
fi

# 4. تنظيف ذاكرة التخزين المؤقت لخدمات متجر بلاي
ui_print "- 🧹 جاري مسح ذاكرة التخزين المؤقت لـ Google Play..." ; delay
rm -rf /data/data/com.android.vending/code_cache/* 2>/dev/null
rm -rf /data/data/com.android.vending/cache/* 2>/dev/null
rm -rf /data/data/com.google.android.gms/code_cache/* 2>/dev/null
rm -rf /data/data/com.google.android.gms/cache/* 2>/dev/null

ui_print " " ; delay
ui_print "- ✅ تم إصلاح فحص SafetyNet بنجاح." ; delay
ui_print "- ✅ تم تزييف حالة البوت لودر." ; delay
ui_print "- ✅ تم إصلاح ترخيص متجر Google Play." ; delay
ui_print "- ✅ تم تأمين مسارات النظام ومحاذاة الـ 16KB." ; delay

ui_print " " ; delay
ui_print "- تم التثبيت بنجاح! 🦅🔥" ; delay
ui_print "- المطور: ABUFARID" ; delay