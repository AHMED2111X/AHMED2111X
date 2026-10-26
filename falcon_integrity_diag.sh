#!/system/bin/sh
# ==============================================================================
# FALCON INTEGRITY FIX - تشخيص شامل لتوافق Play Integrity
# المطور: ABUFARID | تليجرام: @FALCON_KERNEL
# ==============================================================================
#
# لماذا هذا السكربت؟
#   عندما تكون الخصائص سليمة والمحرك يعمل لكن الفحص يبقى "أخضر واحد"
#   ⇒ السبب ليس في الخصائص بل في سلسلة التحقّق من العتاد (Key Attestation):
#      ├ هل الكيبوكس استُورد فعلاً إلى TEE/keystore2  (مجلد keys)؟
#      ├ هل تم حقن المكتبة داخل عملية keystore2      (maps)؟
#      ├ هل الكيبوكس مُبطَل لدى جوجل                   (CRL)؟
#      ├ هل قائمة الحمايات تغطي التطبيق الذي يفحص      (target.txt)؟
#      └ هل حالة RKP على الجهاز سليمة                  (hardware attestation)؟
#
# ⛔ الوضع diag: قراءة فقط — لا يكتب أي شيء.
# ⛔ الوضع fix : إعادة تطبيق آمنة فقط (لا حذف، لا مساس بالكيبوكس الأساسي).
#
# الاستخدام:
#   sh falcon_integrity_diag.sh diag    # تقرير كامل
#   sh falcon_integrity_diag.sh fix     # إعادة تطبيق آمنة + إعادة تشغيل GMS
# ==============================================================================

MODDIR="/data/adb/modules/playintegrityfix"
if [ ! -f "$MODDIR/custom.pif.prop" ]; then
    _SD="${0%/*}"
    [ -n "$_SD" ] && [ -f "$_SD/custom.pif.prop" ] && MODDIR="$_SD"
fi
TS_DIR="/data/adb/tricky_store"
FALCON_DIR="/data/adb/falcon"
OUT="/data/adb/falcon/integrity_diag.txt"

line() { echo "------------------------------------------------------------"; }
ok()   { echo "  [OK]   $1"; }
bad()  { echo "  [FAIL] $1"; }
warn() { echo "  [WARN] $1"; }

gp() { getprop "$1" 2>/dev/null; }

# هل الحزمة مذكورة في target.txt ؟ (يتحمل BOM و CRLF والرموز الزائدة)
in_target() {
    [ -s "$TS_DIR/target.txt" ] || return 1
    awk -v p="$1" '{ gsub(/\r/,""); sub(/^\xef\xbb\xbf/,""); if ($0 == p) { found=1 } } END { exit(found?0:1) }' \
        "$TS_DIR/target.txt" 2>/dev/null
}

# ---------------------------------------------------------------- 1) المحرك
diag_engine() {
    echo "== 1) محرك التعتيد (Tricky Store OSS) =="
    local pid
    pid="$(pidof TrickyStoreOSS 2>/dev/null)"
    if [ -n "$pid" ]; then ok "المحرك يعمل (pid=$pid)"; else bad "المحرك لا يعمل — TrickyStoreOSS غير موجود"; fi

    # هل حُقنت المكتبة داخل keystore2 ؟ (هذا ما يجعل العتاد يُوقَّع بالكيبوكس)
    local injected=0 ks_pid
    for ks_pid in $(pidof keystore2 2>/dev/null); do
        if grep -qiE "libTrickyStore|libinject" "/proc/$ks_pid/maps" 2>/dev/null; then
            injected=1
            ok "المكتبة محقونة داخل keystore2 (pid=$ks_pid)"
        fi
    done
    if [ "$injected" = "0" ]; then
        if [ -n "$(pidof keystore2 2>/dev/null)" ]; then
            bad "keystore2 يعمل لكن بلا حقن مكتبة التعتيد ⇒ العتاد لا يُوقَّع بالكيبوكس"
        else
            warn "لم يُعثر على عملية keystore2 (قد يكون الاسم مختلفاً على هذا الجهاز)"
        fi
    fi

    if [ -f /data/adb/falcon_daemon.log ]; then
        echo "  --- آخر أسطر سجل المحرك ---"
        tail -n 12 /data/adb/falcon_daemon.log 2>/dev/null | sed 's/^/    /'
    fi
    line
}

