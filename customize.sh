# --- واجهة Falcon Terminal v2.1.15 مع التنظيف العميق لملفات الـ BAK ---
cat << 'EOF' > $MODPATH/system/bin/falcon
#!/system/bin/sh
MODDIR="/data/adb/modules/falcon_kernel_fix"
TS_PATH="/data/adb/tricky_store"

echo " "
echo "  ######################################"
echo "  #      🦅 FALCON CONTROL PANEL 🦅    #"
echo "  #          Developer: ABUFARID       #"
echo "  ######################################"
echo " "
echo "1) 🚀 وضع الوحش + حذف ملفات الـ BAK"
echo "2) 🔋 وضع التوفير (60 FPS)"
echo "3) 🔍 فحص وتنظيف المسار"
echo "4) ❌ خروج"
echo " "
read -p "اختر رقم العملية: " choice

case $choice in
    1)
        # تفعيل الأداء
        settings put signature min_refresh_rate 165.0
        settings put signature peak_refresh_rate 165.0
        setprop windowsmgr.max_events_per_sec 300
        
        # --- حذف ملف keybox.xml.bak وتنظيف المسار ---
        if [ -d "$TS_PATH" ]; then
            # حذف الملف الاحتياطي تحديداً إن وجد
            [ -f "$TS_PATH/keybox.xml.bak" ] && rm -f "$TS_PATH/keybox.xml.bak" && echo "🗑️ تم حذف keybox.xml.bak بنجاح."
            
            # حذف الكيبوكس القديم والملفات المؤقتة الأخرى
            rm -f $TS_PATH/keybox.xml
            rm -f $TS_PATH/*.tmp
        fi
        
        # نسخ الكيبوكس الجديد من الإضافة
        if [ -f "$MODDIR/keybox.xml" ]; then
            mkdir -p $TS_PATH
            cp $MODDIR/keybox.xml $TS_PATH/keybox.xml
            chown root:root $TS_PATH/keybox.xml
            chmod 644 $TS_PATH/keybox.xml
            echo "✅ تم تحديث الكيبوكس وتنظيف المسار تماماً."
        fi
        echo "✅ وضع الـ 165 فريم نشط الآن!"
        ;;
    2)
        settings put signature min_refresh_rate 60.0
        settings put signature peak_refresh_rate 60.0
        echo "✅ تم العودة لوضع 60 فريم."
        ;;
    3)
        echo "🔍 فحص ملفات TrickyStore..."
        # حذف ملف الباك فوراً عند الفحص أيضاً لزيادة التأكيد
        rm -f $TS_PATH/keybox.xml.bak
        ls -l $TS_PATH
        ;;
esac
EOF

# ضبط صلاحيات الملف ليعمل كأمر نظام
set_perm $MODPATH/system/bin/falcon 0 0 0755