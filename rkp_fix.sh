#!/system/bin/sh

# ==============================================================================
# إصلاح فحص الحماية FALCON INTEGRITY FIX - إصلاح مفاتيح التحقق عن بُعد (RKP)
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
#
# متى يفيد هذا السكربت؟
#   فقط عندما تكون مفاتيح التحقق داخل الجهاز "تالفة"، أي أن الأمر التالي يفشل:
#       cmd remote_provisioning certify default
#   ويُطبع فيه:
#       android.security.rkp.service.RkpProxyException: ERROR_UNKNOWN: Failure in CSR v2 generation.
#   (أشهر سبب: استعادة نسخة EDL / تحديث نظام / كيرنل مخصص)
#
#   إذا نجح الأمر وأصدر سلسلة شهادات (BEGIN CERTIFICATE) فمعنى ذلك أن المفاتيح
#   سليمة، والإصلاح لن يُغيّر شيئاً — ويكون السبب الحقيقي مختلفاً (غالباً فتح
#   البوت لودر، وهو ما يمنع جوجل من اعتماد الجهاز رسمياً).
#
# الأوضاع:
#   sh rkp_fix.sh auto    ← تلقائي (service.sh): يعالج فقط إذا كانت المفاتيح تالفة
#   sh rkp_fix.sh manual  ← فحص + إصلاح يدوي (بدون تصفير أو إعادة تشغيل)
#   sh rkp_fix.sh full    ← الإصلاح الكامل (إصلاح + إعادة تشغيل تلقائية)
#   sh rkp_fix.sh google  ← إعادة تشغيل خدمات جوجل الثلاث (بدون مسح أي بيانات)
#   sh rkp_fix.sh force   ← إجبار إعادة التزوير حتى لو كانت المفاتيح سليمة
#                            (مخصّص لأجهزة Red Magic التي تتجاهل الكيبوكس المسروق)
#   sh rkp_fix.sh certify ← إجبار متجر Play على إعادة قراءة الاعتماد (Certified)
#                            (يفرّغ الكاش + يعيد ضبط بيانات المتجر فقط — الحساب لا يُمس)
#   sh rkp_fix.sh wipe    ← المسح الشامل لجوجل (الخيار الأخير): يمسح بيانات المتجر +
#                            خدمات جوجل (GMS) + إطار الخدمات (GSF) ويُعيد التشغيل تلقائياً
#                            ⛔ يُسجّل خروج الحسابات — لا يُنفَّذ إلا بطلب صريح من المستخدم
#
# ⛔ سياسة المسح: لا يُنفَّذ أي مسح تلقائياً أو عند الإقلاع إطلاقاً — فقط بطلب صريح من المستخدم.
#    • certify: مسح متجر Play وحده (الحساب لا يُمس — محفوظ في GMS وليس في المتجر).
#    • wipe: المسح الشامل (متجر + GMS + GSF) — يُسجّل خروج الحسابات، ويُعاد التشغيل تلقائياً.
# ==============================================================================

FALCON_DIR="/data/adb/falcon"
MARKER="$FALCON_DIR/rkp_fix_done"
LOGFILE="/data/adb/falcon_rkp_fix.log"

MODE="$1"
case "$MODE" in
    manual|full|google|force|certify|wipe) ;;
    *) MODE="auto" ;;
esac

# --- التحقق من صلاحيات الروت ---
if [ "$(id -u 2>/dev/null)" != "0" ]; then
    [ "$MODE" != "auto" ] && echo "✖ تتطلب هذه العملية صلاحيات الروت (Root)"
    exit 1
fi

mkdir -p "$FALCON_DIR" 2>/dev/null

say() {
    echo "$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null) | $1" >> "$LOGFILE" 2>/dev/null
    LINES=$(wc -l < "$LOGFILE" 2>/dev/null)
    case "$LINES" in
        *[5-9][0-9][0-9])
            tail -n 300 "$LOGFILE" > "$LOGFILE.trim" 2>/dev/null && \
                mv -f "$LOGFILE.trim" "$LOGFILE" 2>/dev/null
            ;;
    esac
}

reboot_now() {
    say "🔄 إعادة تشغيل الجهاز الآن..."
    sync 2>/dev/null
    # ⚠️ نُطلق إعادة التشغيل في الخلفية حتى لا تعلّق واجهة الويب (WebUI) أبداً.
    (
        sleep 2
        if command -v svc >/dev/null 2>&1; then
            svc power reboot 2>/dev/null
        fi
        command -v reboot >/dev/null 2>&1 && reboot 2>/dev/null
    ) >/dev/null 2>&1 &
    return 0
}