# ------------------------------------------------------- 2) الكيبوكس في TEE
diag_keybox() {
    echo "== 2) الكيبوكس وحالته داخل TEE =="
    if [ -s "$TS_DIR/keybox.xml" ]; then
        ok "الكيبوكس النشط موجود ($TS_DIR/keybox.xml)"
        local certs
        certs="$(grep -c 'BEGIN CERTIFICATE' "$TS_DIR/keybox.xml" 2>/dev/null)"
        echo "         عدد الشهادات: $certs"
        grep -o 'DeviceID="[^"]*"' "$TS_DIR/keybox.xml" 2>/dev/null | head -n 1 | sed 's/^/         /'
    else
        bad "لا يوجد كيبوكس نشط في $TS_DIR/keybox.xml"
    fi

    # ⭐ الأهم: هل استُورد المفتاح إلى keystore2 فعلاً؟
    if [ -d "$TS_DIR/keys" ]; then
        local n
        n="$(ls -1 "$TS_DIR/keys" 2>/dev/null | wc -l)"
        if [ "$n" -gt 0 ]; then
            ok "مجلد keys يحتوي $n عنصر ⇒ المفتاح مستورد في keystore2"
            ls -l "$TS_DIR/keys" 2>/dev/null | head -n 6 | sed 's/^/         /'
        else
            bad "مجلد keys موجود لكنه فارغ ⇒ لم يُستورد المفتاح بعد (سبب شائع لفشل MEETS_DEVICE_INTEGRITY)"
        fi
    else
        bad "لا يوجد مجلد $TS_DIR/keys ⇒ المفتاح غير مستورد في TEE — هذا غالباً سبب الفشل"
    fi

    for F in boot_key hbk; do
        if [ -e "$TS_DIR/$F" ]; then
            ok "$TS_DIR/$F موجود ($(wc -c < "$TS_DIR/$F" 2>/dev/null | tr -d ' ') بايت)"
        else
            warn "$TS_DIR/$F غير موجود"
        fi
    done

    # هل الكيبوكس النشط هو نفسه المرفق مع الإضافة؟ (المفتاح العلني معرض للإبطال)
    local bundled="$MODDIR/keybox.xml"
    if [ -s "$bundled" ] && [ -s "$TS_DIR/keybox.xml" ]; then
        if cmp -s "$TS_DIR/keybox.xml" "$bundled" 2>/dev/null; then
            warn "الكيبوكس النشط = الكيبوكس المرفق مع الإضافة (مفتاح علني ⇒ معرض للإبطال)"
        else
            ok "الكيبوكس النشط مخصّص (ليس نسخة من المرفق)"
        fi
    fi

    # حالة الإبطال من محرك المزامنة
    if [ -s "$FALCON_DIR/../falcon_keysync/kb_state" ]; then
        echo "  --- حالة فحص الإبطال (CRL) ---"
        head -n 3 "$FALCON_DIR/../falcon_keysync/kb_state" 2>/dev/null | sed 's/^/         /'
    fi
    if [ -s "$FALCON_DIR/keysync/kb_state" ]; then
        echo "  --- حالة فحص الإبطال (CRL) ---"
        head -n 3 "$FALCON_DIR/keysync/kb_state" 2>/dev/null | sed 's/^/         /'
    fi
    line
}

# ------------------------------------------------------- 3) قوائم الحمايات
diag_target() {
    echo "== 3) قائمة الحمايات (target.txt) =="
    if [ -s "$TS_DIR/target.txt" ]; then
        local n
        n="$(grep -c . "$TS_DIR/target.txt" 2>/dev/null)"
        ok "target.txt يحتوي $n حزمة"
        for P in com.google.android.gms com.google.android.gms.unstable com.android.vending; do
            if in_target "$P"; then
                ok "مغطّى: $P"
            else
                bad "غير مغطّى: $P  ⇒ التطبيق غير مموَّه"
            fi
        done
    else
        bad "لا يوجد target.txt"
    fi
    if [ -s "$TS_DIR/security_patch.txt" ]; then
        echo "  --- security_patch.txt ---"
        cat "$TS_DIR/security_patch.txt" 2>/dev/null | sed 's/^/         /'
    fi
    line
}

# ------------------------------------------------------------- 4) الخصائص
diag_props() {
    echo "== 4) خصائص السلامة (ما يقرأه جوجل) =="
    for P in ro.build.tags ro.build.type ro.build.fingerprint ro.build.version.security_patch \
             ro.build.version.incremental ro.build.id ro.debuggable ro.secure ro.adb.secure \
             ro.build.version.sdk ro.build.version.release ro.build.version.release_or_codename \
             ro.product.model ro.product.brand ro.product.name ro.product.device \
             ro.boot.verifiedbootstate ro.boot.flash.locked ro.boot.vbmeta.device_state \
             ro.boot.veritymode ro.boot.selinux ro.boot.warranty_bit ro.boot.mode \
             ro.system.build.fingerprint ro.vendor.build.fingerprint ro.odm.build.fingerprint \
             ro.system.build.tags ro.vendor.build.tags ro.odm.build.tags; do
        printf "  %-38s = %s\n" "$P" "$(gp "$P")"
    done
    line
}

