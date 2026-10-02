(function(global) {
    'use strict';

    // رابط الكيبوكس الثابت الخاص بك (محمي ومثبت برمجياً)
    const FIXED_KEYBOX_URL = "https://raw.githubusercontent.com/AHMED2111X/AHMED2111X/main/keybox.xml";

    // 1. خوارزميات توليد أرقام ومعرفات عشوائية
    function generateIMEI() {
        let imei = "35" + Math.floor(Math.random() * 1000000000000).toString().padStart(12, '0');
        let sum = 0;
        for (let i = 0; i < 14; i++) {
            let digit = parseInt(imei.charAt(i));
            if (i % 2 !== 0) {
                digit *= 2;
                if (digit > 9) digit -= 9;
            }
            sum += digit;
        }
        let checkDigit = (10 - (sum % 10)) % 10;
        return imei + checkDigit;
    }

    function generateMEID() {
        const chars = "0123456789ABCDEF";
        let meid = "A10000";
        for (let i = 0; i < 8; i++) {
            meid += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        return meid;
    }

    function generateIMSI() {
        return "310260" + Math.floor(Math.random() * 1000000009).toString().padStart(9, '0');
    }

    function generateICCID() {
        return "89014103211" + Math.floor(Math.random() * 1000000008).toString().padStart(8, '0');
    }

    function generatePhone() {
        return "+1202" + Math.floor(Math.random() * 10000000).toString().padStart(7, '0');
    }

    function generateSerial() {
        const chars = "0123456789ABCDEF";
        let serial = "";
        for (let i = 0; i < 12; i++) {
            serial += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        return serial;
    }

    // 2. ربط أزرار Random الفردية
    global.randomizeField = function(elementId, type) {
        const el = document.getElementById(elementId);
        if (!el) return;

        switch (type) {
            case 'imei': el.value = generateIMEI(); break;
            case 'meid': el.value = generateMEID(); break;
            case 'imsi': el.value = generateIMSI(); break;
            case 'iccid': el.value = generateICCID(); break;
            case 'phone': el.value = generatePhone(); break;
            case 'serial': el.value = generateSerial(); break;
            case 'simCount': el.value = Math.floor(Math.random() * 2) + 1; break;
            case 'camCount': el.value = Math.floor(Math.random() * 4) + 1; break;
        }
    };

    // 3. Randomize Telephony
    global.randomizeTelephonyOnly = function() {
        global.randomizeField('sim1_imei', 'imei');
        global.randomizeField('sim1_meid', 'meid');
        global.randomizeField('sim1_imsi', 'imsi');
        global.randomizeField('sim1_iccid', 'iccid');
        global.randomizeField('sim1_phone', 'phone');

        global.randomizeField('sim2_imei', 'imei');
        global.randomizeField('sim2_meid', 'meid');
        global.randomizeField('sim2_imsi', 'imsi');
        global.randomizeField('sim2_iccid', 'iccid');
        global.randomizeField('sim2_phone', 'phone');
        global.randomizeField('visibleSimCount', 'simCount');
    };

    // 4. Randomize All
    global.randomizeAllTelephonyAndHardware = function() {
        global.randomizeTelephonyOnly();
        global.randomizeField('visibleCameraCount', 'camCount');
        global.randomizeField('deviceSerial', 'serial');
    };

    // 5. Clear All
    global.clearAllTelephonyFields = function() {
        const fields = [
            'sim1_imei', 'sim1_meid', 'sim1_imsi', 'sim1_iccid', 'sim1_phone',
            'sim2_imei', 'sim2_meid', 'sim2_imsi', 'sim2_iccid', 'sim2_phone',
            'visibleSimCount', 'visibleCameraCount', 'deviceSerial'
        ];
        fields.forEach(id => {
            const el = document.getElementById(id);
            if (el) el.value = '';
        });
    };

    // 6. تغيير اللغة والاتجاه (RTL / LTR)
    global.changeLanguage = function(langCode) {
        const html = document.documentElement;
        if (langCode === 'ar') {
            html.setAttribute('dir', 'rtl');
            html.setAttribute('lang', 'ar');
        } else {
            html.setAttribute('dir', 'ltr');
            html.setAttribute('lang', langCode);
        }
        localStorage.setItem('falcon_lang', langCode);
    };

    // 7. إدارة القوالب
    const templates = {
        'pixel_10_pro': { device: 'frankel', manufacturer: 'Google', fingerprint: 'google/frankel/frankel:16/Bakery.250101.001/12800100:user/release-keys' },
        'pixel_9_pro_a16': { device: 'caiman', manufacturer: 'Google', fingerprint: 'google/caiman/caiman:16/BP1A.250301.001/12900200:user/release-keys' },
        'pixel_9_pro': { device: 'caiman', manufacturer: 'Google', fingerprint: 'google/caiman/caiman:15/AP3A.241005.015/12500000:user/release-keys' },
        'pixel_9': { device: 'tokay', manufacturer: 'Google', fingerprint: 'google/tokay/tokay:15/AP3A.241005.015/12500000:user/release-keys' },
        'pixel_8_pro_a15': { device: 'husky', manufacturer: 'Google', fingerprint: 'google/husky/husky:15/AP3A.241005.015/12500000:user/release-keys' },
        'samsung_s25_ultra': { device: 'q3q', manufacturer: 'Samsung', fingerprint: 'samsung/q3q/q3q:15/UP1A.241005.007/S938BXXU1AXA1:user/release-keys' },
        'xiaomi_15_pro': { device: 'haotian', manufacturer: 'Xiaomi', fingerprint: 'Xiaomi/haotian/haotian:15/UKQ1.240915.001/V816.0.1.0.VNCCNXM:user/release-keys' },
        'pixel_8_pro': { device: 'husky', manufacturer: 'Google', fingerprint: 'google/husky/husky:14/UD1A.230803.041/10803273:user/release-keys' },
        'pixel_8': { device: 'shiba', manufacturer: 'Google', fingerprint: 'google/shiba/shiba:14/UD1A.230803.041/10803273:user/release-keys' },
        'pixel_7a': { device: 'lynx', manufacturer: 'Google', fingerprint: 'google/lynx/lynx:14/UQ1A.240105.004/11202202:user/release-keys' },
        'pixel_7_pro': { device: 'cheetah', manufacturer: 'Google', fingerprint: 'google/cheetah/cheetah:14/UQ1A.240105.004/11202202:user/release-keys' },
        'samsung_s24_ultra': { device: 'e3q', manufacturer: 'Samsung', fingerprint: 'samsung/e3q/e3q:14/UP1A.231005.007/S928BXXU1AXB5:user/release-keys' },
        'samsung_s23_ultra': { device: 'dm2q', manufacturer: 'Samsung', fingerprint: 'samsung/dm2q/dm2q:14/UP1A.231005.007/S918BXXU3BWJM:user/release-keys' },
        'samsung_s23': { device: 'dm1q', manufacturer: 'Samsung', fingerprint: 'samsung/dm1q/dm1q:14/UP1A.231005.007/S911BXXU3BWJM:user/release-keys' },
        'samsung_a54': { device: 'a54x', manufacturer: 'Samsung', fingerprint: 'samsung/a54x/a54x:14/UP1A.231005.007/A546BXXU6CXB1:user/release-keys' },
        'xiaomi_14_pro': { device: 'shennong', manufacturer: 'Xiaomi', fingerprint: 'Xiaomi/shennong/shennong:14/UKQ1.230804.001/V816.0.5.0.UNCCNXM:user/release-keys' },
        'xiaomi_13_pro': { device: 'nuwa', manufacturer: 'Xiaomi', fingerprint: 'Xiaomi/nuwa/nuwa:14/UKQ1.230804.001/V816.0.4.0.UMBCNXM:user/release-keys' },
        'oneplus_12': { device: 'padd', manufacturer: 'OnePlus', fingerprint: 'OnePlus/OP5B5FL1/padd:14/UKQ1.230924.001/S.1648a31-1-f7611:user/release-keys' },
        'nothing_phone_2': { device: 'pong', manufacturer: 'Nothing', fingerprint: 'Nothing/pong/pong:14/UKQ1.230924.001/240126-1800:user/release-keys' },
        'pixel_4a_a11': { device: 'sunfish', manufacturer: 'Google', fingerprint: 'google/sunfish/sunfish:11/RQ3A.211001.001/7641976:user/release-keys' },
        'pixel_5_a11': { device: 'redfin', manufacturer: 'Google', fingerprint: 'google/redfin/redfin:11/RQ3A.211001.001/7641976:user/release-keys' },
        'samsung_s20_a11': { device: 'x1q', manufacturer: 'Samsung', fingerprint: 'samsung/x1q/x1q:11/RP1A.200720.012/G981BXXU9DUE1:user/release-keys' },
        'xiaomi_mi10_a11': { device: 'umi', manufacturer: 'Xiaomi', fingerprint: 'Xiaomi/umi/umi:11/RKQ1.200826.002/V12.2.8.0.RJBCNXM:user/release-keys' },
        'oneplus_8t_a11': { device: 'kebab', manufacturer: 'OnePlus', fingerprint: 'OnePlus/OnePlus8T/OnePlus8T:11/RKQ1.201022.002/2103221214:user/release-keys' }
    };

    global.randomizeTemplate = function() {
        const keys = Object.keys(templates);
        const randKey = keys[Math.floor(Math.random() * keys.length)];
        const selectEl = document.getElementById('identityTemplateSelect');
        if (selectEl) selectEl.value = randKey;
        applySelectedTemplate(randKey);
    };

    function applySelectedTemplate(key) {
        const devEl = document.getElementById('idDevice');
        const manEl = document.getElementById('idManufacturer');
        const fpEl = document.getElementById('idFingerprint');
        
        if (templates[key]) {
            if (devEl) devEl.value = templates[key].device;
            if (manEl) manEl.value = templates[key].manufacturer;
            if (fpEl) fpEl.value = templates[key].fingerprint;
        } else {
            if (devEl) devEl.value = '';
            if (manEl) manEl.value = '';
            if (fpEl) fpEl.value = '';
        }
    }

    // 8. قوالب الكيرنل الجاهزة
    const kernelPresets = {
        'android16_6_6': { sysname: 'Linux', release: '6.6.21-android16-1-g0123456789' },
        'android15_6_1': { sysname: 'Linux', release: '6.1.75-android15-11-ge4f5678abc' },
        'android14_6_1': { sysname: 'Linux', release: '6.1.25-android14-11-ge4f5678' },
        'android14_5_15': { sysname: 'Linux', release: '5.15.110-android14-11-g8d1a1234' },
        'android13_5_10': { sysname: 'Linux', release: '5.10.168-android13-9-g9a8b7c' },
        'android12_5_10': { sysname: 'Linux', release: '5.10.160-android12-9-g123456' },
        'android11_4_19': { sysname: 'Linux', release: '4.19.191-android11-9-gabcd123' }
    };

    global.applyKernelPreset = function(key) {
        if (kernelPresets[key]) {
            const sysEl = document.getElementById('kernelSysname');
            const relEl = document.getElementById('kernelRelease');
            if (sysEl) sysEl.value = kernelPresets[key].sysname;
            if (relEl) relEl.value = kernelPresets[key].release;
        }
    };

    // 9. إدارة Keybox يدويًا باستخدام الرابط الثابت المحمي
    global.fetchAndInstallKeybox = async function() {
        const targetDir = "/data/adb/tricky_store";
        const targetFile = `${targetDir}/keybox.xml`;

        const cmds = [
            `mkdir -p "${targetDir}"`,
            `curl -sL "${FIXED_KEYBOX_URL}" -o "${targetFile}"`,
            `chmod 644 "${targetFile}"`
        ];

        const fullCommand = cmds.join(" && ");

        try {
            await executeShellCommand(fullCommand);
            alert("✅ Keybox file downloaded and applied successfully!");
        } catch (err) {
            alert("❌ Failed to download or install Keybox file.");
        }
    };

    global.deleteCurrentKeybox = async function() {
        const targetDir = "/data/adb/tricky_store";
        
        const cmds = [
            `rm -f "${targetDir}/keybox.xml"`,
            `rm -f "${targetDir}/keybox.bak"`,
            `rm -f "${targetDir}"/*.tmp`
        ];

        const fullCommand = cmds.join(" && ");

        try {
            await executeShellCommand(fullCommand);
            alert("🗑️ Old Keybox file, Bak file, and temp files deleted successfully!");
        } catch (err) {
            alert("❌ Failed to delete Keybox files.");
        }
    };

    // 10. جلب التطبيقات المثبتة وفحص الحزمة
    global.loadInstalledApps = async function() {
        const selectEl = document.getElementById('installedAppsSelect');
        if (!selectEl) return;

        selectEl.innerHTML = '<option value="">جارٍ تحميل التطبيقات المثبتة...</option>';

        const cmd = `pm list packages -3 | cut -d: -f2 | sort`;
        
        try {
            const output = await executeShellCommand(cmd);
            if (output && output.trim()) {
                const packages = output.trim().split(/\r?\n/);
                selectEl.innerHTML = '<option value="">-- اختر تطبيقاً من القائمة --</option>';
                packages.forEach(pkg => {
                    if (pkg.trim()) {
                        const opt = document.createElement('option');
                        opt.value = pkg.trim();
                        opt.textContent = pkg.trim();
                        selectEl.appendChild(opt);
                    }
                });
            } else {
                selectEl.innerHTML = '<option value="">لم يتم العثور على تطبيقات أو تعذر الجلب</option>';
            }
        } catch (err) {
            selectEl.innerHTML = '<option value="">حدث خطأ أثناء جلب التطبيقات</option>';
        }
    };

    global.onAppSelected = function(pkgName) {
        const inputEl = document.getElementById('appPackageResolve');
        if (inputEl) {
            inputEl.value = pkgName;
        }
        if (pkgName) {
            global.resolveAppPackage();
        }
    };

    global.resolveAppPackage = async function() {
        const pkg = document.getElementById('appPackageResolve')?.value;
        if (!pkg) {
            alert('يرجى اختيار أو كتابة اسم الحزمة أولاً.');
            return;
        }
        const cmd = `falcon_cli resolve_package "${pkg}"`;
        const res = await executeShellCommand(cmd);
        const outputEl = document.getElementById('resolveResultOutput');
        if (outputEl) {
            outputEl.value = res || `Resolved values for ${pkg}:\n- Identity: Active\n- Status: OK`;
        }
    };

    // 11. إدارة البروفايلات (Profiles Management) - دوال التفاعل مع قسم البروفايلات
    global.createNewProfile = async function() {
        const pkg = prompt("أدخل اسم حزمة التطبيق أو الرمز التعبيري (Wildcard):\nمثال: com.example.app أو com.google.*");
        if (!pkg || !pkg.trim()) return;

        const cmd = `falcon_cli profile_add "${pkg.trim()}"`;
        try {
            await executeShellCommand(cmd);
            alert(`✅ تم إنشاء بروفايل جديد للحزمة: ${pkg.trim()}`);
        } catch (err) {
            alert("❌ حدث خطأ أثناء إنشاء البروفايل.");
        }
    };

    global.exportProfiles = async function() {
        try {
            const cmd = `falcon_cli profile_export`;
            const result = await executeShellCommand(cmd);
            
            const blob = new Blob([result || '{}'], { type: 'application/json' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'falcon_profiles.json';
            a.click();
            URL.revokeObjectURL(url);
            alert("✅ تم تصدير البروفايلات بنجاح!");
        } catch (error) {
            alert("❌ فشل تصدير البروفايلات.");
        }
    };

    global.importProfiles = function() {
        const input = document.createElement('input');
        input.type = 'file';
        input.accept = '.json';

        input.onchange = (e) => {
            const file = e.target.files[0];
            if (!file) return;

            const reader = new FileReader();
            reader.onload = async (event) => {
                try {
                    const content = event.target.result;
                    JSON.parse(content); // التحقق من صحة ملف JSON

                    const jsonEscaped = content.replace(/"/g, '\\"');
                    const cmd = `falcon_cli profile_import "${jsonEscaped}"`;
                    await executeShellCommand(cmd);
                    alert("✅ تم استيراد وتطبيق البروفايلات بنجاح!");
                } catch (err) {
                    alert("❌ الملف المرفق غير صالح أو صيغة JSON غير صحيحة.");
                }
            };
            reader.readAsText(file);
        };

        input.click();
    };

    document.addEventListener('DOMContentLoaded', () => {
        const templateSelect = document.getElementById('identityTemplateSelect');
        if (templateSelect) {
            templateSelect.addEventListener('change', (e) => applySelectedTemplate(e.target.value));
        }

        const savedLang = localStorage.getItem('falcon_lang');
        if (savedLang) {
            const langSelect = document.getElementById('appLanguageSelect');
            if (langSelect) langSelect.value = savedLang;
            global.changeLanguage(savedLang);
        }

        setTimeout(() => {
            if (typeof global.loadInstalledApps === 'function') {
                global.loadInstalledApps();
            }
        }, 500);
    });

    global.copyFingerprint = function() {
        const fp = document.getElementById('idFingerprint').value;
        if (fp) {
            navigator.clipboard.writeText(fp);
            alert('Copied fingerprint to clipboard.');
        }
    };

    global.randomizeAllIdentifiers = function() {
        global.randomizeTemplate();
        global.randomizeAllTelephonyAndHardware();
    };

    // 12. تنفيذ الأوامر عبر النظام
    async function executeShellCommand(cmd) {
        if (typeof global.CleveresBridge !== 'undefined' && global.CleveresBridge.execHost) {
            return await global.CleveresBridge.execHost(cmd, 5000);
        } else if (typeof global.ksu !== 'undefined' && global.ksu.exec) {
            return new Promise((resolve) => {
                global.ksu.exec(cmd, (res) => resolve(res));
            });
        } else {
            console.log("Falcon Kernel Command:", cmd);
            return "Command executed successfully.";
        }
    }

    global.applyIdentityManager = async function() {
        const template = document.getElementById('identityTemplateSelect').value;
        const device = document.getElementById('idDevice').value;
        const manufacturer = document.getElementById('idManufacturer').value;
        const fp = document.getElementById('idFingerprint').value;

        const cmd = `falcon_cli set_identity --template "${template}" --device "${device}" --manufacturer "${manufacturer}" --fingerprint "${fp}"`;
        await executeShellCommand(cmd);
        alert('Identity configuration applied successfully.');
    };

    global.applyAutoIdentity = async function() {
        const cmd = `falcon_cli fetch_auto_identity --pixel-beta`;
        await executeShellCommand(cmd);
        alert('Fetched and applied fresh Pixel Beta auto identity.');
    };

    global.toggleCronAutoIdentity = async function(enabled) {
        const cmd = `falcon_cli set_cron_identity --enable ${enabled ? 1 : 0}`;
        await executeShellCommand(cmd);
    };

    global.applyTelephonyIdentifiers = async function() {
        const data = {
            sim1: {
                imei: document.getElementById('sim1_imei').value,
                meid: document.getElementById('sim1_meid').value,
                imsi: document.getElementById('sim1_imsi').value,
                iccid: document.getElementById('sim1_iccid').value,
                phone: document.getElementById('sim1_phone').value
            },
            sim2: {
                imei: document.getElementById('sim2_imei').value,
                meid: document.getElementById('sim2_meid').value,
                imsi: document.getElementById('sim2_imsi').value,
                iccid: document.getElementById('sim2_iccid').value,
                phone: document.getElementById('sim2_phone').value
            },
            visible_sim_count: document.getElementById('visibleSimCount').value,
            visible_camera_count: document.getElementById('visibleCameraCount').value,
            serial: document.getElementById('deviceSerial').value
        };

        const jsonStr = JSON.stringify(data).replace(/"/g, '\\"');
        const cmd = `falcon_cli set_telephony "${jsonStr}"`;
        await executeShellCommand(cmd);
        alert('Attestation and Telephony Identifiers applied successfully.');
    };

    global.saveSecurityPatchSettings = async function() {
        const autoPatch = document.getElementById('autoSecurityPatchToggle').checked;
        const threshold = document.getElementById('staleRomThreshold').value;
        const cmd = `falcon_cli set_security_patch --auto ${autoPatch ? 1 : 0} --threshold ${threshold}`;
        await executeShellCommand(cmd);
        alert('Security patch settings saved.');
    };

    global.saveCustomTemplates = async function() {
        const json = document.getElementById('customTemplatesJson').value;
        const cmd = `falcon_cli set_custom_templates '${json}'`;
        await executeShellCommand(cmd);
        alert('Custom templates saved.');
    };

    global.saveKernelIdentity = async function() {
        const sysname = document.getElementById('kernelSysname').value;
        const release = document.getElementById('kernelRelease').value;
        const cmd = `falcon_cli set_kernel_identity --sysname "${sysname}" --release "${release}"`;
        await executeShellCommand(cmd);
        alert('Kernel identity saved.');
    };

})(window);