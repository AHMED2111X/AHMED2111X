// ==============================================================================
// FALCON INTEGRITY FIX — جسر أوامر الواجهة (WebUI Bridge)
// المطور: ABUFARID | تليجرام: @FALCON_KERNEL
//
// 🛡️ قاعدة إلزامية: كل أمر هنا مُغلَّف بـ timeout حتى لا يعلّق الجهاز أبداً.
//    السبب: أوامر الشبكة (curl) و RKP (remote_provisioning) والتشغيل اليدوي
//    للمحرك كانت قادرة على تجميد keystore2 / الواجهة بالكامل.
// ==============================================================================

const FALCON_BRIDGE_TIMEOUT = 90; // ثانية (الافتراضي)

// تغليف آمن بـ timeout عبر /system/bin/sh -c مع تهريب علامة الاقتباس المفردة
function _fw(cmd, seconds) {
    const t = seconds || FALCON_BRIDGE_TIMEOUT;
    const safe = String(cmd).replace(/'/g, "'\\''");
    return "timeout " + t + " sh -c '" + safe + "'";
}

const API = {
    getStatus: function(callback) {
        const cmds = [];
        cmds.push('[ -f /data/adb/falcon_active_spoof ] && echo ACTIVE || echo INACTIVE');
        cmds.push('cat /data/adb/falcon/applied_identity.json 2>/dev/null | head -c 200');
        cmds.push('cat /data/adb/tricky_store/target.txt 2>/dev/null');
        shell(_fw(cmds.join('; '), 25), { root: true }, function(r) {
            if (callback) callback(r || {});
        });
    },

    getRealUserCount: function(callback) {
        shell(_fw('echo "0"', 15), { root: true }, function(r) {
            if (callback) callback(r || {});
        });
    },

    fetchKeybox: function(callback) {
        const KBURL = 'https://github.com/AHMED2111X/AHMED2111X/raw/main/keybox.xml';
        const cmds = [];
        cmds.push('mkdir -p /data/adb/tricky_store /data/adb/falcon');
        cmds.push('TMP=/data/adb/falcon/keybox.new.xml; rm -f "$TMP"');
        // مهلة صارمة للشبكة: لا يمكن أن تعلّق الواجهة إن انقطع الإنترنت
        cmds.push('curl -L --connect-timeout 10 --max-time 60 -o "$TMP" "' + KBURL + '" 2>/dev/null || wget -T 15 -O "$TMP" "' + KBURL + '" 2>/dev/null');
        // 🔑 (v3.04) لا نُثبّت إلا ملفاً صالحاً، ونثبّته في مسار المستخدم الدائم
        //     /data/adb/falcon/keybox.xml  + مسار المحرك معاً، فيبقى بعد إعادة التشغيل.
        cmds.push('if [ -s "$TMP" ] && grep -q "<AndroidAttestation" "$TMP" 2>/dev/null; then cp -f "$TMP" /data/adb/falcon/keybox.xml && cp -f "$TMP" /data/adb/tricky_store/keybox.xml && chmod 644 /data/adb/falcon/keybox.xml /data/adb/tricky_store/keybox.xml && chown root:root /data/adb/falcon/keybox.xml /data/adb/tricky_store/keybox.xml && rm -f "$TMP" && echo "OK: تم تنزيل الكيبوكس وتثبيته بشكل دائم"; else rm -f "$TMP"; echo "FAIL: فشل التنزيل أو أن الملف غير صالح"; fi');
        shell(_fw(cmds.join(' && '), 90), { root: true }, function(r) {
            if (callback) callback(r || {});
        });
    },

    installLocalKeyboxDevice: function(callback) {
        const cmds = [];
        cmds.push('mkdir -p /data/adb/tricky_store /data/adb/falcon');
        // بحث محدود العمق + مهلة: البحث الواسع كان يعلّق الواجهة على التخزين الكبير
        // 🔑 (v3.04) يُثبَّت الملف في مسار المستخدم الدائم أيضاً حتى لا يُستبدل عند الإقلاع
        cmds.push('KB=$(timeout 25 find /sdcard /storage/emulated/0 /data/media/0 -maxdepth 5 -name "keybox.xml" -type f 2>/dev/null | head -n 1); if [ -n "$KB" ] && grep -q "<AndroidAttestation" "$KB" 2>/dev/null; then cp -f "$KB" /data/adb/falcon/keybox.xml && cp -f "$KB" /data/adb/tricky_store/keybox.xml && chmod 644 /data/adb/falcon/keybox.xml /data/adb/tricky_store/keybox.xml && chown root:root /data/adb/falcon/keybox.xml /data/adb/tricky_store/keybox.xml && echo "OK: تم تثبيت $KB بشكل دائم"; elif [ -n "$KB" ]; then echo "FAIL: الملف $KB غير صالح (لا يحتوي AndroidAttestation)"; else echo "FAIL: لم يُعثر على keybox.xml"; fi');
        shell(_fw(cmds.join(' && '), 60), { root: true }, function(r) {
            if (callback) callback(r || {});
        });
    },

    deleteKeybox: function(callback) {
        const cmds = [];
        cmds.push('rm -f /data/adb/tricky_store/keybox.xml');
        cmds.push('rm -f /data/adb/tricky_store/keybox.xml.bak');
        cmds.push('rm -f /data/adb/tricky_store/keybox.xml.backup');
        cmds.push('rm -f /data/adb/tricky_store/keybox.xml.old');
        cmds.push('rm -f /data/adb/tricky_store/keybox.xml.tmp');
        // حذف كيبوكس المستخدم المحفوظ أيضاً وإلا عاد عند الإقلاع
        cmds.push('rm -f /data/adb/falcon/keybox.xml');
        cmds.push('rm -f /data/adb/falcon/keybox_bundled.xml');
        shell(_fw(cmds.join(' && '), 20), { root: true }, function(r) {
            if (callback) callback(r || {});
        });
    },

    rkpDiagnose: function(callback) {
        const cmds = [];
        cmds.push('echo "=== وحدات Remote Key Provisioning المتوفرة ==="');
        cmds.push('timeout 20 cmd remote_provisioning list 2>&1');
        cmds.push('echo "=== فحص إصدار شهادة التحقق من TEE ==="');
        cmds.push('timeout 30 cmd remote_provisioning certify default 2>&1 | head -c 600');
        cmds.push('echo ""');
        cmds.push('echo "=== وجود أداة ZTE لإصلاح المفاتيح ==="');
        cmds.push('ls -l /vendor/bin/KmInstallKeybox 2>&1');
        shell(_fw(cmds.join('; '), 60), { root: true }, function(r) {
            if (callback) callback(r || {});
        });
    },

    rkpRepair: function(callback) {
        shell(_fw('sh /data/adb/modules/playintegrityfix/rkp_fix.sh manual 2>&1', 120), { root: true }, function(r) {
            if (callback) callback(r || {});
        });
    },

    // تنفيذ أمر خام عبر جسر الصدفة (يُستخدم كخيار احتياطي من الواجهة)
    runRaw: function(cmd, callback) {
        shell(_fw(cmd), { root: true }, function(r) {
            if (callback) callback(r || {});
        });
    },

    // إعادة تشغيل خدمات جوجل الثلاث ثم إعادة التشغيل (بدون مسح أي بيانات)
    gmsReset: function(callback) {
        shell(_fw('sh /data/adb/modules/playintegrityfix/rkp_fix.sh google 2>&1', 120), { root: true }, function(r) {
            if (callback) callback(r || {});
        });
    },

    // الإصلاح الكامل: RKP + إعادة تشغيل GMS (بدون مسح أي بيانات)
    fullRepair: function(callback) {
        shell(_fw('sh /data/adb/modules/playintegrityfix/rkp_fix.sh full 2>&1', 150), { root: true }, function(r) {
            if (callback) callback(r || {});
        });
    },

    // تطبيق ملف البصمة (PIF): يحوّل custom.pif.prop → custom.pif.json
    // ويوزّعه على كل المسارات المحتملة (بعض الأجهزة لا تنقل الملف تلقائياً)
    applyPif: function(callback) {
        shell(_fw('sh /data/adb/modules/playintegrityfix/apply_pif.sh force 2>&1', 90), { root: true }, function(r) {
            if (callback) callback(r || {});
        });
    }
};
