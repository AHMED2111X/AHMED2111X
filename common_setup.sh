# ==============================================================================
# إصلاح فحص الحماية FALCON INTEGRITY FIX - سكربت الإعداد والتوافقية المشترك
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
# ==============================================================================

# إزالة وحذف الإضافات المباشرة التي تسبب تعارضاً مؤكداً
if [ -d /data/adb/modules/safetynet-fix ]; then
    touch /data/adb/modules/safetynet-fix/remove
    ui_print "! سيتم إزالة موديول Universal SafetyNet Fix (USNF) عند إعادة التشغيل القادمة"
fi

# استبدال وإخفاء ملفات ومجلدات تطبيقات الحقن بالرومات المخصصة لإلغاء تفعيلها
LIST=$MODPATH/example.app_replace.list
[ -f "$MODPATH/custom.app_replace.list" ] && LIST=$MODPATH/custom.app_replace.list

for APP in $(grep -v '^#' $LIST); do
    if [ -e "$APP" ]; then
        case $APP in
            /system/*) ;;
            *) PREFIX=/system;;
        esac
        HIDEPATH=$MODPATH$PREFIX$APP
        if [ -d "$APP" ]; then
            mkdir -p $HIDEPATH
            if [ "$KSU" = "true" -o "$APATCH" = "true" ]; then
                setfattr -n trusted.overlay.opaque -v y $HIDEPATH
            else
                touch $HIDEPATH/.replace
            fi
        else
            mkdir -p $(dirname $HIDEPATH)
            if [ "$KSU" = "true" -o "$APATCH" = "true" ]; then
                mknod $HIDEPATH c 0 0
            else
                touch $HIDEPATH
            fi
        fi
        case $APP in
            */overlay/*)
                CFG=$(echo $APP | grep -oE '.*/overlay')/config/config.xml
                if [ -f "$CFG" ]; then
                    if [ -d "$APP" ]; then
                        APK=$(readlink -f $APP/*.apk);
                    elif [[ "$APP" = *".apk" ]]; then
                        APK=$(readlink -f $APP);
                    fi
                    if [ -s "$APK" ]; then
                        PKGNAME=$(unzip -p $APK AndroidManifest.xml | tr -d '\0' | grep -oE 'android.*overlay' | strings | tr -d '\n' | sed -e 's/^android//' -e 's/application//' -e 's;*http.*res/android;;' -e 's/manifest//' -e 's/overlay$//' | grep -oE '[[:alnum:].-_].*overlay' | cut -d\  -f2)
                        if [ "$PKGNAME" ] && grep -q "overlay package=\"$PKGNAME" $CFG; then
                            HIDECFG=$MODPATH$PREFIX$CFG
                            if [ ! -f "$HIDECFG" ]; then
                                mkdir -p $(dirname $HIDECFG)
                                cp -af $CFG $HIDECFG
                            fi
                            sed -i 's;<overlay \(package="'"$PKGNAME"'".*\) />;<!-- overlay \1 -->;' $HIDECFG
                        fi
                    fi
                fi
            ;;
        esac
        if [[ -d "$APP" || "$APP" = *".apk" ]]; then
            ui_print "! تم تعطيل تطبيق الروم المخصص $(basename $APP .apk)، يرجى إلغاء تثبيت تحديثات التطبيق بعد إعادة التشغيل"
            [ "$HIDECFG" ] && ui_print "!  + تم تعليق وإلغاء إدخال $PKGNAME في ملف إعدادات overlay المنسوخ"
        fi
    fi
done

# حل تعارضات خطافات التمويه (PropImitationHooks) بالرومات المخصصة في حال عدم وجود الخصائص الدائمة
if [ -n "$(resetprop ro.aospa.version)" -o -n "$(resetprop net.pixelos.version)" -o -n "$(resetprop ro.afterlife.version)" -o -f /data/system/gms_certified_props.json ]; then
    for PROP in persist.sys.pihooks.first_api_level persist.sys.pihooks.security_patch; do
        resetprop | grep -q "\[$PROP\]" || persistprop "$PROP" ""
    done
fi

# تعطيل محركات التمويه المدمجة بالرومات المخصصة لمنع التضارب مع تمويه الموديول
if resetprop | grep -qE "persist.sys.pihooks|persist.sys.entryhooks|persist.sys.spoof|persist.sys.pixelprops" || [ -f /data/system/gms_certified_props.json ]; then
    persistprop persist.sys.pihooks.disable.gms_props true
    persistprop persist.sys.pihooks.disable.gms_key_attestation_block true
    persistprop persist.sys.entryhooks_enabled false
    persistprop persist.sys.spoof.gms false
    persistprop persist.sys.pixelprops.gms false
    persistprop persist.sys.pixelprops.gapps false
    persistprop persist.sys.pixelprops.google false
    persistprop persist.sys.pixelprops.pi false
fi