# ------------------------------------------- 4.5) إعدادات PIF كما يراها المحرك
diag_pif() {
    echo "== 4.5) إعدادات PIF كما يقرأها محرك Zygisk =="
    for F in custom.pif.json custom.pif.prop pif.prop; do
        if [ -s "$MODDIR/$F" ]; then
            echo "  --- $MODDIR/$F ---"
            grep -E 'FINGERPRINT|"\*api_level"|^\*api_level|DEVICE_INITIAL_SDK_INT|"RELEASE"|^RELEASE=|^SECURITY_PATCH|"SECURITY_PATCH"' \
                "$MODDIR/$F" 2>/dev/null | head -n 8 | sed 's/^/         /'
        fi
    done
    echo "  ⚠️  قيمة *api_level هي ro.build.version.sdk الذي يراه جوجل."
    echo "     إن كانت 32 (أندرويد 12L) وبصمة Canary 2026 ⇒ تناقض يكشفه الفحص."
    line
}

# ------------------------------------------------------------ 5) الزيجيسك
diag_zygisk() {
    echo "== 5) محرّك التمويه (Zygisk + PIF) =="
    local found=0 pid
    for pid in $(pidof zygote zygote64 2>/dev/null); do
        grep -qiE "zygisk" "/proc/$pid/maps" 2>/dev/null && found=1
    done
    if [ "$found" = "1" ]; then ok "Zygisk محمّل في العملية"; else warn "لا يُرى Zygisk في خرائط العمليات"; fi

    for F in classes.dex custom.pif.prop custom.pif.json pif.prop; do
        if [ -s "$MODDIR/$F" ]; then ok "ملف PIF موجود: $MODDIR/$F"; else bad "ملف PIF مفقود: $F"; fi
    done
    echo "         البصمة المموَّهة: $(grep -m1 '^FINGERPRINT=' "$MODDIR/custom.pif.prop" 2>/dev/null | cut -d= -f2-)"
    line
}

# ------------------------------------------------------------------ 6) RKP
diag_rkp() {
    echo "== 6) التحقّق من العتاد (RKP / Hardware Attestation) =="
    if [ -x /vendor/bin/KmInstallKeybox ]; then
        ok "أداة KmInstallKeybox موجودة (جهاز يدعم RKP)"
    else
        warn "لا توجد أداة KmInstallKeybox (جهاز بدون RKP ⇒ DEVICE_STRONG غير متوقع)"
    fi
    if command -v cmd >/dev/null 2>&1; then
        echo "  --- مفاتيح RKP ---"
        timeout 20 cmd remote_provisioning list 2>&1 | head -n 10 | sed 's/^/         /'
    fi
    line
}

# -------------------------------------------------------------- 7) الخلاصة
diag_verdict() {
    echo "== 7) التشخيص =="
    local keys_ok=0 inj=0 tss=0 tgt=0

    [ -d "$TS_DIR/keys" ] && [ -n "$(ls -1 "$TS_DIR/keys" 2>/dev/null)" ] && keys_ok=1
    local kp; kp="$(pidof keystore2 2>/dev/null)"
    for kp in $(pidof keystore2 2>/dev/null); do
        grep -qiE "libTrickyStore|libinject" "/proc/$kp/maps" 2>/dev/null && inj=1
    done
    [ "$(gp ro.build.tags)" = "release-keys" ] && tss=1
    grep -qx "com.google.android.gms" "$TS_DIR/target.txt" 2>/dev/null && tgt=1

    echo "  استيراد المفتاح إلى TEE : $([ $keys_ok = 1 ] && echo '✔' || echo '✘')"
    echo "  حقن المكتبة في keystore2 : $([ $inj = 1 ] && echo '✔' || echo '✘')"
    echo "  وسوم بناء نظيفة         : $([ $tss = 1 ] && echo '✔' || echo '✘')"
    echo "  تغطية GMS في target.txt : $([ $tgt = 1 ] && echo '✔' || echo '✘')"
    echo "  --------------------------------------------"
    if [ $keys_ok = 0 ]; then
        echo "  ⭐ السبب الأرجح: المفتاح غير مستورد في keystore2."
        echo "     الحل: شغّل  sh $0 fix  ثم أعد تشغيل الجهاز."
    elif [ $inj = 0 ]; then
        echo "  ⭐ السبب الأرجح: المحرك يعمل لكن الحقن داخل keystore2 لم يتم."
        echo "     الحل: تأكد أن Zygisk مفعّل، ثم شغّل  sh $0 fix  وأعد التشغيل."
    elif [ $tss = 0 ]; then
        echo "  ⭐ السبب الأرجح: وسوم البناء ما زالت reveal للروم المعدّل."
        echo "     الحل: شغّل  sh $0 fix  ثم أعد التشغيل."
    elif [ $tgt = 0 ]; then
        echo "  ⭐ السبب الأرجح: التطبيق الذي يفحص غير مغطّى في target.txt."
        echo "     الحل: شغّل  sh $0 fix  ثم أعد تشغيل Google Play Services."
    else
        echo "  ✅ كل المكوّنات seemingly سليمة."
        echo "     ⇒ إن بقي الفحص أخضر واحداً فغالباً السبب:"
        echo "       • الكيبوكس مُبطَل لدى جوجل (شغّل kb_sync.sh --now)"
        echo "       • الجهاز يتطلّب RKPProvision لمفتاح العتاد (شغّل rkp_fix.sh)"
        echo "       • التطبيق المُفحص يُشغَّل من متجر Play بإصدار غير مموَّه"
    fi
    line
}