# --- وضع google: تصفير خدمات جوجل فقط ---
if [ "$MODE" = "google" ]; then
    say "════════ FALCON إعادة تشغيل خدمات جوجل (بدون مسح أي بيانات) ════════"
    # ⛔ لا pm clear — إعادة التشغيل وحدها كافية لإجبار الخدمة على التحقق من جديد.
    for P in com.google.android.gms com.google.android.gsf com.android.vending; do
        say "🔄 إعادة تشغيل: $P"
        am force-stop "$P" >/dev/null 2>&1
    done
    say "✔ تمت إعادة التشغيل بلا أي مسح — حساباتك وبياناتك كما هي."
    say "  بعد الإقلاع: لا تفحص Play Integrity لمدة 15-20 دقيقة على الأقل."
    say "════════ انتهى التقرير ════════"
    reboot_now
    exit 0
fi

# --- وضع certify: إجبار متجر Play على إعادة قراءة حالة الاعتماد (Certified) ---
# ⛔ لا نلمس حساب جوجل إطلاقاً: الحساب محفوظ في خدمات جوجل (GMS)، والضبط يخص متجر Play وحده.
if [ "$MODE" = "certify" ]; then
    say "════════ FALCON إجبار اعتماد متجر Play (Certified) ════════"
    say "ℹ️ حسابك وتطبيقاتك ومشترياتك لا تُمس — الضبط يخص متجر Play فقط."
    for P in com.google.android.gms com.google.android.gsf com.android.vending; do
        say "🔄 إيقاف مؤقت: $P"
        am force-stop "$P" >/dev/null 2>&1
    done
    say "🧹 تفريغ كاش خدمات جوجل (بدون أي بيانات)..."
    rm -rf /data/data/com.google.android.gms/cache/* 2>/dev/null
    rm -rf /data/data/com.google.android.gsf/cache/* 2>/dev/null
    say "🗑️ إعادة ضبط بيانات متجر Play وحده (ليعيد قراءة الاعتماد)..."
    if pm clear com.android.vending >/dev/null 2>&1; then
        say "  ✔ تمت إعادة ضبط المتجر — حسابك لم يُمس إطلاقاً."
    else
        say "  ⚠️ تعذّرت إعادة الضبط — سيكملها الإقلاع."
    fi
    say ""
    say "🔄 أعد تشغيل الجهاز الآن ثم افتح متجر Play واتركه يبني حالته."
    say "   • التحقق: Play Store ← الإعدادات ← حول ← «اعتماد Play Protect»."
    say "   • يظهر «معتمد» عادة خلال دقائق — وقد يتأخر حتى 1-2 ساعة (جوجل تسجّل الجهاز)."
    say "   • إن بقي غير معتمد: تأكد أن فحص Play Integrity يعطي BASIC على الأقل."
    say "════════ انتهى التقرير ════════"
    exit 0
fi

# --- وضع wipe: المسح الشامل لجوجل (الخيار الأخير للاعتماد — يُسجّل خروج الحسابات) ---
# ⛔ يُنفَّذ فقط بطلب صريح من المستخدم (زر الواجهة) — لا يُستدعى تلقائياً أو عند الإقلاع أبداً.
if [ "$MODE" = "wipe" ]; then
    say "════════ FALCON المسح الشامل لجوجل (الخيار الأخير) ════════"
    say "⛔ تنبيه: سيتم تسجيل الخروج من حسابات جوجل — ستحتاج إضافتها من جديد."
    say "ℹ️ لا تُمس صورك وملفاتك وتطبيقاتك — فقط بيانات تطبيقات جوجل الثلاثة."
    for P in com.google.android.gms com.google.android.gsf com.android.vending; do
        am force-stop "$P" >/dev/null 2>&1
        say "🔄 إيقاف: $P"
    done
    for P in com.google.android.gsf com.google.android.gms com.android.vending; do
        if pm clear "$P" >/dev/null 2>&1; then
            say "🗑️ مُسحت بيانات: $P"
        else
            say "⚠️ تعذّر مسح: $P"
        fi
    done
    say ""
    say "✅ انتهى المسح الشامل — جاري إعادة تشغيل الجهاز..."
    say "   • بعد الإقلاع: أضف حساب جوجل من: الإعدادات ← الحسابات."
    say "   • ثم افتح متجر Play واتركه يبني حالته (يظهر «معتمد» خلال دقائق إلى ساعتين)."
    say "   • إن بقي غير معتمد: تأكد أن Play Integrity يعطي BASIC على الأقل."
    say "════════ انتهى التقرير ════════"
    reboot_now
    exit 0
fi

# في الوضع التلقائي: لا نكرر الإصلاح إذا كان مُنفَّذاً سابقاً
if [ "$MODE" = "auto" ] && [ -f "$MARKER" ]; then
    exit 0
fi

# --- 1. البحث عن أداة KmInstallKeybox ---
KM_BIN=""
for CAND in /vendor/bin/KmInstallKeybox /system/bin/KmInstallKeybox /system_ext/bin/KmInstallKeybox; do
    if [ -f "$CAND" ]; then
        KM_BIN="$CAND"
        break
    fi
done

if [ -z "$KM_BIN" ]; then
    if [ "$MODE" != "auto" ]; then
        say "════════ FALCON إصلاح مفاتيح RKP ════════"
        say "✖ لم يتم العثور على أداة KmInstallKeybox على هذا الجهاز."
        say "  الأداة متوفرة في روم RedMagic الأصلي (Stock) فقط."
    fi
    exit 1
fi

say "════════ FALCON إصلاح مفاتيح RKP (${MODE}) ════════"
say "✔ تم العثور على أداة الإصلاح: $KM_BIN"

# --- 2. فحص حالة مفاتيح RKP الحالية ---
say ""
say "📋 الخطوة 1: فحص وحدات Remote Key Provisioning المتوفرة..."
# 🛡️ timeout إلزامي: أمر RKP قد يعلّق الجهاز إن كان TEE تالفاً
RKP_LIST=$(timeout 20 cmd remote_provisioning list 2>&1)
say "$RKP_LIST"

say ""
say "📋 الخطوة 2: محاولة إصدار شهادة تحقق (CSR) من TEE..."
CSR_OUT=$(timeout 30 cmd remote_provisioning certify default 2>&1)
CSR_STATE="unknown"

if echo "$CSR_OUT" | grep -qE "RkpProxyException|Failure in CSR|ERROR_UNKNOWN" 2>/dev/null; then
    CSR_STATE="broken"
    say "✖ فشل إصدار الشهادة — مفاتيح التحقق داخل الجهاز تالفة."
    say "  (الأسباب الشائعة: استعادة نسخة EDL، تحديث نظام، أو تغيير كيرنل)"
elif echo "$CSR_OUT" | grep -q "BEGIN CERTIFICATE" 2>/dev/null; then
    CSR_STATE="healthy"
    say "✔ الـ TEE أصدر سلسلة شهادات كاملة — مفاتيح التحقق سليمة."
    say "  ➜ أي مشكلة متبقية (خاصة \"غير معتمد في جوجل\") سببها غالباً فتح البوت لودر،"
    say "    وليس مفاتيح RKP. جوجل: \"Lock bootloader to fix issue\"."
else
    CSR_STATE="unknown"
    say "⚠️ لم نتمكن من قراءة حالة الشهادات بوضوح (الناتج غير معروف)."
    say "  الناتج كان: $(echo "$CSR_OUT" | head -c 200)"
fi

# --- في الوضع التلقائي: لا ننفّذ إصلاحاً إذا كانت المفاتيح سليمة ---
if [ "$MODE" = "auto" ] && [ "$CSR_STATE" = "healthy" ]; then
    say "ℹ️ الوضع التلقائي: المفاتيح سليمة — تم تخطي إعادة التزوير (لا حاجة لها)."
    date '+%Y-%m-%d %H:%M:%S' > "$MARKER" 2>/dev/null
    say "════════ انتهى التقرير ════════"
    exit 0
fi

# --- 3. إعادة طلب شهادات جديدة من جوجل (وضع RKP) ---
say ""
SKIPPED=0
if [ "$CSR_STATE" = "healthy" ] && [ "$MODE" != "force" ]; then
    # 🛡️ حماية حرجة: إعادة التزوير على مفاتيح سليمة لا تفيد إطلاقاً،
    # وهي عملية خطيرة على TEE/keystore2 وقد تعلّق الجهاز بلا سبب.
    # لذلك نتخطّاها دائماً ونسلك مسار إعادة التشغيل فقط.
    say "ℹ️ مفاتيح التحقق سليمة — تم تخطي إعادة التزوير (عملية خطيرة بلا داعٍ)."
    say "   السبب الحقيقي لظهور «غير معتمد» غالباً فتح البوت لودر وليس المفاتيح."
    SKIPPED=1
    INSTALL_OUT=""
    RC=0
else
    if [ "$CSR_STATE" = "healthy" ]; then
        say "⚠️ وضع الإجبار (force): إعادة التزوير رغم أن المفاتيح سليمة —"
        say "   (مطلوب لأجهزة Red Magic التي تتجاهل الكيبوكس المسروق بعد تحديث RKP)."
    fi
    say "🛠️ الخطوة 3: تنفيذ إعادة التزوير عبر KmInstallKeybox بوضع RKP..."
    say "   (الأداة تتجاهل ملف الـ XML وتطلب من TEE شهادات جديدة من جوجل)"
    say "   ⏳ مهلة قصوى 90 ثانية حمايةً للجهاز من التعليق."

    EMPTY_XML="/data/local/tmp/falcon_empty.xml"
    touch "$EMPTY_XML" 2>/dev/null

    # 🛡️ timeout إلزامي: أداة ZTE تعمل على TEE وقد تعلّق الجهاز بلا مهلة
    INSTALL_OUT=$(timeout 90 env LD_LIBRARY_PATH=/vendor/lib64/hw:/vendor/lib64 \
        "$KM_BIN" "$EMPTY_XML" 0 true true 2>&1)
    RC=$?
    say "$INSTALL_OUT"

    rm -f "$EMPTY_XML" 2>/dev/null
fi

if [ "$RC" = "0" ]; then
    say ""
    if [ "$SKIPPED" = "1" ]; then
        say "ℹ️ تم تخطي إعادة التزوير (المفاتيح سليمة أصلاً)."
    else
        say "✔ تم تنفيذ إعادة التزوير بنجاح (رمز الخروج: $RC)."
    fi

    if [ "$MODE" = "full" ]; then
        # ⛔ أُزيل مسح بيانات جوجل (pm clear) نهائياً لأنه كان يُخرج حسابات متجر Play.
        # إعادة تشغيل خدمة Google Play Services كافية لإجبارها على التحقق من جديد.
        say ""
        say "🔄 الخطوة 4: إعادة تشغيل خدمات Google Play Services (بدون مسح أي بيانات)..."
        am force-stop com.google.android.gms >/dev/null 2>&1 && \
            say "  ✔ تمت إعادة تشغيل Google Play Services بلا مسح." || \
            say "  ⚠️ تعذّرت إعادة التشغيل — سيكملها الإقلاع."
        say "✔ انتهت الخطوات — جاري إعادة التشغيل."
        say "════════ انتهى التقرير ════════"
        reboot_now
        exit 0
    fi

    # إيقاف عمليات خدمات جوجل القديمة لإجبارها على الالتقاء بخوادم جوجل مجدداً
    for PKG in com.google.android.gms.unstable com.google.android.gms com.android.vending; do
        if command -v killall >/dev/null 2>&1; then
            killall "$PKG" 2>/dev/null
        elif command -v pkill >/dev/null 2>&1; then
            pkill -f "$PKG" 2>/dev/null
        elif command -v am >/dev/null 2>&1; then
            am force-stop "$PKG" 2>/dev/null
        fi
    done

    if [ "$MODE" != "auto" ]; then
        say "  ✔ تم إيقاف عمليات خدمات جوجل القديمة."
        say ""
        say "🔄 الخطوة 4: أعد تشغيل الجهاز الآن ثم تحقق من النتيجة."
        say "   • إن بقيت النتيجة (BASIC فقط) أو ظهرت \"غير معتمد\":"
        say "     شغّل الوضع الكامل: sh rkp_fix.sh full   (أو استخدم زر الإصلاح الكامل في WebUI)"
        say "   • تأكد أن البوت لودر يظهر مقفلاً (تزوير حالة البوت لودر + كيبوكس سليم)."
        say "   • لا تكرّر الفحص باستمرار — انتظر 10-15 دقيقة (جوجل تعطي خطأ مؤقتاً عند الإفراط)."
    fi

    date '+%Y-%m-%d %H:%M:%S' > "$MARKER" 2>/dev/null
else
    say ""
    say "✖ فشل تنفيذ الأداة (رمز الخروج: $RC)."
    if [ "$MODE" != "auto" ]; then
        say "  تحقق من: جهاز Red Magic بروم أصلي + اتصال إنترنت + حساب جوجل نشط."
    fi
    # 🔄 (v3.04) لا نكتب علامة النجاح عند الفشل — نكتفي بحد المحاولات حتى يستطيع
    #    المستخدم إعادة المحاولة بعد إصلاح السبب (كوايرن/إنترنت/روم أصلي).
    if [ "$MODE" = "auto" ]; then
        FAILS=0
        [ -f "$FALCON_DIR/rkp_fix_fail" ] && FAILS=$(cat "$FALCON_DIR/rkp_fix_fail" 2>/dev/null)
        case "$FAILS" in ''|*[!0-9]*) FAILS=0 ;; esac
        FAILS=$((FAILS + 1))
        echo "$FAILS" > "$FALCON_DIR/rkp_fix_fail" 2>/dev/null
        if [ "$FAILS" -ge 3 ]; then
            say "ℹ️ توقفت المحاولة التلقائية بعد $FAILS محاولات فاشلة — استخدم الزر اليدوي."
            date '+%Y-%m-%d %H:%M:%S' > "$MARKER" 2>/dev/null
        else
            say "🔄 المحاولة رقم $FAILS من 3 — ستُعاد تلقائياً في الإقلاع القادم."
        fi
    fi
fi

say "════════ انتهى التقرير ════════"
exit 0
