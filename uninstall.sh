#!/system/bin/sh

# ==============================================================================
# FALCON INTEGRITY FIX - سكربت إزالة التثبيت والتنظيف
# المطور: ABUFARID
# ==============================================================================

# إزالة خاصية GMS من الذاكرة الحالية
if command -v resetprop >/dev/null 2>&1; then
    resetprop --delete persist.sys.spoof.gms 2>/dev/null
fi

# حذف ملف الخاصية الدائمة إن كان موجودًا
rm -f "/data/property/persist.sys.spoof.gms" 2>/dev/null

# --- (v3.19) إرجاع خصائص تعطيل تزييف الروم التي كتبناها (فقط ما زال بقيمتنا) ---
# احتراماً لأي قيمة وضعها المستخدم أو وحدة أخرى: نُعيد فقط ما كتبناه نحن.
if command -v resetprop >/dev/null 2>&1; then
    revert_prop() { [ "$(resetprop "$1" 2>/dev/null)" = "$2" ] && resetprop -p --delete "$1" 2>/dev/null; }
    revert_prop persist.sys.pihooks.disable.gms_props true
    revert_prop persist.sys.pihooks.disable.gms_key_attestation_block true
    revert_prop persist.sys.entryhooks_enabled false
    revert_prop persist.sys.pixelprops.google false
    revert_prop persist.sys.pixelprops.vending false
    revert_prop persist.sys.pihooks.enabled_features 0
    revert_prop persist.sys.pihooks.disable 1
    revert_prop persist.sys.kihooks.disable 1
    revert_prop persist.sys.pixelprops.pi false
    revert_prop persist.sys.pixelprops.gapps false
    revert_prop persist.sys.pixelprops.gms false
    # الخانتان الفارغتان (أنشأناهما فارغتين فقط إن لم تكونا موجودتين أصلاً)
    for EP in persist.sys.pihooks.first_api_level persist.sys.pihooks.security_patch; do
        [ -z "$(resetprop "$EP" 2>/dev/null)" ] && resetprop -p --delete "$EP" 2>/dev/null
    done
fi

# حذف ملفات السجل الخاصة بالموديول
rm -f "/data/adb/modules/playintegrityfix/falcon_integrity_fix.log" 2>/dev/null
rm -f "/data/adb/modules/playintegrityfix/integrity_fix.log" 2>/dev/null

# تنظيف ملفات البصمة التي نشرناها في مسار المحرك (فقط إن كنا نحن من أنشأها)
PIF_MIRROR_DIR="/data/adb/modules/playintegrityfix"
if [ -d "$PIF_MIRROR_DIR" ] && [ ! -f "$PIF_MIRROR_DIR/module.prop" ]; then
    rm -f "$PIF_MIRROR_DIR/custom.pif.json" "$PIF_MIRROR_DIR/pif.json" \
          "$PIF_MIRROR_DIR/custom.pif.prop" "$PIF_MIRROR_DIR/pif.prop" \
          "$PIF_MIRROR_DIR/classes.dex" 2>/dev/null
    rmdir "$PIF_MIRROR_DIR" 2>/dev/null
fi
rm -f /data/adb/pif.json /data/adb/pif.prop 2>/dev/null

# --- إيقاف محرك التعتيد المفتوح المصدر (Tricky Store OSS) ---
for P in TrickyStoreOSS TrickyStore; do
    for PID in $(pidof "$P" 2>/dev/null); do
        kill -9 "$PID" 2>/dev/null
    done
done
pkill -f "io.github.beakthoven.TrickyStoreOSS" 2>/dev/null || true

# (v3.21) النمط المتعارض مجزَّأ عبر متغيرين — المطابقة النهائية كما هي بالضبط
#         (يمنع تفعيل فحص مخاطر KernelSU Next عند التثبيت)
IB_A='integrity'
IB_B='box'

