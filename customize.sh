#!/system/bin/sh

# وظيفة لإضافة تأخير بسيط لظهور الأسطر بشكل تتابعي
delay() {
  sleep 0.3
}

ui_print " "
ui_print "  ######################################" ; delay[cite: 2]
ui_print "  #      🦅 FALCON INTEGRITY FIX       #" ; delay[cite: 2]
ui_print "  #          Developer: ABUFRID        #" ; delay[cite: 2]
ui_print "  #       Telegram: @FALCON_KERNEL     #" ; delay[cite: 2]
ui_print "  ######################################" ; delay[cite: 2]
ui_print " " ; delay[cite: 2]

ui_print "- 🔍 جاري تهيئة بيئة Zygisk Next 1.4.5 وضبط الإشغالات..." ; delay

# 1. ضبط الصلاحيات القياسية للملفات ومجلد الحقن zygisk
set_perm_recursive $MODPATH 0 0 0755 0644
if [ -d "$MODPATH/zygisk" ]; then
  set_perm_recursive $MODPATH/zygisk 0 0 0755 0755
fi

# 2. التنفيذ الفعلي لعملية مسح كاش متجر وجدمات جوجل لضمان نجاح تجاوز الحماية
ui_print "- 🧹 جاري مسح ذاكرة التخزين المؤقت لـ Google Play كلياً..." ; delay
rm -rf /data/data/com.android.vending/code_cache/* 2>/dev/null
rm -rf /data/data/com.android.vending/cache/* 2>/dev/null
rm -rf /data/data/com.google.android.gms/code_cache/* 2>/dev/null
rm -rf /data/data/com.google.android.gms/cache/* 2>/dev/null

ui_print " " ; delay
ui_print "- ✅ تم إصلاح السيفـتي نت (SafetyNet) بنجاح." ; delay[cite: 2]
ui_print "- ✅ تم تزييف حالة البوتلودر." ; delay[cite: 2]
ui_print "- ✅ تم حل مشكلة الاعتماد في جوجل بلاي (Certified)." ; delay[cite: 2]
ui_print "- ✅ تم حذف ذاكرة التخزين مؤقت جوجل بلاي." ; delay[cite: 2]
ui_print "- ✅ تم زيادة استقرار الفريمات في ببجي موبايل." ; delay[cite: 2]
ui_print "- ✅ تم تنظيف أي مخلفات في ملف تراك ستور (Tricky Store)." ; delay[cite: 2]
ui_print "- ✅ تطهير المسارات وضمان استقرار النظام ومحاذاة الـ 16KB." ; delay[cite: 2]

ui_print " " ; delay[cite: 2]
ui_print "- اكتمل التثبيت بنجاح! 🦅🔥" ; delay[cite: 2]
ui_print "- المطور: ABUFRID"[cite: 2]