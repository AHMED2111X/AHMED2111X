🦅🔥 **FALCON INTEGRITY FIX — الإصدار v3.15** 🔥🦅

━━━━━━━━━━━━━━━━━━━━
**الإصدار الذي أنهى مشكلة** ❌ «الجهاز غير معتمد» **و** ❌ «Bootloader Unlocked» **في فحص Play Integrity!**
بلا إغلاق بوت لودر · بلا مسح بيانات جوجل · بلا خروج من الحسابات.
━━━━━━━━━━━━━━━━━━━━

## 🎯 ما هو الموديول؟

وحدة روت متكاملة تجمع أفضل ما في عالم تجاوز فحص الحماية، مع واجهة عربية كاملة:

| المحرّك | الوظيفة |
|---|---|
| 🎭 **بصمة PIF** | بصمة Pixel 6a (bluejay · beta) مع رقعة أمنية مطابقة تماماً: `2026-09-05` |
| 🔐 **تعتيد الكيبوكس** | محرك **Tricky Store OSS v3.1.0** مفتوح المصدر — يحقن `keystore2` فيُخفي فتح البوت لودر عن جوجل |
| 🩺 **إصلاح RKP** | مخصّص لأجهزة Red Magic / ZTE / Nubia التي تفقد مفاتيح التحقق بعد استعادة EDL أو تحديث النظام |
| 📱 **واجهتان WebUI** | `FALCON TRICKY` — مرصد تخفٍّ بـ **4 لغات** (عربي · إنجليزي · تركي · روسي) |
| 🔄 **تحديث تلقائي** | الموديول يفحص وجود إصدار جديد من داخل مدير الروت |

## ✅ النتيجة المتوقعة

```
✅ BASIC_INTEGRITY
✅ DEVICE_INTEGRITY
✅ STRONG_INTEGRITY   ← وفق قبول جوجل لمفتاح الكيبوكس
✅ متجر Google Play يعرض: «الجهاز معتمد»
```

## 🆕 الجديد في v3.15 — حذف قسري لإضافات TrickyStore + ربط مزدوج فوري

🗑️ **لا يبقى أي أثر لإضافة تخص Tricky Store الأصلي:**

* 🔍 **الكشف لم يعد بالاسم فقط**: يقرأ المثبّت `module.prop` لكل وحدة **(id + name)**، فأي ملحق بأي تسمية (`TrickyAddonModule` · `tricky_addon` · اسم غامض) يُلتقط فوراً.
* ⚡ **حذف قسري فوري حقيقي** (`rm -rf`) بلا انتظار إعادة تشغيل + **قائمة معرّفات معروفة** (`tricky_store` · `TrickyStoreOSS` · `ts_addon` · `tricky_store_addon` …).
* 🧹 **بقايا بيانات الملاحق** (`/data/adb/tricky_addon` وأمثالها) تُنظَّف أيضاً.
* 🔁 **يتكرر تلقائياً عند كل إقلاع** — لو ثبّت أحدهم محركاً أو ملحقاً بعدنا، يُعطَّل ويُحذف.
* 🛡️ **قواعد أمان صارمة**: وحدتنا وملحقنا لا يُمسان · **لا يُمس** `/data/adb/tricky_store` (كيبوكسك و`target.txt` في أمان) · ووحدة تذكر TrickyStore **في الوصف فقط** ⇒ تُعطَّل بدل حذف أعمى قد يصيب وحدة لا تخصنا.

🔗 **والربط المزدوج صار فورياً وحقيقياً في الاتجاهين:**

* حذف **FALCON INTEGRITY FIX** ⇒ يُحذف مجلد **FALCON TRICKY** فوراً + أرشيف أيقوناته.
* حذف **FALCON TRICKY** ⇒ يُشغّل تنظيف الوحدة الأم كاملاً (إيقاف المحرك · إزالة خاصية GMS · حذف السجلات) ثم **يحذف مجلد الأم فوراً**.
* 🧷 علَم حماية داخلي يمنع حذف مجلد الملحق **وهو قيد التنفيذ** — لا حذف نصفي ولا بقايا يتيمة · و`service.sh` في الوحدتين يزيل أي وحدة يتيمة عند الإقلاع.

