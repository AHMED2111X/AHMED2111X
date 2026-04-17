#!/system/bin/sh

# 1. استخراج ملفات الواجهة (الصور والأيقونات)
ui_print "- Extracting WebUI resources..."
unzip -o "$ZIPFILE" "webroot/*" -d "$MODPATH" >&2

# 2. استخراج صورة الـ splash لعرضها أثناء التفليش
unzip -o "$ZIPFILE" "splash" -d "$MODPATH" >&2

if [ -f "$MODPATH/splash" ]; then
    set_perm $MODPATH/splash 0 0 0644
    ui_print " "
    ui_print_image "$MODPATH/splash"
    ui_print " "
fi

# 3. تثبيت ملفات الخدمة والصلاحيات
ui_print "- Installing FALCON INTEGRITY FIX..."
set_perm $MODPATH/service.sh 0 0 0755

# 4. حقوق المطور ABUFARID
ui_print "--------------------------------------"
ui_print "- Developer: ABUFARID"
ui_print "- WebUI: Enabled"
ui_print "--------------------------------------"
ui_print "- Success! Please reboot."