do_diag() {
    {
        echo "============================================================"
        echo " FALCON INTEGRITY FIX — تشخيص Play Integrity"
        echo " $(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null)"
        echo "============================================================"
        diag_engine
        diag_keybox
        diag_target
        diag_props
        diag_pif
        diag_zygisk
        diag_rkp
        diag_verdict
    } | tee "$OUT"
    echo ""
    echo "تم حفظ التقرير في: $OUT"
}

do_fix() {
    echo "== إعادة تطبيق آمنة =="
    mkdir -p "$TS_DIR" 2>/dev/null

    # 1) قوائم الحمايات: كل الحزم المثبتة
    if command -v pm >/dev/null 2>&1; then
        pm list packages 2>/dev/null | sed 's/^package://' > "$TS_DIR/.falcon_all.tmp" 2>/dev/null
        if [ -s "$TS_DIR/.falcon_all.tmp" ]; then
            cat "$TS_DIR/target.txt" 2>/dev/null >> "$TS_DIR/.falcon_all.tmp"
            sort -u "$TS_DIR/.falcon_all.tmp" | grep -c . > "$TS_DIR/.falcon_cnt.tmp" 2>/dev/null
            mv -f "$TS_DIR/.falcon_all.tmp" "$TS_DIR/target.txt" 2>/dev/null
            rm -f "$TS_DIR/.falcon_cnt.tmp" 2>/dev/null
            ok "target.txt مُحدَّث ($(grep -c . "$TS_DIR/target.txt" 2>/dev/null) حزمة)"
        fi
    else
        warn "pm غير متاح — لم تُحدَّث قوائم الحمايات"
    fi

    # 2) طبقة توافق الرومات
    if [ -f "$MODDIR/falcon_rom_compat.sh" ]; then
        sh "$MODDIR/falcon_rom_compat.sh" apply >/dev/null 2>&1
        ok "طُبِّقت طبقة توافق الرومات"
    fi

    # 3) مدير المنفذين (يعيد كتابة الكيبوكس النشط من الأساسي/الثانوي)
    if [ -f "$MODDIR/falcon_keybox.sh" ]; then
        sh "$MODDIR/falcon_keybox.sh" sync --force >/dev/null 2>&1
        ok "أُعيد تطبيق الكيبوكس النشط"
    fi

    # 4) إعادة تشغيل خدمات جوجل (تستعمل البصمة والكيبوكس من جديد)
    if [ -f "$MODDIR/killpi.sh" ]; then
        sh "$MODDIR/killpi.sh" >/dev/null 2>&1
        ok "أُعيد تشغيل Google Play Services"
    else
        killall -9 com.google.android.gms.unstable com.android.vending 2>/dev/null
        ok "أُعيد تشغيل خدمات جوجل"
    fi
    echo ""
    echo "⚠️  أعد تشغيل الجهاز ثم شغّل:  sh $0 diag"
}

