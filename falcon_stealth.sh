#!/system/bin/sh

# ==============================================================================
# FALCON INTEGRITY FIX — وضع التخفي من السجلات (v3.19)
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
#
# الوظيفة:
#   1) إخماد وسومنا من المنبع في logcat (persist.log.tag.* = S) حتى لا تظهر
#      رسائل FALCON_FIX لأي تطبيق يقرأ السجل (كاشفات الروت تقرأ logcat).
#   2) تنظيف دوري (كل 30 دقيقة) لملفات ANR/tombstone التي قد تذكر آثارنا
#      (FALCON / TrickyStoreOSS / مسارات playintegrityfix) — يقشر أسطرنا فقط
#      من التقرير ولا يحذف الملف نفسه.
#
# الإيقاف: touch /data/adb/falcon/no_log_cleanup
# ملاحظة: لا يمس أي شيء غير ذي صلة — فقط الأسطر التي تحمل آثارنا.
# ==============================================================================

[ -f /data/adb/falcon/no_log_cleanup ] && exit 0

# --- الانتظار حتى يكتمل الإقلاع (بحد أقصى 8 دقائق) ---
W=0
while [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ] && [ "$W" -lt 240 ]; do
    sleep 2
    W=$((W + 1))
done

# --- 1) إخماد وسومنا من المنبع (دائمة: تبقى بعد إعادة التشغيل) ---
for T in FALCON_FIX FALCON; do
    resetprop -p "persist.log.tag.$T" S 2>/dev/null
done

# --- 2) حلقة التنظيف الدورية ---
while true; do
    for F in /data/anr/anr_* /data/anr/traces.txt /data/tombstones/tombstone_*; do
        [ -f "$F" ] || continue
        if grep -qE "FALCON|falcon|TrickyStoreOSS|libTrickyStoreOSS|playintegrityfix|libinject" "$F" 2>/dev/null; then
            sed -i '/FALCON/d;/falcon/d;/TrickyStoreOSS/d;/libTrickyStoreOSS/d;/playintegrityfix/d;/libinject/d' "$F" 2>/dev/null
        fi
    done
    rm -f /data/local/tmp/falcon_*.log /data/local/tmp/falcon_*.tmp 2>/dev/null
    sleep 1800
done
