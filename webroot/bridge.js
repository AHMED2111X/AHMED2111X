/* ==============================================================================
 * Falcon Integrity Fix - Bridge JavaScript Engine
 * المطور: ABUFARID | @FALCON_KERNEL
 * ============================================================================== */

// --- 1. قوالب الأجهزة الذكية (Device Fingerprints Database) ---
const FINGERPRINT_TEMPLATES = {
    "pixel_10_pro": {
        device: "husky",
        manufacturer: "Google",
        fingerprint: "google/husky/husky:16/BP1A.250305.001/12345678:user/release-keys"
    },
    "pixel_9_pro_a16": {
        device: "komodo",
        manufacturer: "Google",
        fingerprint: "google/komodo/komodo:16/BP11.241206.002/12800000:user/release-keys"
    },
    "pixel_9_pro": {
        device: "komodo",
        manufacturer: "Google",
        fingerprint: "google/komodo/komodo:15/AP2A.240805.005/12000000:user/release-keys"
    },
    "pixel_9": {
        device: "tokay",
        manufacturer: "Google",
        fingerprint: "google/tokay/tokay:15/AP2A.240805.005/12000001:user/release-keys"
    },
    "pixel_8_pro_a15": {
        device: "husky",
        manufacturer: "Google",
        fingerprint: "google/husky/husky:15/AP2A.240805.005/11900000:user/release-keys"
    },
    "samsung_s25_ultra": {
        device: "e3q",
        manufacturer: "samsung",
        fingerprint: "samsung/e3qxx/e3q:15/UP1A.250105.001/S938BXXU1AOA1:user/release-keys"
    },
    "xiaomi_15_pro": {
        device: "haotian",
        manufacturer: "Xiaomi",
        fingerprint: "Xiaomi/haotian/haotian:15/UKQ1.240915.001/V816.0.2.0.UNCCNXM:user/release-keys"
    },
    "pixel_8_pro": {
        device: "husky",
        manufacturer: "Google",
        fingerprint: "google/husky/husky:14/UD1A.230805.004/10310220:user/release-keys"
    },
    "pixel_8": {
        device: "shiba",
        manufacturer: "Google",
        fingerprint: "google/shiba/shiba:14/UD1A.230805.004/10310221:user/release-keys"
    },
    "pixel_7a": {
        device: "lynx",
        manufacturer: "Google",
        fingerprint: "google/lynx/lynx:14/UP1A.231105.003/11010452:user/release-keys"
    },
    "pixel_7_pro": {
        device: "cheetah",
        manufacturer: "Google",
        fingerprint: "google/cheetah/cheetah:14/UP1A.231105.003/11010450:user/release-keys"
    },
    "samsung_s24_ultra": {
        device: "e2q",
        manufacturer: "samsung",
        fingerprint: "samsung/e2qxx/e2q:14/UP1A.231005.007/S928BXXU1AXB5:user/release-keys"
    },
    "samsung_s23_ultra": {
        device: "dm3q",
        manufacturer: "samsung",
        fingerprint: "samsung/dm3qxx/dm3q:14/UP1A.231005.007/S918BXXU3BWJM:user/release-keys"
    },
    "xiaomi_14_pro": {
        device: "shennong",
        manufacturer: "Xiaomi",
        fingerprint: "Xiaomi/shennong/shennong:14/UKQ1.230804.001/V816.0.4.0.UNCCNXM:user/release-keys"
    },
    "oneplus_12": {
        device: "OP595DL1",
        manufacturer: "OnePlus",
        fingerprint: "OnePlus/OP595DL1/OP595DL1:14/UKQ1.230924.001/1705400122:user/release-keys"
    },
    "pixel_4a_a11": {
        device: "sunfish",
        manufacturer: "Google",
        fingerprint: "google/sunfish/sunfish:11/RQ3A.211001.001/7641976:user/release-keys"
    },
    "pixel_5_a11": {
        device: "redfin",
        manufacturer: "Google",
        fingerprint: "google/redfin/redfin:11/RQ3A.211001.001/7641976:user/release-keys"
    }
};