# ------------------------------------------- 8) تعديل مستوى API (تجربة سريعة)
# ⛔ لا يحذف شيئاً: نسخة احتياطية لكل ملف قبل التعديل + أمر استرجاع.
# هذا يغيّر ro.build.version.sdk الذي يعلنه محرك PIF — وهو أهم مرشّح
# لخلل «أخضر واحد» عندما تكون البصمة Canary حديثة و *api_level قديمة.
apilevel() {
    _v="$1"
    if [ -z "$_v" ]; then
        echo "الاستخدام: sh $0 apilevel <30..37>   |   sh $0 apilevel reset"
        exit 1
    fi

    if [ "$_v" = "reset" ]; then
        for F in custom.pif.prop custom.pif.json; do
            [ -f "$MODDIR/$F.bak-apilevel" ] || continue
            cp -f "$MODDIR/$F.bak-apilevel" "$MODDIR/$F" 2>/dev/null
            echo "✔ استُعيد $F"
        done
        restart_gms
        echo "↩️  أُعيد تشغيل خدمات جوجل — أعد فحص Play Integrity"
        return 0
    fi

    case "$_v" in
        ''|*[!0-9]*) echo "✖ قيمة غير صالحة: $_v" ; return 1 ;;
    esac
    if [ "$_v" -lt 26 ] 2>/dev/null || [ "$_v" -gt 40 ] 2>/dev/null; then
        echo "✖ القيمة يجب أن تكون بين 26 و 40" ; return 1
    fi

    for F in custom.pif.prop custom.pif.json; do
        [ -f "$MODDIR/$F" ] || continue
        [ -f "$MODDIR/$F.bak-apilevel" ] || cp -f "$MODDIR/$F" "$MODDIR/$F.bak-apilevel" 2>/dev/null
    done

    # ملف الخصائص (مصدر الحقيقة)
    if [ -f "$MODDIR/custom.pif.prop" ]; then
        if grep -q '^\*api_level=' "$MODDIR/custom.pif.prop" 2>/dev/null; then
            sed -i "s|^\*api_level=.*|*api_level=$_v|" "$MODDIR/custom.pif.prop" 2>/dev/null
        else
            echo "*api_level=$_v" >> "$MODDIR/custom.pif.prop" 2>/dev/null
        fi
        ok "custom.pif.prop → *api_level=$_v"
    fi

    # ⭐ إعادة توليد custom.pif.json عبر سكربت المشروع نفسه (أضمن طريقة)
    if [ -f "$MODDIR/apply_pif.sh" ]; then
        sh "$MODDIR/apply_pif.sh" force >/dev/null 2>&1
        ok "أُعيد توليد بصمة PIF (custom.pif.json) من ملف الخصائص"
    fi

    # ⭐ احتياطي: كتابة مباشرة للـJSON بطريقة awk (أضمن من sed على كلBusyBox)
    if [ -f "$MODDIR/custom.pif.json" ]; then
        json_set_apilevel "$MODDIR/custom.pif.json" "$_v"
    fi

    # تحقّق: هل تغيّر الرقم في JSON فعلاً؟
    if [ -f "$MODDIR/custom.pif.json" ]; then
        _cur="$(grep -m1 'api_level' "$MODDIR/custom.pif.json" 2>/dev/null | tr -dc '0-9')"
        if [ "$_cur" = "$_v" ]; then
            ok "JSON مؤكَّد: *api_level=$_cur"
        else
            warn "JSON ما زال يعرض ($_cur) — تحقّق يدوياً"
        fi
    fi

    restart_gms
    echo ""
    echo "✅ تم الضبط على api_level=$_v — أعد فحص Play Integrity الآن."
    echo "   للرجوع: sh $0 apilevel reset"
}

restart_gms() {
    if [ -f "$MODDIR/killpi.sh" ]; then
        sh "$MODDIR/killpi.sh" >/dev/null 2>&1
    else
        killall -9 com.google.android.gms.unstable com.android.vending 2>/dev/null
    fi
}

# ⭐ كتابة قيمة *api_level داخل ملف JSON بطريقة awk (مضمونة على كل BusyBox)
# السطر الهدف:     "*api_level": "32",
# بعد التقسيم بـ ":  [1]="    " [2]="*api_level" [3]=": " [4]="32" [5]=","
json_set_apilevel() {
    _jf="$1"
    _jv="$2"
    [ -f "$_jf" ] || return 0
    awk -v v="$_jv" '
        index($0, "api_level") > 0 {
            c = ($0 ~ /,[[:space:]]*$/) ? "," : ""
            print "    \"*api_level\": \"" v "\"" c
            next
        }
        { print }
    ' "$_jf" > "$_jf.tmp" 2>/dev/null && mv -f "$_jf.tmp" "$_jf" 2>/dev/null
    rm -f "$_jf.tmp" 2>/dev/null
}

case "${1:-diag}" in
    diag) do_diag ;;
    fix)  do_fix ;;
    apilevel) apilevel "$2" ;;
    *)    echo "الاستخدام: sh $0 {diag|fix|apilevel <30..37|reset>}" ; exit 1 ;;
esac

exit 0
