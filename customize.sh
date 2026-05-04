#!/system/bin/sh
mkdir -p $MODPATH/system/bin

ui_print "- جاري إنشاء واجهة Falcon Terminal v2.18..."

cat << 'EOF' > $MODPATH/system/bin/falcon
#!/system/bin/sh
MODDIR="/data/adb/modules/falcon_integrity_fix"
TS_PATH="/data/adb/tricky_store"

clear
echo "  ######################################"
echo "  #      🦅 FALCON TERMINAL v2.18      #"
echo "  #          Developer: ABUFARID       #"
echo "  ######################################"
echo " "
echo "1) 🚀 وضع الوحش (أداء 165 FPS)"
echo "2) 🧹 تنظيف الكاش الذكي (GMS & Store)"
echo "3) 🗑️ حذف ملفات الـ BAK وتنظيف المسار"
echo "4) ❌ خروج"
echo " "
read -p "اختر رقم العملية: " choice

case $choice in
    1)
        settings put signature min_refresh_rate 165.0
        settings put signature peak_refresh_rate 165.0
        echo "✅ تم تفعيل الأداء الأقصى!"
        ;;
    2)
        rm -rf /data/data/com.google.android.gms/cache/*
        rm -rf /data/data/com.android.vending/cache/*
        echo "✅ تم التنظيف الذكي بنجاح!"
        ;;
    3)
        rm -f $TS_PATH/*.bak
        rm -f $TS_PATH/*.tmp
        echo "✅ تم تنظيف جميع الملفات الاحتياطية والمؤقتة."
        ;;
    *)
        exit
        ;;
esac
EOF

# ضبط الصلاحيات النهائية
set_perm $MODPATH/system/bin/falcon 0 0 0755
set_perm $MODPATH/action.sh 0 0 0755
set_perm $MODPATH/inject 0 0 0755

ui_print "- اكتمل التثبيت بنجاح! 🦅🔥"