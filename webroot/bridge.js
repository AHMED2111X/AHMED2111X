const API = {
    getStatus: function(callback) {
        const cmds = [];
        cmds.push('[ -f /data/adb/falcon_active_spoof ] && echo ACTIVE || echo INACTIVE');
        cmds.push('cat /data/adb/falcon/applied_identity.json 2>/dev/null | head -c 200');
        cmds.push('cat /data/adb/tricky_store/target.txt 2>/dev/null');
        const full = cmds.join('; ');
        shell(full, { root: true }, function(r) {
            if (callback) callback(r || {});
        });
    },

    getRealUserCount: function(callback) {
        shell('echo "0"', { root: true }, function(r) {
            if (callback) callback(r || {});
        });
    },

    fetchKeybox: function(callback) {
        const cmds = [];
        cmds.push('mkdir -p /data/adb/tricky_store');
        cmds.push('rm -f /data/adb/tricky_store/keybox.xml');
        cmds.push('rm -f /data/adb/tricky_store/keybox.xml.bak');
        cmds.push('rm -f /data/adb/tricky_store/keybox.xml.backup');
        cmds.push('rm -f /data/adb/tricky_store/keybox.xml.old');
        cmds.push('rm -f /data/adb/tricky_store/keybox.xml.tmp');
        cmds.push('curl -L -o /data/adb/tricky_store/keybox.xml "https://github.com/AHMED2111X/AHMED2111X/raw/main/keybox.xml" 2>/dev/null || wget -O /data/adb/tricky_store/keybox.xml "https://github.com/AHMED2111X/AHMED2111X/raw/main/keybox.xml" 2>/dev/null');
        cmds.push('chmod 644 /data/adb/tricky_store/keybox.xml 2>/dev/null');
        const full = cmds.join(' && ');
        shell(full, { root: true }, function(r) {
            if (callback) callback(r || {});
        });
    },

    installLocalKeyboxDevice: function(callback) {
        const cmds = [];
        cmds.push('mkdir -p /data/adb/tricky_store');
        cmds.push('rm -f /data/adb/tricky_store/keybox.xml');
        cmds.push('rm -f /data/adb/tricky_store/keybox.xml.bak');
        cmds.push('rm -f /data/adb/tricky_store/keybox.xml.backup');
        cmds.push('rm -f /data/adb/tricky_store/keybox.xml.old');
        cmds.push('rm -f /data/adb/tricky_store/keybox.xml.tmp');
        cmds.push('KB=$(find /sdcard /storage /storage/emulated /storage/emulated/0 /data/media/0 /mnt/media_rw 2>/dev/null -name "keybox.xml" -type f | head -n 1); if [ -n "$KB" ]; then cp "$KB" /data/adb/tricky_store/keybox.xml; fi');
        cmds.push('chmod 644 /data/adb/tricky_store/keybox.xml 2>/dev/null');
        const full = cmds.join(' && ');
        shell(full, { root: true }, function(r) {
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
        const full = cmds.join(' && ');
        shell(full, { root: true }, function(r) {
            if (callback) callback(r || {});
        });
    },

    rkpDiagnose: function(callback) {
        const cmds = [];
        cmds.push('echo "=== وحدات Remote Key Provisioning المتوفرة ==="');
        cmds.push('cmd remote_provisioning list 2>&1');
        cmds.push('echo "=== فحص إصدار شهادة التحقق من TEE ==="');
        cmds.push('cmd remote_provisioning certify default 2>&1 | head -c 600');
        cmds.push('echo ""');
        cmds.push('echo "=== وجود أداة ZTE لإصلاح المفاتيح ==="');
        cmds.push('ls -l /vendor/bin/KmInstallKeybox 2>&1');
        const full = cmds.join('; ');
        shell(full, { root: true }, function(r) {
            if (callback) callback(r || {});
        });
    },

    rkpRepair: function(callback) {
        const cmds = [];
        cmds.push('sh /data/adb/modules/playintegrityfix/rkp_fix.sh manual 2>&1');
        const full = cmds.join('; ');
        shell(full, { root: true }, function(r) {
            if (callback) callback(r || {});
        });
    },

    // تنفيذ أمر خام عبر جسر الصدفة (يُستخدم كخيار احتياطي من الواجهة)
    runRaw: function(cmd, callback) {
        shell(cmd, { root: true }, function(r) {
            if (callback) callback(r || {});
        });
    },

    // إعادة تشغيل خدمات جوجل الثلاث ثم إعادة التشغيل (بدون مسح أي بيانات)
    gmsReset: function(callback) {
        const cmds = [];
        cmds.push('sh /data/adb/modules/playintegrityfix/rkp_fix.sh google 2>&1');
        const full = cmds.join('; ');
        shell(full, { root: true }, function(r) {
            if (callback) callback(r || {});
        });
    },

    // الإصلاح الكامل: RKP + إعادة تشغيل GMS (بدون مسح أي بيانات)
    fullRepair: function(callback) {
        shell('sh /data/adb/modules/playintegrityfix/rkp_fix.sh full 2>&1', { root: true }, function(r) {
            if (callback) callback(r || {});
        });
    },

    // تطبيق ملف البصمة (PIF): يحوّل custom.pif.prop → custom.pif.json
    // ويوزّعه على كل المسارات المحتملة (بعض الأجهزة لا تنقل الملف تلقائياً)
    applyPif: function(callback) {
        shell('sh /data/adb/modules/playintegrityfix/apply_pif.sh force 2>&1', { root: true }, function(r) {
            if (callback) callback(r || {});
        });
    }
};
