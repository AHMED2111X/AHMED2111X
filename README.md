<div align="center">

# 🦅 FALCON INTEGRITY FIX

[![Magisk](https://img.shields.io/badge/Magisk-23%2B-00B0FF?style=for-the-badge&logo=magisk)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-4CAF50?style=for-the-badge)](https://github.com/tiann/KernelSU)
[![Zygisk](https://img.shields.io/badge/Zygisk-Ready-orange?style=for-the-badge)](https://github.com/topjohnwu/Magisk/wiki/Zygisk)
[![License](https://img.shields.io/badge/License-GPL%20v3-blue?style=for-the-badge)](LICENSE)
[![Version](https://img.shields.io/badge/Version-v3.21-red?style=for-the-badge)](https://github.com/AHMED2111X/AHMED2111X/releases)

**Play Integrity Fix • Tricky Store OSS • Advanced TEE/RKP Fixes**

[العربية](#arabic) • [English](#english)

</div>

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
3. اختر ملف `FALCONINTEGITY_FIX_vX.X.zip` وابدأ التثبيت
4. أعد تشغيل الجهاز
5. افتح **FALCON TRICKY** من قائمة الوحدات للوصول للواجهة

### 🔧 الاستخدام

- **واجهة WebUI**: متاحة عبر وحدة `FALCON TRICKY` المربوطة بالوحدة الرئيسية
- **Keybox مخصص**: ضع ملف `keybox.xml` الخاص بك في `/data/adb/falcon/keybox.xml` وسيتم استخدامه تلقائياً
- **إدارة Target List**: من الواجهة أو مباشرةً في `/data/adb/tricky_store/target.txt`
- **فحص التحديثات**: يدعم `updateJson` مع تحديثات مباشرة من خلال مدير الروت

### ⚠️ ملاحظات هامة

- **وجود محركين تعتيد** سيؤدي لتعطيل الفحص أو تجميد الجهاز، الموديول ينظف تلقائياً أي تعارضات
- **DenyList**: في حالة استخدام Magisk، يُنصح بترك إعدادات DenyList كما أضافها الموديول تلقائياً
- **Keybox**: استخدم Keybox صالح فقط، والموديول يعطي أولوية للـKeybox الذي تنقله يدوياً

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
3. Select the `FALCONINTEGITY_FIX_vX.X.zip` file
4. Reboot your device
5. Access the UI via the **FALCON TRICKY** module in your root manager

### 🔧 Usage

- **WebUI**: Available from the linked `FALCON TRICKY` module
- **Custom Keybox**: Place your valid `keybox.xml` at `/data/adb/falcon/keybox.xml` to override bundled one
- **Target Management**: Edit `/data/adb/tricky_store/target.txt` or use WebUI
- **Updates**: Supported via `updateJson` in module managers

### ⚠️ Important Notes

- **Avoid duplicate attestation engines** – Having multiple TrickyStore/PIF modules can cause bootloops or broken attestation. This module cleans them automatically
- **DenyList**: If using Magisk, leave the auto-added entries as is for best results
- **Use valid Keyboxes**: Only use legitimately sourced keyboxes

### 👨‍💻 Developer

- **Developer**: ABUFARID
- **Telegram**:https://t.me/FALCON_KERNEL
- **Channel**:https://t.me/FALCON_KERNEL_PRO

### 🤝 Contributing

Contributions, issues and feature requests are welcome! Feel free to check the [issues page](https://github.com/AHMED2111X/AHMED2111X/issues).

### 📜 License

This project is licensed under the [GNU General Public License v3.0](LICENSE).
</div>
