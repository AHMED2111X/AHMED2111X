<important_rules>
{
  "executeShellCommand": {
    "description": "دالة لتنفيذ أوامر SHELL مع دعم لـ KernelSU و CleveresBridge مع إ管理 الأخطاء.",
    "code": "async function executeShellCommand(cmd) {\n    try {\n        if (typeof global.CleveresBridge !== 'undefined' && global.CleveresBridge.execHost) {\n            const res = await global.CleveresBridge.execHost(cmd, 5000);\n            if (typeof res === 'object' && res !== null) {\n                return res.stdout || res.output || \"\";\n            }\n            return res || \"\";\n        } else if (typeof global.ksu !== 'undefined' && global.ksu.exec) {\n            return new Promise((resolve) => {\n                global.ksu.exec(cmd, (errno, stdout, stderr) => {\n                    if (errno === 0 || !errno) {\n                        resolve(stdout || \"\");\n                    } else {\n                        resolve(stdout || stderr || \"\");\n                    }\n                });\n            });\n        } else {\n            console.log(\"Falcon Kernel Command: \", cmd);\n            throw new Error(\"لا وجود لطريقة تنفيذ SHELL متوفرة\");\n        }\n    } catch (err) {\n        console.error(\"خطأ في تنفيذ أوامر SHELL: \", err);\n        throw err;\n    }\n}"
  },
  "fetchAndInstallKeybox": {
    "description": "دالة لتنزيل ملف Keybox وتحديده مع إ管理 الأخطاء.",
    "code": "global.fetchAndInstallKeybox = async function() {\n    const targetDir = \"/data/adb/tricky_store\";\n    const targetFile = `${targetDir}/keybox.xml`;\n\n    try {\n        // التحقق من وجود目錄 أو إنشاؤه\n        const dirExists = await executeShellCommand(`test -d \"${targetDir}\" && echo \"exists\"`);\n        if (!dirExists.trim()) {\n            await executeShellCommand(`mkdir -p \"${targetDir}\"`);\n        }\n\n        // تنزيل ملف Keybox\n        await executeShellCommand(`curl -sL \"${FIXED_KEYBOX_URL}\" -o \"${targetFile}\"`);\n        await executeShellCommand(`chmod 644 \"${targetFile}\"`);\n        alert(\"✅ تم تنزيل ملف Keybox وتحديده بنجاح!\");\n    } catch (err) {\n        alert(`❌ فشل تنزيل أو تثبيت ملف Keybox: ${err.message}`);\n        throw err;\n    }\n};"
  },
  "deleteCurrentKeybox": {
    "description": "دالة لحذف ملفات Keybox مع التحقق من وجودها.",
    "code": "global.deleteCurrentKeybox = async function() {\n    const targetDir = \"/data/adb/tricky_store\";\n    const targetFile = `${targetDir}/keybox.xml`;\n\n    try {\n        // التحقق من وجود الملف قبل الحذف\n        const fileExists = await executeShellCommand(`test -f \"${targetFile}\" && echo \"exists\"`);\n        if (fileExists.trim()) {\n            await executeShellCommand(`rm -f \"${targetFile}\"`);\n            alert(\"✅ تم حذف ملف Keybox بنجاح\");\n        } else {\n            alert(\"لا يوجد ملف Keybox لحذفه.\");\n        }\n    } catch (err) {\n        alert(`❌ فشل حذف ملف Keybox: ${err.message}`);\n        throw err;\n    }\n};"
  },
  "loadInstalledApps": {
    "description": "دالة لتحميل تطبيقات مثبتة مع إ管理 الأخطاء.",
    "code": "global.loadInstalledApps = async function() {\n    const selectEl = document.getElementById('installedAppsSelect');\n    if (!selectEl) return;\n\n    try {\n        selectEl.innerHTML = '<option value=\"\">جارٍ تحميل التطبيقات...</option>';\n        const output = await executeShellCommand('pm list packages -3');\n\n        if (!output || !output.trim()) {\n            throw new Error(\"لم يتم العثور على تطبيقات مثبتة\");\n        }\n\n        const packages = output.trim().split(/\\r?\\n/)\n            .map(pkg => pkg.replace(/^package:/i, '').trim())\n            .filter(pkg => pkg.length > 0)\n            .sort();\n\n        if (packages.length === 0) {\n            selectEl.innerHTML = '<option value=\"\">لم يتم العثور على تطبيقات مثبتة</option>';\n            return;\n        }\n\n        selectEl.innerHTML = '<option value=\"\">-- اختر تطبيقًا من القائمة --</option>';\n        packages.forEach(pkg => {\n            const opt = document.createElement('option');\n            opt.value = pkg;\n            opt.textContent = pkg;\n            selectEl.appendChild(opt);\n        });\n\n    } catch (err) {\n        console.error(\"خطأ في تحميل التطبيقات المثبتة: \", err);\n        selectEl.innerHTML = `<option value=\"\">حدث خطأ أثناء تحميل التطبيقات: ${err.message}</option>`;\n    }\n};"
  }
}
</important_rules>

