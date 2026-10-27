<div align="center">

# 🦅 FALCON INTEGRITY FIX

[![Magisk](https://img.shields.io/badge/Magisk-23%2B-00B0FF?style=for-the-badge&logo=magisk)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-4CAF50?style=for-the-badge)](https://github.com/tiann/KernelSU)
[![Zygisk](https://img.shields.io/badge/Zygisk-Ready-orange?style=for-the-badge)](https://github.com/topjohnwu/Magisk/wiki/Zygisk)
[![License](https://img.shields.io/badge/License-GPL%20v3-blue?style=for-the-badge)](LICENSE)
[![Version](https://img.shields.io/badge/Version-v3.24-red?style=for-the-badge)](https://github.com/AHMED2111X/AHMED2111X/releases)

**Play Integrity Fix • Tricky Store OSS • Advanced TEE/RKP Fixes**

[العربية](#arabic) • [English](#english)

</div>

---

## 🆕 What's New in v3.24

### العربية

- **🌐 واجهة بلغات العالم — 248 لغة** — زر 🌐 واحد يفتح قائمة كل لغات العالم مع بحث فوري بالاسم الأصلي أو الإنجليزي أو الرمز، وتبديل RTL/LTR فوراً، وزر «🌐 لغة الجهاز» في الأعلى، مع حفظ تلقائي للغة.
- **🎯 إخفاء كل التطبيقات عند التثبيت** — عند التثبيت يُختار كل التطبيقات المثبتة ويُخفى فوراً، ويستمر الإخفاء التلقائي لأي تطبيق جديد يُثبَّت لاحقاً (زر الإخفاء التلقائي يوقفه).
- **🔗 حذف الوحدتين معاً (مُختبَر فعلياً)** — حذف أي وحدة منهما يحذف الأخرى فوراً من كل من `modules` و`modules_update`، مع حراسات إقلاع في الوحدتين تمنع بقاء أي وحدة يتيمة، ودون المساس بكيبوكس المستخدم.
- **📢 فتح قناة تليجرام بعد اكتمال التفليش** — بعد 5 ثوانٍ من انتهاء التفليش يُفتح تطبيق تليجرام الرسمي في **نافذة منفصلة**، ويبقى مدير الروت مفتوحاً لتعود إليه وتضغط «إعادة التشغيل» بنفسك — **بدون أي إعادة تشغيل تلقائية**.

### English

- **🌐 World-language UI — 248 languages** — one 🌐 button opens every world language with instant search (native name, English name, language code), instant RTL/LTR switching, a "🌐 device language" shortcut, and automatic language persistence.
- **🎯 Hide every app at install** — all installed apps are selected and hidden immediately at install, and auto-hide keeps applying to newly installed apps afterwards (the auto-hide toggle turns it off).
- **🔗 Uninstall symmetry (actually tested)** — removing either module instantly removes the other from both `modules` and `modules_update`, with boot guards in both modules against orphaned modules, and without touching the user's keybox.
- **📢 Telegram channel opens after flashing** — 5 seconds after flashing completes, the official Telegram app opens in a **separate window** while the root manager stays open so you return to it and press Reboot yourself — **never an automatic reboot**.

---
## 🆕 What's New in v3.23

### العربية

- **🔐 منفذا كيبوكس حقيقيان (أساسي + ثانوي)** — نظام جديد كامل `falcon_keybox.sh` يدير منفذين: الأساسي `/data/adb/falcon/keybox.xml` (**مُقدَّس، لا يُكتب ولا يُحذف أبداً**) والثانوي `/data/adb/falcon/keybox2.xml` (احتياطي). مع تفضيل صريح (`auto` / `primary` / `secondary`)، وكتابة ذرّية للملف النشط، ونسخ احتياطية (آخر 3 لكل نوع)، وسجل كامل، وانعكاس تلقائي على TEESim.
- **🖥️ لوحة "منفذ الكيبوكس" في واجهة FALCON TRICKY** — عرض الحالة، تبديل التفضيل، ترقية الثانوي إلى الأساسي، ومسح الثانوي — كلها من الواجهة مباشرة (عربي/English/Türkçe/Русский).
- **🔄 محرك Tricky Store لا يبدأ قبل تجهيز الكيبوكس** — أُعيد ترتيب `service.sh` ليُطبَّق المنفذ المختار **قبل** إقلاع المحرك، فلا يبدأ المحرك أبداً بكيبوكس قديم أو مرفق.
- **🧱 لم تعد التثبيتات تدهس كيبوكساً نشطاً** — `customize.sh` لم يعد ينسخ فوق الملف النشط بلا ترتيب؛ الاستبدال يحدث فقط عند غياب الملف أو تلفه.
- **🧬 لن يتبنّى الموديول كيبوكس الإضافة ككيبوكس مستخدم** — نسخ الكيبوكس المرفق (الحالي أو لقطة إصدار سابق) مستبعدة صراحةً من التبنّي التلقائي.
- **🛡️ نسخة احتياطية إلزامية قبل التنظيف الشامل** — `clean_install.sh` ينسخ كيبوكسات المستخدم وإعداداته إلى `/sdcard/FALCON_CLEAN_BACKUP_<التاريخ>` قبل أي حذف.
- **🔒 تحقّق SHA-256 من سلامة الحزمة** — ملف `payload.sha256` مولَّد وقت البناء يُفحص في بداية التثبيت؛ **تحذير فقط** ولا يمنع التثبيت أبداً.
- **📦 توافق Magisk 28102+** — دعم `MAGISK_WHITEOUT` لإخفاء تطبيقات الرومات المخصصة، وتعطيل خصائص `persist.sys.pp.*` المتعارضة.
- **♻️ مسح ذاكرة خصائص بعد الحذف** — `resetprop -c` بعد `resetprop --delete` (من مرجع PIF 19.7.7-r2) لضمان عدم بقاء قيمة قديمة في ذاكرة الخصائص.
- **🛡️ طبقة توافق الرومات المعدّلة (جديد)** — `falcon_rom_compat.sh` تعالج 21 خاصية كانت مكشوفة على LineageOS/crDroid/Evolution: `ro.build.tags` (`test-keys` ⇒ `release-keys`)، `ro.build.type` (`userdebug` ⇒ `user`)، بصمات الأجزاء الأربعة، معرّفات البناء، تواريخ الرقعة، و`ro.build.description`. القيم كلها مشتقّة من نفس بصمة PIF ⇒ اتساق مضمون 100%. تُطبَّق قبل Zygote وتُعاد كل 20 ثانية.
- **📦 مجلد `zygisk/` مطابق للمرجع 1:1** — أضفنا `zygisk/keybox.xml` و`zygisk/xda-developers` (نسخة مطابقة بايت-ببايت) و`zygisk/target.txt` و`zygisk/security_patch.txt`، فاكتملت سلسلة الاحتياطي `$MODDIR/zygisk/keybox.xml` ← `$MODDIR/keybox.xml` التي كانت معطوبة، وتطابق تخطيط الحزمة المرجع تماماً.
- **🔬 تدقيق بايت-بايتي لوحدة Zygisk** — أثبت التحليل أن `zygisk/*.so` لا تقرأ أي كيبوكس إطلاقاً (0 إشارة لـ `keybox`)، وتقرأ فقط `pif.prop` و`custom.pif.prop` و`custom.pif.json` — أي أن **البصمة تمر عبر مساراتها المعتادة فقط، ولم يتغيّر سلوك الزيجيسك إطلاقاً**.
- **🚧 بوابات تثبيت أوضح** — تحذير عند التثبيت من Recovery، ورسالة واضحة لمعمارية غير مدعومة (دون منع تثبيت الأجهزة المدعومة).

### English

- **🔐 Real dual keybox slots (primary + secondary)** — a complete new `falcon_keybox.sh` manager: the primary `/data/adb/falcon/keybox.xml` is **sacred — never written, never wiped**, and the secondary `/data/adb/falcon/keybox2.xml` is an optional backup. Explicit preference (`auto` / `primary` / `secondary`), atomic writes to the active file, rolling backups (last 3 per type), a full log, and automatic TEESim mirroring.
- **🖥️ "Keybox slots" panel in the FALCON TRICKY WebUI** — status, preference switching, secondary → primary promotion and secondary clearing, straight from the UI (Arabic/English/Türkçe/Русский).
- **🔄 The Tricky Store engine never starts before the keybox is ready** — `service.sh` was reordered so the chosen slot is applied **before** the daemon boots.
- **🧱 Installs no longer stomp an active keybox** — `customize.sh` only replaces the active file when it is missing or corrupted.
- **🧬 The module never adopts its own bundled keybox as a user keybox** — bundled copies (current or older snapshot) are explicitly excluded from auto-adoption.
- **🛡️ Mandatory backup before a clean wipe** — `clean_install.sh` copies user keyboxes/configs to `/sdcard/FALCON_CLEAN_BACKUP_<timestamp>` before deleting anything.
- **🔒 SHA-256 package integrity check** — a build-time `payload.sha256` manifest is verified at the start of the install; **warning only**, it can never block an install.
- **📦 Magisk 28102+ compatibility** — `MAGISK_WHITEOUT` support for hiding custom-ROM injection apps, plus conflicting `persist.sys.pp.*` property handling.
- **♻️ Property-cache flush after deletion** — `resetprop -c` after `resetprop --delete` (from the PIF 19.7.7-r2 reference).
- **🚧 Clearer install gates** — warning when installing from recovery, explicit message for unsupported architectures (supported devices are never blocked).
- **🛡️ Custom-ROM compatibility layer (new)** — `falcon_rom_compat.sh` fixes 21 properties that were exposed on LineageOS/crDroid/Evolution: `ro.build.tags` (`test-keys` ⇒ `release-keys`), `ro.build.type` (`userdebug` ⇒ `user`), the four partition fingerprints, build IDs, security-patch dates, and `ro.build.description`. Every value is derived from the same PIF fingerprint ⇒ guaranteed 100% consistency. Applied before Zygote and re-applied every 20 seconds.
- **📦 `zygisk/` folder now 1:1 with the reference** — we added `zygisk/keybox.xml` and `zygisk/xda-developers` (byte-identical copies) plus `zygisk/target.txt` and `zygisk/security_patch.txt`. This completes the `$MODDIR/zygisk/keybox.xml` ← `$MODDIR/keybox.xml` fallback chain that was previously broken, and makes the package layout match the reference exactly.
- **🔬 Byte-level audit of the Zygisk module** — proven that `zygisk/*.so` never reads any keybox (0 `keybox` strings); they only read `pif.prop`, `custom.pif.prop` and `custom.pif.json` — so **the fingerprint still flows through its usual paths and the Zygisk behaviour is completely unchanged**.

### 🛡️ دعم الرومات المعدّلة (جديد في v3.23)

على الرومات المخصصة (LineageOS / crDroid / Evolution X / PixelOS ...) تترك بعض الخصائص بصمة الروم نفسه، وهي **أوضح علامات** تعرّفه جوجل وتُفشل فحص السلامة:

| الخاصية | على الروم المعدّل | ما يفعله الموديول |
|---|---|---|
| `ro.build.tags` | `test-keys` | ⇒ `release-keys` |
| `ro.build.type` | `userdebug` / `eng` | ⇒ `user` |
| `ro.debuggable` | `1` | ⇒ `0` |
| `ro.secure` / `ro.adb.secure` | `0` | ⇒ `1` |
| `ro.system/vendor/odm/product.build.fingerprint` | بصمة الروم | ⇒ بصمة PIF المموَّهة |
| `ro.system/vendor/odm/product.build.tags` | `test-keys` | ⇒ `release-keys` |
| `ro.system/vendor/odm/product.build.id` | معرّف الروم | ⇒ معرّف PIF |
| `ro.*.build.version.security_patch` | تاريخ الروم | ⇒ تاريخ PIF |
| `ro.build.description` | اسم الروم | ⇒ وصف بنية متسقة |

**كيف نضمن الاتساق؟** كل قيمة تُستخرج من **نفس بصمة PIF** (`custom.pif.prop`، أو الهوية المحفوظة من الواجهة إن وُجدت) ⇒ يستحيل أن تتعارض مع محرك PIF.

**الأوامر:**
```sh
sh /data/adb/modules/playintegrityfix/falcon_rom_compat.sh status   # عرض الحالة
sh /data/adb/modules/playintegrityfix/falcon_rom_compat.sh disable  # تعطيل
sh /data/adb/modules/playintegrityfix/falcon_rom_compat.sh enable   # تفعيل
```

> ⛔ **لا نلمس** `ro.build.fingerprint` — يتولّاها محرك PIF داخل العمليات المستهدفة فقط (سلوك PIF الأصلي). ولا نكتب أي ملف نظام إطلاقاً — الخصائص فقط عبر `resetprop`.

---

## 🆕 What's New in v3.22

### العربية

- **📊 عداد المستخدمين الناشطين المباشر** — يظهر داخل واجهة FALCON TRICKY ويُحدَّث كل 5 ثوانٍ، بمعرّف جهاز واحد لكل مستخدم (لا احتساب مزدوج)، مع عرض فوري من الذاكرة المؤقتة عند فتح الصفحة.
- **🖥️ حالة الوحدة الحيّة في مدير الروت** — بطاقة **FALCON TRICKY** تعرض: `⚙️ Engine: Running | Google: 3/3 | 🔑 KB OK` وتتحدث كل 4 ثوانٍ، وبطاقة **FALCON INTEGRITY FIX** تعرض الزيجيسك وحالة BL والعدد النشط.
- **🔧 إصلاح العداد (صفر دائم)** — `wget --timeout` غير مدعوم في BusyBox المدمج؛ صار الاستدعاء بـ `-T 6` مع سلسلة بديلة: curl ← BusyBox ← wget، مع مهلة قصيرة لكل أمر وعدم تصفير القيمة عند فشل الشبكة.
- **🛰️ إصلاح تحديث بصمة Canary** — إزالة `set +o standalone` (كان يوقف السكربت بصمت على أندرويد) وضبط `DEVICE_INITIAL_SDK_INT` لكل جهاز على حدة.
- **🌐 سيرفر عدّاد متجدد (اختياري)** — نسخة Cloudflare Worker جديدة بـ Durable Object واحدة تضمن رقماً متسقاً لكل المستخدمين، مع `POST /ping` و`GET /count` (مجلد `server/`).

### English

- **📊 Live active-users counter** — displayed inside the FALCON TRICKY WebUI, refreshed every 5 seconds with a single device ID per user (no double counting) and instant memory-cache rendering on open.
- **🖥️ Live module status in your root manager** — the **FALCON TRICKY** card shows `⚙️ Engine: Running | Google: 3/3 | 🔑 KB OK` refreshed every 4 seconds; the **FALCON INTEGRITY FIX** card shows Zygisk, BL state and the active count.
- **🔧 Counter fix (always zero)** — `wget --timeout` is unsupported by the bundled BusyBox; requests now use `-T 6` with a curl ← BusyBox ← wget fallback chain, short per-command timeouts, and no value resets on network failure.
- **🛰️ Canary fingerprint update fix** — removed `set +o standalone` (silently killed the script on Android) and made `DEVICE_INITIAL_SDK_INT` per-device.
- **🌐 Refreshed counter server (optional)** — a new Cloudflare Worker with a single Durable Object guaranteeing one consistent number for all users (`POST /ping`, `GET /count`) — see the `server/` folder.

---

## <a name="arabic"></a>🇸🇦 العربية

### 📖 نبذة عن المشروع

**FALCON INTEGRITY FIX** هو موديول متكامل لإصلاح فحص Play Integrity على أجهزة Android المدعومة، يجمع بين أفضل الحلول في مكان واحد مع واجهة احترافية موحدة عبر **FALCON TRICKY** WebUI.

يهدف الموديول إلى تجاوز قيود فحص الجهاز على Google Play Services، مع الحفاظ على الأمان والخصوصية قدر الإمكان، ودعم مختلف بيئات الروت (Magisk + Zygisk، ZygiskNext، NeoZygisk، ReZygisk، BreZygisk).

### ✨ المزايا الرئيسية

- **🟢 Zygisk Ready** – يدعم جميع محركات Zygisk المعروفة
- **🎭 PIF + Tricky Store OSS v3.1.0** – دمج كامل لمحرك التعتيد المفتوح المصدر
- **🔐 دعم Keybox ذكي** – نقل تلقائي للـKeybox صالح من أي إضافة قديمة مع أولوية للـKeybox الخاص بالمستخدم
- **🩺 إصلاح RKP Auto-Fix** – إصلاح تلقائي لمفاتيح RKP لأجهزة Red Magic وغيرها
- **🧰 SOTER / TEE Fixes** – تحسينات إضافية لإصلاح فحص التشفير والحماية
- **🗑️ تنظيف تلقائي** – حذف قسري لأي إضافة TrickyStore قديمة لمنع التعارضات
- **🖥️ واجهة FALCON TRICKY WebUI** – تحكم موحد، أيقونات حقيقية، دعم متعدد اللغات
- **📊 عداد المستخدمين الناشطين** – رقم مباشر داخل الواجهة ووصف الوحدة
- **📦 ضم تلقائي للتطبيقات** – إضافة جميع التطبيقات المثبتة لقائمة `target.txt` تلقائياً عند التثبيت
- **🔄 مزامنة Keybox تلقائية** – نظام FALCON KEYSYNC لفحص وتحديث الـKeybox
- **🛡️ قوائم عزل تلقائية** – إضافة Google Play Services وPlay Store لقائمة DenyList تلقائياً

### 📋 المتطلبات

- جهاز أندرويد مدعوم بإصدار **Android 7.0 (API 25)** أو أعلى
- رووت عبر **[Magisk](https://github.com/topjohnwu/Magisk)** (مع تفعيل Zygisk) أو **[KernelSU](https://github.com/tiann/KernelSU)**
- دعم **Zygisk** (مدمج أو خارجي)

### 📥 طريقة التثبيت

1. حمل أحدث إصدار من قسم [Releases](https://github.com/AHMED2111X/AHMED2111X/releases)
2. افتح مدير Magisk/KernelSU وانتقل لقسم **الوحدات** → **التثبيت من ملف**
3. اختر ملف `FALCONINTEGITY_FIX_V3.24.zip` وابدأ التثبيت
4. أعد تشغيل الجهاز
5. افتح **FALCON TRICKY** من قائمة الوحدات للوصول للواجهة

### 🔧 الاستخدام

- **واجهة WebUI**: متاحة عبر وحدة `FALCON TRICKY` المربوطة بالوحدة الرئيسية
- **Keybox مخصص**: ضع ملف `keybox.xml` الخاص بك في `/data/adb/falcon/keybox.xml` وسيتم استخدامه تلقائياً
- **إدارة Target List**: من الواجهة أو مباشرةً في `/data/adb/tricky_store/target.txt`
- **فحص التحديثات**: يدعم `updateJson` مع تحديثات مباشرة من خلال مدير الروت

### 🔑 منفذا الكيبوكس (جديد في v3.23)

يدعم الموديول الآن ملفي كيبوكس منفصلين، مع الحفاظ على الأساسي وعدم استبداله تلقائياً:

- **المنفذ الأساسي**: `/data/adb/falcon/keybox.xml`
- **المنفذ الثانوي**: `/data/adb/falcon/keybox2.xml`
- **الملف النشط**: `/data/adb/tricky_store/keybox.xml` (يقرأه محرك Tricky Store)

الأوامر (من طرفية الروت):

```sh
# الحالة الكاملة: صلاحية كل منفذ، النشط حالياً، والتفضيل
sh /data/adb/modules/playintegrityfix/falcon_keybox.sh status

# إضافة منفذ ثانوي وتفعيله فوراً (مع نسخة احتياطية)
sh /data/adb/modules/playintegrityfix/falcon_keybox.sh set-secondary /sdcard/Download/keybox2.xml

# التبديل بين المنفذين
sh /data/adb/modules/playintegrityfix/falcon_keybox.sh prefer secondary
sh /data/adb/modules/playintegrityfix/falcon_keybox.sh prefer auto

# ترقية الثانوي إلى أساسي (الأساسي القديم يُحفظ في backups)
sh /data/adb/modules/playintegrityfix/falcon_keybox.sh promote-secondary

# حذف الثانوي (مع نسخة احتياطية)
sh /data/adb/modules/playintegrityfix/falcon_keybox.sh clear-secondary
```

- `prefer auto`: أساسي صالح ← ثانوي صالح ← مرفق. (`prefer primary` مرادف لـ`auto`)
- `prefer secondary`: ثانوي صالح ← أساسي صالح ← مرفق.
- لا يُحذف أي منفذ تلقائياً، ولا يُنسخ الثانوي فوق الأساسي إلا بأمر `promote-secondary`.
- النسخ الاحتياطية في `/data/adb/falcon/keybox_slots/backups` (آخر 3 لكل نوع).
- السجل في `/data/adb/falcon/keybox_slots/keybox.log`.

### 📦 بنية مجلد `zygisk/` داخل الحزمة

مجلد `zygisk/` في الحزمة يحتوي على نفس محتويات المرجع (Play Integrity Fix 19.7.7-r2) بالبيكيت:

| الملف | الحجم | الغرض |
|---|---|---|
| `zygisk/arm64-v8a.so` | 237,144 | وحدة Zygisk (aarch64) — **مطابقة بايت-ببايت** للمرجع |
| `zygisk/armeabi-v7a.so` | 170,476 | وحدة Zygisk (armv7) — مطابقة بايت-ببايت |
| `zygisk/x86.so` | 154,780 | وحدة Zygisk (x86) — مطابقة بايت-ببايت |
| `zygisk/x86_64.so` | 169,584 | وحدة Zygisk (x86_64) — مطابقة بايت-ببايت |
| `zygisk/keybox.xml` | 16,949 | نسخة الكيبوكس المرفق داخل مجلد Zygisk (مطابقة بايت-ببايت للمرجع) |
| `zygisk/xda-developers` | 16,949 | نسخة احتياطية مطابقة تماماً لـ `keybox.xml` (اسم قديم من بنية PIF الأصلية) |
| `zygisk/target.txt` | 75 | قالب قائمة الحمايات (نفس `target.txt` الجذري) |
| `zygisk/security_patch.txt` | 15 | تاريخ الرقعة الأمنية (نفس الملف الجذري) |

**ماذا يقرأ وحدة Zygisk فعلياً؟** تحليل بايت-بايتي كامل للملف `zygisk/arm64-v8a.so` (وكذلك x86) أثبت أنه **لا يحتوي على أي سلسلة** تُشير إلى `keybox` أو `target.txt` أو `tricky` (0 نتيجة من 0). الوحدة تقرأ **فقط**:
```
/data/adb/modules/playintegrityfix/classes.dex
/data/adb/modules/playintegrityfix/pif.prop
/data/adb/modules/playintegrityfix/custom.pif.json
/data/adb/modules/playintegrityfix/custom.pif.prop
/data/adb/modules/playintegrityfix/pif.json
```
أي أن **البصمة تمر عبر هذه المسارات فقط**، والكيبوكس يقرأه محرك **Tricky Store** من `/data/adb/tricky_store/keybox.xml` — لا من مجلد `zygisk/`.

**إذن لماذا نضيفه؟** لأن سكربتاتنا (المثبت، `service.sh`، `action.sh`، ومدير المنفذين) تملك **سلسلة احتياطية** تبدأ بـ `$MODDIR/zygisk/keybox.xml` ثم `$MODDIR/keybox.xml` — وكان الملف الأول غير موجود فتصبح السلسلة معطوبة. الآن اكتملت، وأصبح تخطيط الحزمة مطابقاً 1:1 للمرجع.

### ⚠️ ملاحظات هامة

- **وجود محركين تعتيد** سيؤدي لتعطيل الفحص أو تجميد الجهاز، الموديول ينظف تلقائياً أي تعارضات
- **DenyList**: في حالة استخدام Magisk، يُنصح بترك إعدادات DenyList كما أضافها الموديول تلقائياً
- **Keybox**: استخدم Keybox صالح فقط، والموديول يعطي أولوية للـKeybox الذي تنقله يدوياً، ويدعم منفذين أساسي/ثانوي عبر `falcon_keybox.sh`

### 👨‍💻 المطور

- **المطور**: ABUFARID
- **تيليجرام**: https://t.me/FALCON_KERNEL
- **القناة**: https://t.me/FALCON_KERNEL_PRO

### 🤝 المساهمة

نرحب بالمساهمات! إذا وجدت خطأ أو لديك اقتراح، يمكنك فتح [Issue](https://github.com/AHMED2111X/AHMED2111X/issues) أو التواصل عبر تيليجرام.

### 📜 الترخيص

هذا المشروع مرخص تحت [GNU General Public License v3.0](LICENSE).

---

## <a name="english"></a>🇬🇧 English

### 📖 About

**FALCON INTEGRITY FIX** is an all-in-one Magisk/KernelSU module designed to fix Play Integrity attestation on supported Android devices. It combines proven solutions like Play Integrity Fix and Tricky Store OSS with a unified, professional WebUI through **FALCON TRICKY**.

Built with automation in mind, it handles keybox migration, conflicts, RKP fixes, and much more out of the box.

### ✨ Key Features

- **🟢 Zygisk Ready** – Compatible with all major Zygisk implementations (Magisk Zygisk, ZygiskNext, NeoZygisk, ReZygisk, BreZygisk)
- **🎭 PIF + Tricky Store OSS v3.1.0** – Integrated open-source attestation engine
- **🔐 Smart Keybox Handling** – Auto-detects and imports valid keyboxes from conflicting modules with user-priority support
- **🩺 RKP Auto-Fix** – Automatic RKP key fixes for Red Magic and compatible devices
- **🧰 TEE/SOTER Enhancements** – Extra patches for better attestation results
- **🗑️ Automatic Cleanup** – Force-removes conflicting TrickyStore/PIF-related modules
- **🖥️ FALCON TRICKY WebUI** – Unified control panel with real app icons & multi-language support
- **📊 Active Users Counter** – Live count inside the WebUI and module descriptions
- **📦 Auto-Targeting** – Seeds all installed apps into `target.txt` on first install
- **🔄 Auto Keybox Sync** – FALCON KEYSYNC system with configurable sources
- **🛡️ Auto DenyList** – Automatically adds GMS & Play Store to Magisk DenyList

### 📋 Requirements

- Android **7.0 (API 25)** or higher
- Rooted with **[Magisk](https://github.com/topjohnwu/Magisk)** (Zygisk enabled) or **[KernelSU](https://github.com/tiann/KernelSU)**
- **Zygisk** support required (built-in or external)

### 📥 Installation

1. Download the latest release from the [Releases](https://github.com/AHMED2111X/AHMED2111X/releases) page
2. Open Magisk/KernelSU app → **Modules** → **Install from storage**
3. Select the `FALCONINTEGITY_FIX_V3.24.zip` file
4. Reboot your device
5. Access the UI via the **FALCON TRICKY** module in your root manager

### 🔧 Usage

- **WebUI**: Available from the linked `FALCON TRICKY` module
- **Custom Keybox**: Place your valid `keybox.xml` at `/data/adb/falcon/keybox.xml` to override bundled one
- **Target Management**: Edit `/data/adb/tricky_store/target.txt` or use WebUI
- **Updates**: Supported via `updateJson` in module managers

### 🔑 Two keybox slots (new in v3.23)

The module now manages two separate keybox slots while keeping the primary slot sacred:

- **Primary slot**: `/data/adb/falcon/keybox.xml`
- **Secondary slot**: `/data/adb/falcon/keybox2.xml`
- **Active file** (read by the Tricky Store engine): `/data/adb/tricky_store/keybox.xml`

Commands (from a root shell):

```sh
# Full status: validity of each slot, the active one, and the current preference
sh /data/adb/modules/playintegrityfix/falcon_keybox.sh status

# Add a secondary slot and activate it (with a backup)
sh /data/adb/modules/playintegrityfix/falcon_keybox.sh set-secondary /sdcard/Download/keybox2.xml

# Switch between slots
sh /data/adb/modules/playintegrityfix/falcon_keybox.sh prefer secondary
sh /data/adb/modules/playintegrityfix/falcon_keybox.sh prefer primary

# Promote the secondary slot to primary (explicit, reversible)
sh /data/adb/modules/playintegrityfix/falcon_keybox.sh promote-secondary

# Clear the secondary slot (the primary is never touched)
sh /data/adb/modules/playintegrityfix/falcon_keybox.sh clear-secondary
```

- `prefer auto`: valid primary → valid secondary → bundled. (`prefer primary` is an alias of `auto`)
- `prefer secondary`: valid secondary → valid primary → bundled.
- No slot is ever deleted automatically, and the secondary is never copied over the primary except through an explicit `promote-secondary`.
- Backups live in `/data/adb/falcon/keybox_slots/backups` (last 3 per type).
- The log lives in `/data/adb/falcon/keybox_slots/keybox.log`.

### 📦 `zygisk/` folder layout in the package

The package's `zygisk/` folder now matches the reference (Play Integrity Fix 19.7.7-r2) byte-for-byte:

| File | Size | Purpose |
|---|---|---|
| `zygisk/arm64-v8a.so` | 237,144 | Zygisk module (aarch64) — **byte-identical** to the reference |
| `zygisk/armeabi-v7a.so` | 170,476 | Zygisk module (armv7) — byte-identical |
| `zygisk/x86.so` | 154,780 | Zygisk module (x86) — byte-identical |
| `zygisk/x86_64.so` | 169,584 | Zygisk module (x86_64) — byte-identical |
| `zygisk/keybox.xml` | 16,949 | Bundled keybox inside the Zygisk folder (byte-identical to the reference) |
| `zygisk/xda-developers` | 16,949 | Exact backup copy of `keybox.xml` (legacy name from the original PIF layout) |
| `zygisk/target.txt` | 75 | Protection-list template (same as the root `target.txt`) |
| `zygisk/security_patch.txt` | 15 | Security patch date (same as the root file) |

**What does the Zygisk module actually read?** A full byte-level audit of `zygisk/arm64-v8a.so` (and `x86.so`) shows **zero** string references to `keybox`, `target.txt` or `tricky`. The module reads **only**:
```
/data/adb/modules/playintegrityfix/classes.dex
/data/adb/modules/playintegrityfix/pif.prop
/data/adb/modules/playintegrityfix/custom.pif.json
/data/adb/modules/playintegrityfix/custom.pif.prop
/data/adb/modules/playintegrityfix/pif.json
```
So **the fingerprint flows through those paths only**, and the keybox is read by the **Tricky Store** engine from `/data/adb/tricky_store/keybox.xml` — not from the `zygisk/` folder.

**So why add it?** Because our scripts (installer, `service.sh`, `action.sh`, and the slot manager) have a **fallback chain** that starts at `$MODDIR/zygisk/keybox.xml` and then `$MODDIR/keybox.xml` — the first entry was missing, so the chain was broken. It is now complete, and the package layout is 1:1 with the reference.
- The same panel is available in the FALCON TRICKY WebUI → **🔐 منفذ الكيبوكس**.

### ⚠️ Important Notes

- **Avoid duplicate attestation engines** – Having multiple TrickyStore/PIF modules can cause bootloops or broken attestation. This module cleans them automatically
- **DenyList**: If using Magisk, leave the auto-added entries as is for best results
- **Use valid Keyboxes**: Only use legitimately sourced keyboxes
- **Zygisk is untouched in v3.23**: the Zygisk payload ships byte-identical to the previous release and nothing in this version re-pushes or re-injects the fingerprint through Zygisk at runtime. The fingerprint is applied through the properties in `custom.pif.prop`, and hardware attestation is handled by the Tricky Store engine.

### 👨‍💻 Developer

- **Developer**: ABUFARID
- **Telegram**: https://t.me/FALCON_KERNEL
- **Channel**: https://t.me/FALCON_KERNEL_PRO

### 🤝 Contributing

Contributions, issues and feature requests are welcome! Feel free to check the [issues page](https://github.com/AHMED2111X/AHMED2111X/issues).

### 📜 License

This project is licensed under the [GNU General Public License v3.0](LICENSE).