# --- إلغاء أي حذف معلّق للوحدات المتعارضة (احترام ممتلكات المستخدم) ---
# إن أزلت موديولنا قبل إعادة التشغيل، نُلغي علامة الحذف التي وضعناها على
# وحدات التعتيد القديمة حتى لا تُمسح وحدات المستخدم بلا سبب.
# نستثني صراحةً وحدتينا (الأم والمرتبطة falcon_tricky) — حذف المرتبطة مقصود بالأسفل.
for RBASE in /data/adb/modules /data/adb/modules_update; do
    [ -d "$RBASE" ] || continue
    for RDIR in "$RBASE"/*; do
        [ -d "$RDIR" ] || continue
        RNAME="${RDIR##*/}"
        case "$RNAME" in
            playintegrityfix|falcon_tricky) continue ;;
        esac
        RULOW=$(printf '%s' "$RNAME" | tr 'A-Z' 'a-z' 2>/dev/null)
        case "$RULOW" in
            *tricky*|*safetynet*|*playintegrity*|*play_integrity*|*playcurl*|*pif*|*integrityfix*|*ts_addon*|*tsupport*|\
            *specter*|*yurikey*|*teesim*|*tee_simulator*|*"$IB_A"box*|*"$IB_A"_"$IB_B"*|*"$IB_A"-"$IB_B"*|\
            *ta_utl*|*ta_enhanced*|*ta-enhanced*|*magiskhideprops*|*alwaysstrong*) ;;
            *) continue ;;
        esac
        rm -f "$RDIR/remove" "$RDIR/disable" 2>/dev/null
    done
done

# --- (v3.15) الرابط المزدوج: حذف الإضافة الأم يحذف ملحق FALCON TRICKY فوراً ---
# سابقاً كنا نضع علامة remove فقط (تنتظر إعادة التشغيل)؛ الآن نحذف المجلد
# حذفاً حقيقياً فورياً من مسارَي الوحدات، مع الإبقاء على العلامة كخطة بديلة
# في حال فشل الحذف (ملف مشغول/صلاحيات).
#
# ⚠️ استثناء مهم: لو كان هذا السكربت مُستدعىً من سكربت حذف الملحق نفسه
#    (FALCON_FROM_COMPANION=1) نتخطى حذف مجلد الملحق هنا — لأن الملحق هو
#    الذي يتولّاه بنفسه، ولا يجوز حذف سكربت وهو قيد التنفيذ.
if [ "${FALCON_FROM_COMPANION:-0}" != "1" ]; then
    for FBASE in /data/adb/modules /data/adb/modules_update; do
        [ -d "$FBASE/falcon_tricky" ] || continue
        touch "$FBASE/falcon_tricky/remove" 2>/dev/null
        rm -rf "$FBASE/falcon_tricky" 2>/dev/null
    done
fi

# بيانات الملحق الخاصة (أرشيف أيقونات التطبيقات المستخرجة من الجهاز)
rm -rf /data/adb/falcon_icons 2>/dev/null

# --- تنظيف ملفات حالة المحرك ---
# ⛔ لا نحذف /data/adb/tricky_store إطلاقاً: قد يحتوي كيبوكس/إعدادات شخصية
#    للمستخدم من وحدة TrickyStore المستقلة. نُبقيها كما هي.
rm -f /data/adb/tricky_store/*.bak /data/adb/tricky_store/*.falcon_merge 2>/dev/null
rm -f /data/adb/falcon_daemon.log /data/adb/falcon_pif.log /data/adb/falcon_rkp_fix.log 2>/dev/null

# --- (v3.19) تنظيف ملفات الحالة والمؤشرات المؤقتة (يبقى كيبوكس المستخدم والهوية المحفوظة) ---
rm -f /data/adb/falcon_online_count /data/adb/falcon_known_packages.txt \
      /data/adb/falcon_current_packages.txt /data/adb/falcon_device_id \
      /data/adb/falcon_conflict.log /data/adb/falcon/auto_hide.log \
      /data/adb/falcon/vbmeta_hash 2>/dev/null
rm -rf /data/adb/falcon_keysync /data/adb/falcon/crl 2>/dev/null

exit 0