## 🆕 الجديد في v3.14 — ردّ فعل لحظي + تحديد الكل بضغطة

⚡ **كل ضغطة صارت لحظية — لا مزيد من «هناك عملية قيد التنفيذ… انتظر» لعشر ثوانٍ.**

عرفنا السبب بدقة: في v3.13 كان كل إخفاء/إظهار يشغّل أمرين ثقيلين على الجسر — استخراج أيقونات **كل** التطبيقات، ثم إعادة قراءة قائمة الحزم بـ `pm list packages` — فيبقى الجسر مشغولاً والواجهة مقفلة عشر ثوانٍ قبل أن تستطيع تعليم التطبيق التالي.

**ما تغيّر:**

* 🚀 **الحفظ لم يعد يقرأ قائمة الحزم**: الإخفاء يظهر أمامك **فوراً** في الواجهة، والكتابة تجري في الخلف (نصف ثانية). `pm list packages` لم يبقَ له موضع إلا زر **⟳ تحديث** وعند الإقلاع بصمت. (كان: كل ضغطة = 3–10 ثوانٍ انتظار)
* 🖼️ **الأيقونات لم تعد تمرّ من الجسر أبداً**: صارت تُقرأ كملفات عادية من مسار الواجهة نفسه `webroot/icons/<الحزمة>.png` + ملف فهرس `_index.txt`. **صفر استدعاءات** — والصور تُخزَّن في الواجهة فتُفتح في أجزاء من الثانية.
* 🫥 **استخراج الأيقونات يسحب نفسه في الخلفية** (`( … & )`) وللحزم **الجديدة فقط** — الأمر يعود فوراً فلا يزاحم أي ضغطة.
* ✔️ **زر «تحديد الكل»** — يخفي كل التطبيقات المعروضة أمامك بضغطة واحدة، مع أزرار إخفاء وإظهار **بضغطة زر** كما طلبت.
* ✖️ **زر «إلغاء الكل»** — يُظهر كل المعروض بضغطة واحدة (مع بقاء حزم Google الثلاث محميّة).
* 🔢 **عدّاد ذكي تحت الزرّين**: «قابل للإخفاء: 12 · قابل للإظهار: 40» — تعرف أثر الضغطة قبل أن تضغط.
* 🎯 الزرّان يعملان على **ما تراه بالضبط**: التصفية الحالية + نتيجة البحث الحالية.
* 🛟 ولو تعذّر قراءة أيقونة لأي سبب، تعود الواجهة تلقائياً إلى الحرف الملوّن — بلا خطأ وبلا تعليق.

## 🖼️ أيقونات التطبيقات (v3.13)

👁️ **ترى صورة التطبيق لا اسم حزمته فقط.**

* 🖼️ الوحدة **تستخرج الأيقونة من ملف APK على جهازك نفسه** — بلا إنترنت وبلا صور مرفقة: `icons.sh` يقرأ مورد أيقونة المشغّل من داخل الحزمة.
* ⚡ تُستخرج أيقونات كل التطبيقات المخفية **تلقائياً عند الإقلاع** (في الخلفية بلا تأثير على سرعة الإقلاع).
* 🎯 وعند إخفاء تطبيق جديد تُستخرج أيقونته **فوراً** في الخلفية بلا انتظار إعادة تشغيل.
* 🔤 وإن تعذّر الاستخراج (تطبيق نظامي أو APK مقسّم) يظهر **حرف ملوّن** بلون ثابت لكل تطبيق.
* 📐 يفضّل أعلى دقة متاحة (`xxxhdpi` → `hdpi`) ويفضّل PNG على WEBP.

## ✨ ما أضافته سلسلة التحديثات v3.05 → v3.15