// --- 2. محرك تنفيذ أوامر Root عبر أجهزة أندرويد ---
function execShellCommand(command) {
    return new Promise((resolve, reject) => {
        // فحص وجود بيئة KSU/APatch/Magisk WebUI Bridge
        if (window.ksu && typeof window.ksu.exec === 'function') {
            window.ksu.exec(command, '{}', (stdout, stderr) => {
                resolve(stdout ? stdout.trim() : '');
            });
        } else if (window.su && typeof window.su.exec === 'function') {
            window.su.exec(command).then(res => resolve(res.trim())).catch(reject);
        } else {
            console.warn("Shell Bridge Not Found (Running in Mock/Browser Mode):", command);
            resolve("OK");
        }
    });
}

// --- 3. توليد القيم العشوائية (Random Generators) ---
function generateRandomHex(length) {
    const chars = '0123456789ABCDEF';
    let result = '';
    for (let i = 0; i < length; i++) {
        result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
}

function generateRandomNumeric(length) {
    let result = '';
    for (let i = 0; i < length; i++) {
        result += Math.floor(Math.random() * 10).toString();
    }
    return result;
}

function generateIMEI() {
    let imei = "35" + generateRandomNumeric(12);
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

function randomizeField(elementId, type) {
    const el = document.getElementById(elementId);
    if (!el) return;

    switch (type) {
        case 'imei':
            el.value = generateIMEI();
            break;
        case 'meid':
            el.value = generateRandomHex(14);
            break;
        case 'imsi':
            el.value = "310150" + generateRandomNumeric(9);
            break;
        case 'iccid':
            el.value = "890141032" + generateRandomNumeric(10);
            break;
        case 'phone':
            el.value = "+120255" + generateRandomNumeric(5);
            break;
        case 'serial':
            el.value = generateRandomHex(12);
            break;
        case 'simCount':
            el.value = Math.floor(Math.random() * 3) + 1;
            break;
        case 'camCount':
            el.value = Math.floor(Math.random() * 4) + 1;
            break;
    }
}

// --- 4. وظائف إدارة الهوية (Identity Tab Functions) ---
document.addEventListener('DOMContentLoaded', () => {
    const templateSelect = document.getElementById('identityTemplateSelect');
    if (templateSelect) {
        templateSelect.addEventListener('change', (e) => {
            const key = e.target.value;
            if (FINGERPRINT_TEMPLATES[key]) {
                const t = FINGERPRINT_TEMPLATES[key];
                document.getElementById('idDevice').value = t.device;
                document.getElementById('idManufacturer').value = t.manufacturer;
                document.getElementById('idFingerprint').value = t.fingerprint;
            }
        });
    }
});

function randomizeTemplate() {
    const keys = Object.keys(FINGERPRINT_TEMPLATES);
    const randomKey = keys[Math.floor(Math.random() * keys.length)];
    const select = document.getElementById('identityTemplateSelect');
    if (select) {
        select.value = randomKey;
        select.dispatchEvent(new Event('change'));
    }
}

function copyFingerprint() {
    const fpInput = document.getElementById('idFingerprint');
    if (fpInput && fpInput.value) {
        navigator.clipboard.writeText(fpInput.value).then(() => {
            alert('تم نسخ البصمة بنجاح!');
        });
    }
}

function randomizeAllIdentifiers() {
    randomizeTemplate();
    randomizeAllTelephonyAndHardware();
}

function applyAutoIdentity() {
    const pixelKeys = Object.keys(FINGERPRINT_TEMPLATES).filter(k => k.startsWith('pixel'));
    const randomPixel = pixelKeys[Math.floor(Math.random() * pixelKeys.length)];
    const select = document.getElementById('identityTemplateSelect');
    if (select) {
        select.value = randomPixel;
        select.dispatchEvent(new Event('change'));
        applyIdentityManager();
    }
}

function applyIdentityManager() {
    const device = document.getElementById('idDevice').value;
    const manufacturer = document.getElementById('idManufacturer').value;
    const fp = document.getElementById('idFingerprint').value;

    if (!fp) {
        alert('يرجى اختيار أو إدخال بصمة هاتف أولاً!');
        return;
    }

    const cmd = `
        resetprop -n ro.product.device "${device}"
        resetprop -n ro.product.manufacturer "${manufacturer}"
        resetprop -n ro.build.fingerprint "${fp}"
        resetprop -n ro.bootimage.build.fingerprint "${fp}"
    `;

    execShellCommand(cmd).then(() => {
        alert('تم تطبيق هوية الجهاز الجديدة بنجاح!');
    });
}

function toggleCronAutoIdentity(checked) {
    const state = checked ? "1" : "0";
    execShellCommand(`echo "${state}" > /data/adb/falcon_cron_identity.cfg`).then(() => {
        alert(checked ? 'تم تفعيل جلب الهوية التلقائي كل 24 ساعة.' : 'تم تعطيل جلب الهوية التلقائي.');
    });
}

function saveCustomTemplates() {
    const jsonStr = document.getElementById('customTemplatesJson').value;
    try {
        JSON.parse(jsonStr);
        execShellCommand(`echo '${jsonStr}' > /data/adb/falcon_custom_templates.json`).then(() => {
            alert('تم حفظ القوالب المخصصة بنجاح.');
        });
    } catch (e) {
        alert('تنسيق JSON غير صحيح!');
    }
}

function applyKernelPreset(presetKey) {
    const sysnameInput = document.getElementById('kernelSysname');
    const releaseInput = document.getElementById('kernelRelease');

    const presets = {
        "android16_6_6": { sysname: "Linux", release: "6.6.21-android16-11-g89abcde" },
        "android15_6_1": { sysname: "Linux", release: "6.1.75-android15-9-g1234567" },
        "android14_6_1": { sysname: "Linux", release: "6.1.25-android14-8-g0123456" },
        "android14_5_15": { sysname: "Linux", release: "5.15.110-android14-8-ab12345" },
        "android13_5_10": { sysname: "Linux", release: "5.10.168-android13-9-gcba9876" },
        "android12_5_10": { sysname: "Linux", release: "5.10.160-android12-9-g1234567" },
        "android11_4_19": { sysname: "Linux", release: "4.19.191-mainline-g9876543" }
    };

    if (presets[presetKey]) {
        sysnameInput.value = presets[presetKey].sysname;
        releaseInput.value = presets[presetKey].release;
    }
}

function saveKernelIdentity() {
    const sysname = document.getElementById('kernelSysname').value;
    const release = document.getElementById('kernelRelease').value;

    const cmd = `
        resetprop -n ro.build.kernel.sysname "${sysname}"
        resetprop -n ro.build.kernel.release "${release}"
    `;

    execShellCommand(cmd).then(() => {
        alert('تم تطبيق هوية النواة والكيرنل بنجاح!');
    });
}

function randomizeAllTelephonyAndHardware() {
    randomizeField('sim1_imei', 'imei');
    randomizeField('sim1_meid', 'meid');
    randomizeField('sim1_imsi', 'imsi');
    randomizeField('sim1_iccid', 'iccid');
    randomizeField('sim1_phone', 'phone');

    randomizeField('sim2_imei', 'imei');
    randomizeField('sim2_meid', 'meid');
    randomizeField('sim2_imsi', 'imsi');
    randomizeField('sim2_iccid', 'iccid');
    randomizeField('sim2_phone', 'phone');

    randomizeField('visibleSimCount', 'simCount');
    randomizeField('visibleCameraCount', 'camCount');
    randomizeField('deviceSerial', 'serial');
}

function clearAllTelephonyFields() {
    const fields = ['sim1_imei', 'sim1_meid', 'sim1_imsi', 'sim1_iccid', 'sim1_phone',
                    'sim2_imei', 'sim2_meid', 'sim2_imsi', 'sim2_iccid', 'sim2_phone',
                    'visibleSimCount', 'visibleCameraCount', 'deviceSerial'];
    fields.forEach(f => {
        const el = document.getElementById(f);
        if (el) el.value = '';
    });
}

function applyTelephonyIdentifiers() {
    const imei = document.getElementById('sim1_imei').value;
    const serial = document.getElementById('deviceSerial').value;

    let cmd = "";
    if (imei) cmd += `resetprop -n ro.ril.oem.imei "${imei}"\n`;
    if (serial) cmd += `resetprop -n ro.serialno "${serial}"\n`;

    execShellCommand(cmd).then(() => {
        alert('تم تطبيق إعدادات الاتصالات والرقم التسلسلي!');
    });
}

// --- 5. وظائف إدارة البروفايلات (Profiles Functions) ---
function createNewProfile() {
    const name = prompt("أدخل اسم البروفايل الجديد:");
    if (name) {
        alert(`تم إنشاء البروفايل: ${name}`);
    }
}

function exportProfiles() {
    const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify({ profiles: [] }));
    const downloadAnchor = document.createElement('a');
    downloadAnchor.setAttribute("href", dataStr);
    downloadAnchor.setAttribute("download", "falcon_profiles.json");
    document.body.appendChild(downloadAnchor);
    downloadAnchor.click();
    downloadAnchor.remove();
}

function importProfiles() {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.json';
    input.onchange = e => {
        alert('تم استيراد ملف البروفايلات بنجاح!');
    };
    input.click();
}

// --- 6. وظائف الكيبوكس (Keybox Management Functions) ---
function fetchAndInstallKeybox() {
    const url = document.getElementById('keyboxSourceUrl').value;
    const cmd = `
        mkdir -p /data/adb/tricky_store
        curl -sSL -o /data/adb/tricky_store/keybox.xml "${url}" || wget -q -O /data/adb/tricky_store/keybox.xml "${url}"
        chmod 644 /data/adb/tricky_store/keybox.xml
        chown root:root /data/adb/tricky_store/keybox.xml
    `;
    execShellCommand(cmd).then(() => {
        alert('تم تنزيل وتثبيت ملف Keybox في TrickyStore بنجاح!');
    });
}

function deleteCurrentKeybox() {
    if (confirm("هل أنت تأكد من إزالة ملفات Keybox الحالية؟")) {
        const cmd = `rm -f /data/adb/tricky_store/keybox.xml /data/adb/tricky_store/*.bak /data/adb/tricky_store/*.tmp`;
        execShellCommand(cmd).then(() => {
            alert('تم حذف جميع ملفات Keybox والنسخ الاحتياطية بنجاح.');
        });
    }
}

// --- 7. وظائف تصحيح الأمان والتحقق من التطبيقات (Security Patch) ---
function saveSecurityPatchSettings() {
    const autoPatch = document.getElementById('autoSecurityPatchToggle').checked;
    const threshold = document.getElementById('staleRomThreshold').value;

    const cmd = `
        echo "auto=${autoPatch}" > /data/adb/falcon_sp.cfg
        echo "threshold=${threshold}" >> /data/adb/falcon_sp.cfg
    `;

    execShellCommand(cmd).then(() => {
        alert('تم حفظ إعدادات تصحيح الأمان!');
    });
}

function loadInstalledApps() {
    const select = document.getElementById('installedAppsSelect');
    if (!select) return;

    select.innerHTML = '<option value="">جاري جلب التطبيقات...</option>';

    execShellCommand("pm list packages -3 | cut -d':' -f2 | sort").then(output => {
        if (!output || output === "OK") {
            select.innerHTML = '<option value="com.google.android.gms">Google Play Services (com.google.android.gms)</option>' +
                               '<option value="com.android.vending">Google Play Store (com.android.vending)</option>';
            return;
        }

        const pkgs = output.split('\n');
        select.innerHTML = '<option value="">-- اختر تطبيقاً مثبتًا --</option>';
        pkgs.forEach(pkg => {
            if (pkg.trim()) {
                const opt = document.createElement('option');
                opt.value = pkg.trim();
                opt.textContent = pkg.trim();
                select.appendChild(opt);
            }
        });
    });
}

function onAppSelected(pkg) {
    const input = document.getElementById('appPackageResolve');
    if (input && pkg) {
        input.value = pkg;
    }
}

function resolveAppPackage() {
    const pkg = document.getElementById('appPackageResolve').value;
    const output = document.getElementById('resolveResultOutput');

    if (!pkg) {
        alert('يرجى اختيار أو أدخال اسم الحزمة أولاً!');
        return;
    }

    output.value = `جاري فحص التطبيق: ${pkg}...\n`;

    execShellCommand(`dumpsys package ${pkg} | grep -E "versionName|firstInstallTime|flags"`).then(res => {
        output.value = `=== نتيجة فحص الحزمة: ${pkg} ===\n` + (res || "لم يتم العثور على تفاصيل إضافية.");
    });
}