```javascript
<final_code>
(function (global) {
    'use strict';

    async function executeShellCommand(cmd) {
        try {
            if (typeof global.CleveresBridge !== 'undefined' && global.CleveresBridge.execHost) {
                const res = await global.CleveresBridge.execHost(cmd, 5000);
                if (typeof res === 'object' && res !== null) {
                    return res.stdout || res.output || "";
                }
                return res || "";
            } else if (typeof global.ksu !== 'undefined' && global.ksu.exec) {
                return new Promise((resolve) => {
                    global.ksu.exec(cmd, (errno, stdout, stderr) => {
                        if (errno === 0 || !errno) {
                            resolve(stdout || "");
                        } else {
                            resolve(stdout || stderr || "");
                        }
                    });
                });
            } else {
                console.log("Falcon Kernel Command:", cmd);
                throw new Error("لا وجود لطريقة تنفيذ SHELL متوفرة");
            }
        } catch (err) {
            console.error("خطأ في تنفيذ أوامر SHELL:", err);
            throw err;
        }
    }

    global.fetchAndInstallKeybox = async function () {
        const targetDir = "/data/adb/tricky_store";
        const targetFile = `${targetDir}/keybox.xml`;

        try {
            // التحقق من وجود目錄 أو إنشاؤه
            const dirExists = await executeShellCommand(`test -d "${targetDir}" && echo "exists"`);
            if (!dirExists.trim()) {
                await executeShellCommand(`mkdir -p "${targetDir}"`);
            }

            // تنزيل ملف Keybox
            await executeShellCommand(`curl -sL "${FIXED_KEYBOX_URL}" -o "${targetFile}"`);
            await executeShellCommand(`chmod 644 "${targetFile}"`);
            alert("✅ تم تنزيل ملف Keybox وتحديده بنجاح!");
        } catch (err) {
            alert(`❌ فشل تنزيل أو تثبيت ملف Keybox: ${err.message}`);
            throw err;
        }
    };

    global.deleteCurrentKeybox = async function () {
        const targetDir = "/data/adb/tricky_store";
        const targetFile = `${targetDir}/keybox.xml`;

        try {
            // التحقق من وجود الملف قبل الحذف
            const fileExists = await executeShellCommand(`test -f "${targetFile}" && echo "exists"`);
            if (fileExists.trim()) {
                await executeShellCommand(`rm -f "${targetFile}"`);
                alert("✅ تم حذف ملف Keybox بنجاح");
            } else {
                alert("لا يوجد ملف Keybox لحذفه.");
            }
        } catch (err) {
            alert(`❌ فشل حذف ملف Keybox: ${err.message}`);
            throw err;
        }
    };

    global.loadInstalledApps = async function () {
        const selectEl = document.getElementById('installedAppsSelect');
        if (!selectEl) return;

        try {
            selectEl.innerHTML = '<option value="">جارٍ تحميل التطبيقات...</option>';
            const output = await executeShellCommand('pm list packages -3');

            if (!output || !output.trim()) {
                throw new Error("لم يتم العثور على تطبيقات مثبتة");
            }

            const packages = output.trim().split(/\r?\n/)
                .map(pkg => pkg.replace(/^package:/i, '').trim())
                .filter(pkg => pkg.length > 0)
                .sort();

            if (packages.length === 0) {
                selectEl.innerHTML = '<option value="">لم يتم العثور على تطبيقات مثبتة</option>';
                return;
            }

            selectEl.innerHTML = '<option value="">-- اختر تطبيقًا من القائمة --</option>';
            packages.forEach(pkg => {
                const opt = document.createElement('option');
                opt.value = pkg;
                opt.textContent = pkg;
                selectEl.appendChild(opt);
            });

        } catch (err) {
            console.error("خطأ في تحميل التطبيقات المثبتة:", err);
            selectEl.innerHTML = `<option value="">حدث خطأ أثناء تحميل التطبيقات: ${err.message}</option>`;
        }
    };

    // ...بقية kode مع التعديلات اللازمة

})(window);
</final_code>