| الإصدار | الإضافة |
|---|---|
| **v3.05** | 🧩 وحدة **FALCON TRICKY** المرافقة + تنظيف أي إصدار قديم من TrickyStore / SafetyNet |
| **v3.06** | 🌐 **4 لغات** كاملة مع تبديل فوري للاتجاه (RTL/LTR) وعزل النصوص اللاتينية |
| **v3.07** | 📋 **قائمة تطبيقات الجهاز المثبّتة** — تختار بالضغط بدل كتابة اسم الحزمة، وخيار `/data/system/packages.list` كاحتياط |
| **v3.08** | 💾 زر **حفظ الإعدادات** الفعلي + تصعيد تلقائي بـ `su` عند فتح الواجهة بلا جذر |
| **v3.09** | 📥 استيراد الكيبوكس تلقائياً + 📜 **سجل الإخفاء** + 🔄 تصفير المراقبة |
| **v3.10** | ⚡ **فتح لحظي** (قراءة النواة 4 أجزاء من الألف من الثانية بلا استدعاء `pm`) + تحميل القائمة في الخلفية + زر حفظ كبير متوهج |
| **v3.11** | 🔌 **إصلاح جذر الجسر**: `KsuWebUI Standalone` و `MMRL` يقبلان فقط **اسم دالة نصّي** — الآن يُدعمان مع KernelSU في وضع واحد تلقائياً |
| **v3.12** | 🔑 **ضمان الكيبوكس في `/data/adb/tricky_store/keybox.xml`** عند التثبيت وعند كل إقلاع |
| **v3.13** | 🖼️ **أيقونات التطبيقات الحقيقية** + بديل الحرف الملوّن |
| **v3.14** | ⚡ **ردّ فعل لحظي** (إلغاء `readState` بعد الحفظ + أيقونات عبر HTTP بلا جسر) + **زر «تحديد الكل» و«إلغاء الكل»** بضغطة مع عدّاد |
| **v3.15** | 🗑️ **حذف قسري فوري لأي إضافة/ملحق يخص TrickyStore** (كشف من `module.prop` + قائمة معرّفات + مسح عند كل إقلاع) + 🔗 **ربط مزدوج فوري** بين الوحدة الأم والمرافقة |

## 🧩 وحدة FALCON TRICKY المرافقة

وحدة مرئية في مدير الروت تعمل كـ **مرصد تخفٍّ** — تُثبَّت تلقائياً مع الوحدة الأم:

* 🔗 **الحذف متبادل وفوري**: حذف إحدى الوحدتين يحذف الأخرى نهائياً (سكربتا حذف + حراسة عند الإقلاع).
* 🛡️ **لا تُشغّل أي محرّك** — محرّك واحد فقط يملك `keystore2` (تشغيله مرتين = تجمّد الجهاز).
* 🗑️ **حذف قسري فوري** لأي وحدة أو ملحق يخص TrickyStore عند التثبيت وعند كل إقلاع — بالكشف من الاسم **و** `module.prop`، مع عدم المساس بـ `/data/adb/tricky_store` (كيبوكسك و`target.txt`).

### 📖 شرح كل قائمة في واجهة FALCON TRICKY

**🔝 الأعلى:** رادار + اسم الواجهة، وزر **⟳ تحديث** (يقرأ حالة الملفات من جديد — لحظي).

**🌐 شريط اللغات:** العربية · English · Türkçe · Русский — التبديل فوري، والنصوص اللاتينية مثل `@falcon_kernel` لا تنقلب.

**🔌 سطر الجسر:** هل الاتصال بجذر الجهاز يعمل؟ أهم قطعة تشخيص — إن ظهر «لا يوجد جسر» فافتح الواجهة من KernelSU / KernelSU-Next / KsuWebUI / MMRL.

**📊 البطاقات الأربع:**

| البطاقة | المعنى |
|---|---|
| تطبيق مخفي | كم تطبيقاً مخفياً الآن |
| حماية Google | هل الحزم الثلاث الإلزامية موجودة |
| الكيبوكس | **مخصّص ✔** يعمل · **مرفق ⚠** احتياطي (يفشل DEVICE/STRONG) · **مفقود** |
| المحرك | يعمل / متوقف — هل المحرك محقون في `keystore2` الآن |

**🎛️ لوحة التحكم:**

