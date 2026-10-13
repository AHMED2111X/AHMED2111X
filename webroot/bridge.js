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
        cmds.push('KB=$(find /sdcard /storage /storage/emulated /storage/emulated/0 /data/media/0 2>/dev/null -name "keybox.xml" -type f | head -n 1); if [ -n "$KB" ]; then cp "$KB" /data/adb/tricky_store/keybox.xml; fi');
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
        const full = cmds.join(' && ');
        shell(full, { root: true }, function(r) {
            if (callback) callback(r || {});
        });
    }
};