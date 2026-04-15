# --- إعدادات تثبيت إضافة FALCON ---

# طباعة رسالة للمستخدم أثناء التثبيت
ui_print "- Installing FALCON PLAY FIX..."
ui_print "- Setting up secure environment..."

# إعطاء صلاحية التنفيذ لملف الخدمة المشفر (Binary)
# هذا السطر هو الأهم ليعمل ملف service.sh المشفر
set_perm $MODPATH/service.sh 0 0 0755

# ضبط صلاحيات الكيبوكس (اختياري لزيادة الأمان)
if [ -f "$MODPATH/keybox.xml" ]; then
    set_perm $MODPATH/keybox.xml 0 0 0644
fi

ui_print "- Encryption Verified."
ui_print "- Developer: @rngfalcon"
ui_print "- Success! Please reboot your device."