* **إخفاء التطبيقات الجديدة تلقائياً** — كل تطبيق تُثبّته بعد الآن يُخفى وحده خلال 10 ثوانٍ.
* **🎯 الإبقاء على الأساسي فقط** — تنظيف سريع يترك 3 حزم Google الإلزامية.
* **🔄 تصفير المراقبة** — يعتبر كل المثبّت الآن «أساساً»، فلا يُخفى تلقائياً إلا الجديد.
* **📜 سجل الإخفاء** — يقرأ `/data/adb/falcon/auto_hide.log`: الدليل المكتوب على أن الإخفاء التلقائي عمل فعلاً.
* **💾 حفظ الإعدادات** — يحفظ المفتاح واللغة فعلياً ويتحقق من الملف بعد الكتابة.
* **📥 استيراد كيبوكس** — يبحث في الوحدات و zygisk و payload و Downloads و `/data/misc` وينسخه إلى `/data/adb/tricky_store/keybox.xml`.
* **🩺 فحص الجسر** — تشخيص كامل (الجسر · الكتابة · الصلاحيات · المسارات) — أرسل نتيجته عند أي مشكلة.
* **📄 نسخ السجل** — نافذة بكل السجل لتحديده ونسخه.
* **📋 استعراض القائمة الخام** — يطبع `target.txt` سطراً سطراً كما هو على الجهاز.

**📱 قسم التطبيقات:** 🔎 بحث بثلاث طرق (اسم الحزمة · الاسم العربي · الاسم بأي من اللغات الأربع)، و4 تبويبات: **مخفي · المثبتة (الافتراضي) · الكل · مستخدم**. فوق القائمة زرّا **✔ تحديد الكل** و **✖ إلغاء الكل** مع عدّاد «قابل للإخفاء / قابل للإظهار» — يخفيان أو يُظهران **كل ما تراه أمامك** بضغطة واحدة (وتبقى حزم Google الثلاث محميّة). كل صفٍّ = دائرة الحالة + **أيقونة التطبيق** + اسم الحزمة + الاسم العربي + الوسوم (`إلزامي` · `مستثنى !` · `مستخدم` · `نظام` · `غير مثبّت`) + أزرار **إخفاء / إظهار**.

**➕ إضافة حزمة يدوياً:** لتطبيق لم يُثبَّت بعد وتريد إخفاءه مسبقاً.

**📜 سجل العمليات:** كل أمر مُغلَّف بمهلة زمنية — **لا يمكن أن يعلّق الجهاز**، والكتابة محصورة في ملف واحد: `/data/adb/tricky_store/target.txt`.

## ⚙️ المتطلبات

* أندرويد 10 (API 29) أو أحدث
* روت: **KernelSU-Next / Magisk / APatch**
* **Zygisk Next** v1.5.2 أو أحدث (`zygisksu`)
* ⚠️ مع إطفاء Zygisk المدمج داخل Magisk (فعّل أحدهما فقط)
* ℹ️ لواجهة FALCON TRICKY: تحتاج KernelSU / KernelSU-Next / KsuWebUI / MMRL (Magisk وحده لا يوفّر WebUI)

## 📥 التثبيت — 3 خطوات فقط

1️⃣ ثبّت ملف ZIP من مدير الروت
2️⃣ أعد تشغيل الجهاز
3️⃣ انتظر 15–20 دقيقة، ثم افحص Play Integrity **مرة واحدة فقط**

> 🔑 الكيبوكس يُنقل تلقائياً إلى `/data/adb/tricky_store/keybox.xml` — لا خطوة يدوية.
> 🔒 كيبوكسك الخاص في `/data/adb/falcon/keybox.xml` لا يُستبدل أبداً.

## ⛔ تنبيهات مهمة جداً

* 🚫 **لا تُغلق البوت لودر** — القفل غير مطلوب وهو خطير.
* 🚫 **لا تثبّت وحدة أو ملحقاً يخص TrickyStore** — يُحذف قسرياً عند التثبيت وعند الإقلاع لأن التكرار يُجمّد الجهاز (حقن مزدوج في `keystore2`).
* 🌀 **لا تُكرّر الفحص بسرعة** — جوجل تُرجع خطأً مؤقتاً (`-17`).
* 🧩 **المعرّف موحّد** (`playintegrityfix`) فتُستبدل الإضافة المشابهة تلقائياً.
* 🧹 الموديول **لا يمسح بيانات جوجل** ولا أي ملف تحت `/data/data` — حساباتك في متجر Play لا تُخرَج أبداً.

