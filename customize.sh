{\rtf1}# --- إعدادات التثبيت لإضافة FALCON ---

# طباعة شعار الإضافة عند التثبيت
ui_print " "
ui_print "  ######################################"
ui_print "  #                                    #"
ui_print "  #      🦅 FALCON INTEGRITY FIX 🦅    #"
ui_print "  #          Version: v2.14            #"
ui_print "  #         Developer: ABUFARID        #"
ui_print "  #                                    #"
ui_print "  ######################################"
ui_print " "

# التأكد من وجود ملفات الحماية المطلوبة في مجلد الإضافة
if [ -f "$MODPATH/pif.json" ]; then
    ui_print "- جاري تجهيز ملفات بصمة الأمان (PIF)..."
else
    ui_print "! تحذير: ملف pif.json غير موجود في حزمة التثبيت."
fi

# إعداد صلاحيات التنفيذ لسكربت الخدمة
ui_print "- ضبط صلاحيات سكربتات النظام..."
set_perm $MODPATH/service.sh 0 0 0755

# فحص وجود أداة curl الضرورية لنظام التتبع الخاص بك
if [ -f /system/bin/curl ] || [ -f /apex/com.android.runtime/bin/curl ]; then
    ui_print "- تم التحقق من وجود أداة التتبع (Curl)."
else
    ui_print "! تنبيه: أداة curl مفقودة، قد لا يعمل نظام التتبع بشكل صحيح."
fi

ui_print " "
ui_print "✅ تم التثبيت بنجاح! استمتع بحماية الصقر."
ui_print "📢 يرجى إعادة تشغيل الجهاز لتفعيل التعديلات."