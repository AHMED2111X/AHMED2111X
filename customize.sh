# إنشاء المسارات الضرورية[cite: 11]
mkdir -p $MODPATH/system/bin[cite: 11]

# نقل واجهة falcon التي أنشأتها يدوياً[cite: 11]
cp -f $MODPATH/falcon $MODPATH/system/bin/falcon[cite: 11]

# ضبط الصلاحيات النهائية[cite: 11]
ui_print "- جاري ضبط صلاحيات Falcon v2.18..."[cite: 11]

set_perm $MODPATH/inject 0 0 0755[cite: 11]
set_perm $MODPATH/system/bin/falcon 0 0 0755[cite: 11]
set_perm $MODPATH/service.apk 0 0 0644[cite: 11]

ui_print "- اكتمل التثبيت يا بطل! اكتب falcon في الترمينال."[cite: 11]