## 🗂️ أماكن الملفات

| المسار | الوصف |
|---|---|
| `/data/adb/tricky_store/target.txt` | قائمة التطبيقات المخفية |
| `/data/adb/tricky_store/keybox.xml` | الكيبوكس الفعّال |
| `/data/adb/falcon/keybox.xml` | كيبوكسك الخاص (لا يُستبدل) |
| `/data/adb/falcon/auto_hide.log` | سجل الإخفاء التلقائي |
| `/data/adb/falcon_icons/` | أيقونات التطبيقات المستخرجة (أرشيف) |
| `/data/adb/modules/falcon_tricky/webroot/icons/` | الأيقونات التي تقرأها الواجهة مباشرة (بلا جسر) + فهرس `_index.txt` |

## 🔗 الروابط

* 📥 **التحميل:** [FALCONINTEGITY_FIX_V3.15.zip](https://github.com/AHMED2111X/AHMED2111X/releases/download/v3.15/FALCONINTEGITY_FIX_V3.15.zip)
* 📢 **القناة الرسمية:** https://t.me/FALCON_KERNEL_PRO
* 👨‍💻 **تواصل المطور:** https://t.me/falcon_kernel
* 🐙 **مستودع التحديثات:** https://github.com/AHMED2111X/AHMED2111X

━━━━━━━━━━━━━━━━━━━━
## 🇬🇧 English Summary

**FALCON INTEGRITY FIX v3.15** — a complete root module that passes **Play Integrity 3/3** without locking the bootloader and without wiping any Google data (BASIC / DEVICE / STRONG).

* 🎭 **PIF fingerprint** — Pixel 6a (bluejay beta) with matching security patch `2026-09-05`.
* 🔐 **Keybox attestation** — open-source **Tricky Store OSS v3.1.0** hooking `keystore2`, so the unlocked bootloader is hidden from Google.
* 🩺 **Automatic RKP key repair** for Red Magic / ZTE / Nubia devices.
* ⚡ **Instant UI (v3.14)** — no more 10-second “operation in progress”: saving no longer re-lists packages, and app icons are served as plain files from the module webroot instead of travelling over the root bridge.
* ✔️ **Select all / Clear all (v3.14)** — hide or unhide every app currently on screen with one tap, with a live “can hide / can show” counter.
* 🗑️ **Forced cleanup of TrickyStore addons (v3.15)** — any module or add-on tied to the original Tricky Store is detected from its folder name **and** its `module.prop` (id + name) and **hard-deleted instantly** at install (plus a safety known-id list), then re-checked on every boot. Your engine data in `/data/adb/tricky_store` is never touched, and the description-only weak signal just disables instead of deleting.
* 🔗 **Instant two-way unlink (v3.15)** — removing either FALCON INTEGRITY FIX or FALCON TRICKY immediately removes the other one (with a guard flag so a running script is never deleted mid-execution, plus a boot-time orphan sweep).
* 📱 **FALCON TRICKY companion WebUI** in 4 languages (AR/EN/TR/RU) with a real **Save** button, instant load, auto-hide of newly installed apps, an on-device **hide log**, one-tap keybox import, and app icons extracted straight from the installed APKs.
* 🔑 Keybox is transferred automatically to `/data/adb/tricky_store/keybox.xml` on install and every boot.
* 🚫 Standalone `tricky_store` modules and any TrickyStore add-on are hard-removed at install and re-checked every boot (double injection into `keystore2` deadlocks the device).
* 🔒 Your Google accounts are never signed out — no `pm clear`, nothing under `/data/data` is touched.

**Install:** flash the ZIP → reboot → wait 15–20 min → check Play Integrity once.
**Requirements:** Android 10+, KernelSU-Next / Magisk / APatch, Zygisk Next.

━━━━━━━━━━━━━━━━━━━━
🦅 **FALCON INTEGRITY FIX** | المطور: **ABUFARID**
━━━━━━━━━━━━━━━━━━━━

`#Falcon_Integrity_Fix` `#PlayIntegrity` `#Root` `#KernelSU` `#Magisk` `#IntegrityFix` `#TrickyStore`
