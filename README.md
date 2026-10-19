🦅🔥 **FALCON INTEGRITY FIX — الإصدار v3.19** 🔥🦅

━━━━━━━━━━━━━━━━━━━━
**الإصدار الذي أنهى مشكلة** ❌ «الجهاز غير معتمد» **و** ❌ «Bootloader Unlocked» **في فحص Play Integrity!**
بلا إغلاق بوت لودر · بلا مسح تلقائي لأي بيانات جوجل · لا خروج من الحسابات إلا بزرّ «المسح الشامل» الذي تضغطه بنفسك.
━━━━━━━━━━━━━━━━━━━━

## 🎯 ما هو الموديول؟

وحدة روت متكاملة تجمع أفضل ما في عالم تجاوز فحص الحماية، مع واجهة عربية كاملة:

| المحرّك | الوظيفة |
|---|---|
| 🎭 **بصمة PIF** | بصمة Pixel 6a (bluejay · beta · Canary ZP11.260918.007) مع رقعة أمنية مطابقة تماماً: `2026-10-05` |
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

## 🆕 Nuevo in v3.19 — الأيقونات فوراً (ksu://icon) + دعم كل محركات Zygisk + تحسينات الواجهة

⚡ **الأيقونات صارت فورية وحقيقية (الإصلاح النهائي):**

* 🔍 **الاكتشاف:** مشروع TrickyAddonModule لا يستخرج أيقونات من الـAPK إطلاقاً؛ بل يطلبها من **مضيف الواجهة** عبر بروتوكول خاص `ksu://icon/<اسم الحزمة>` — المضيف (KsuWebUIStandalone / MMRL WebUI-X) هو من يجلب أيقونة المشغّل الحقيقية من نظام أندرويد ويعرضها فوراً. بلا unzip، بلا busybox، بلا dex.
* 🎯 **المطبَّق في FALCON:** كل صف تطبيق يطلب `ksu://icon/<pkg>` أولاً → **كل الأيقونات فوراً** (المستخدمة والنظامية وفي كل الفلاتر). فحص استباقي (حزمة `android`) يكتشف دعم المضيف؛ وإن لم يدعمه يُعاد رسم القائمة فوراً بالبديل (أيقونتنا المستخرجة ← الحرف الملوّن). مسار الاستخراج القديم بقي كخطة بديلة.
* 🛡️ **سقوط آمن ثلاثي:** `ksu://icon` ← `icons/<pkg>.png` ← الحرف الملوّن — لا يخسر أي جهاز شيئاً.

🧩 **دعم كل محركات Zygisk (بطلبك):**

* ✅ **التثبيت:** يتعرّف على كل المحركات ويعطي رسالة توافق: ZygiskNext (بالمعرّفين `zygisk_next` و `zygisksu`) · NeoZygisk · ReZygisk · BreZygisk (بالمعرّفين) · Zygisk المدمج في Magisk — مع تحذير التعارض.
* 📋 **بطاقة الوصف:** بدل نقش ثابت تعرض اسم المحرك الفعلي وإصداره: `🟢 ZygiskNext vX` / `🟢 NeoZygisk` / `🟢 ReZygisk` / `🟢 BreZygisk` / `🟢 Zygisk (Magisk)`.

🛠️ **تحسينات الواجهة والثبات (v3.19):**

* 🛟 **إصلاح «الواجهة الفارغة»**: حارس أخطاء إقلاع (`jsErrBar`) + فحص آلي: كل معرّف `$('id')` يجب أن يكون موجوداً في الصفحة.
* ✍️ **سطر المؤلف** بالصيغة الحرفية: `author=ABUFARID | Telegram:@falcon_kernel`.
* 📋 **الواجهة تفتح افتراضياً على فلتر «مستخدم»** (قائمة صغيرة).
* 💬 **وصف مختصر احترافي** لبطاقة FALCON TRICKY في مدير الروت.
* 🔧 **محرك أيقونات dex (app_process)** كطبقة أخيرة (v3.19f) + **busybox مدمج** (v3.19e) + **أداة فك ضغط مدمجة**.

📊 **النتيجة:** 94/94 فحصاً آلياً ناجحاً (بما في ذلك فحص كل محركات Zygisk وبروتوكول ksu://icon).

## 🆕 الجديد في v3.18 — إصلاح «جلب Keybox (إنترنت)» نهائياً + واجهة «مرصد التخفي» النهائية

🧩 **زر «جلب Keybox (إنترنت)» يعمل الآن على كل الهواتف — إصلاح جذري:**

* 🔍 **السبب الحقيقي**: كان الزر يعتمد على `curl` (غير موجود على أغلب الأجهزة)، ثم `wget -T 15` — وأداة أندرويد الافتراضية لا تدعم الخيار `-T` فتتعطّل فوراً — مع مصدر تنزيل واحد فقط: أي حجب = فشل كامل.
* 🔄 **4 مصادر بالتتابع** حتى ينجح أحدها: Falcon raw ← Falcon GitHub ← TrickyStoreOSS ← davidepalma.it (خارج GitHub).
* 🛠️ **3 أدوات تنزيل بالتدرّج**: `curl` ← `busybox wget` (بحث تلقائي في 4 مسارات) ← `wget` النظامي بصيغتين متوافقتين مع toybox.
* ✅ **فحص صارم للملف**: `<AndroidAttestation>` + مفتاح خاص + **شهادتان على الأقل** — يرفض صفحات الأخطاء نهائياً.
* 📋 **سجل تشخيصي كامل**: أي مصدر جُرّب؟ أي أداة؟ أين توقّف التنزيل بالضبط؟ — «راجع السجل» أصبح مفيداً فعلاً.
* ⚡ **تثبيت شامل بعد النجاح**: `tricky_store` + `falcon` + `teesim` + إعادة تشغيل خدمات جوجل فوراً.

🖥️ **واجهة «مرصد التخفي» الموحّدة الجديدة:**

* 🎨 تصميم بطاقة أنيق: اسم الوحدة في المنتصف، أيقونات نصية بلا صور.
* 🔁 زر «تحديث» عريض في صف كامل تحت العنوان مباشرة.
* 🧰 قسم **«صيانة الوحدة الأم»**: الأزرار فوق بعضها + **شرح منسدل لكل زر** (زر واحد مفتوح في كل مرة).

🌐 **ترجمة كاملة 100%:** كل النصوص تتبدّل فوراً — **بما فيها شروح أزرار الصيانة وتقارير التشخيص** — أربع لغات، والعربية تظهر فقط عند اختيارها.

📣 **أزرار تيليجرام داخل الواجهة (أسفل الشاشة):** 👤 المطوّر @falcon_kernel · 📣 القناة @FALCON_KERNEL_PRO.

🗑️ **حماية قسرية متبادلة محسّنة:** حذف أي إضافة قديمة (TrickyStore / SafetyNet / PlayIntegrity / PIF…) قبل التثبيت + الوحدتان تراقبان بعضهما (حذف إحداهما يحذف الأخرى فوراً).

👤 **بيانات المطوّر في `module.prop`:** `ABUFARID (أبو فريد) | Telegram: @falcon_kernel`.

## 🆕 الجديد في v3.16 — سجل حي بلا انتظار + اعتماد متجر Play + العداد

📜 **مشكلة السجل «المنتظر» انتهت نهائياً — وُجد السبب الجذري:**

* 🧠 السبب كان دقيقاً: العملية الخلفية تُبقي **قناة الاتصال بالواجهة معلّقة** حتى تنتهي، فتنتهي مهلة البداية (20 ثانية) قبل أن يبدأ البثّ أصلاً — «انتهت المهلة» بلا أي سطر.
* ⚡ الحل: فصل واصفات العملية الخلفية (`>/dev/null 2>&1`) — الآن **كل عملية طويلة تبثّ سطورها لحظياً**: فحص/إصلاح/إجبار RKP · البصمة · فحص CRL · تحديث Canary · المسح الشامل — مع **طمأنة كل 20 ثانية** ونتيجة واضحة «✅ انتهى بنجاح» أو فشل. (أُثبت بالقياس: 4 ثوانٍ انتظار ← صفر).
* 🖥️ الإصلاح في **الواجهتين** — الرئيسية و FALCON TRICKY.

✅ **إجبار اعتماد متجر Play (Certified) — في الواجهة الرئيسية:**

* زر جديد يعيد ضبط **متجر Play وحده** ليقرأ حالة الاعتماد من جديد — **حسابك لا يُمس** (محفوظ في خدمات جوجل GMS لا في المتجر).

💣 **المسح الشامل لجوجل (الخيار الأخير) — في الواجهتين:**

* يمسح بيانات **متجر Play + خدمات جوجل (GMS) + إطار خدمات جوجل (GSF)** ثم **يعيد التشغيل تلقائياً** — للاعتماد المستعصي فقط.
* ⛔ يُسجّل خروجك من حسابات جوجل (تُضيفها من جديد) — أما صورك وملفاتك وتطبيقاتك فلا تُمس إطلاقاً.

📊 **عداد المستخدمين النشطين في FALCON TRICKY:**

* نفس عداد الواجهة الرئيسية (نقطة خضراء نابضة + العدد الحقيقي) — في أعلى القائمة، ومترجم بأربع لغات.

🩺 **ومن v3.16 أيضاً:** فحص إبطال الكيبوكس (CRL) بزر مستقل في الواجهتين · تحديث بصمة Canary عند الطلب · سطر إقلاع محروس · تحسين سرعة الواجهة الرئيسية.

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

## ✨ ما أضافته سلسلة التحديثات v3.05 → v3.19

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
| **v3.16** | 📜 **سجل حي لكل عملية طويلة** (إصلاح جذري لتعليق الجسر) + ✅ **إجبار اعتماد متجر Play** + 💣 **مسح شامل لجوجل** (اختياري) + 📊 **عداد المستخدمين النشطين** في FALCON TRICKY + 🩺 فحص CRL وتحديث Canary |
| **v3.17** | 🖥️ **واجهة موحّدة**: أدوات الوحدة الأم انتقلت نهائياً إلى FALCON TRICKY + 🧰 قسم صيانة بشرح منسدل لكل زر + 🔁 زر تحديث تحت العنوان + 📣 أزرار تيليجرام |
| **v3.18** | 🧩 **إصلاح جذري لزر «جلب Keybox (إنترنت)»** (4 مصادر + 3 أدوات تنزيل + فحص صارم + سجل تشخيصي) + 🌐 **ترجمة كاملة** للشروح والتقارير + 🎨 الواجهة النهائية |
| **v3.19** | ⚡ **أيقونات فوراً (ksu://icon)** + 🧩 دعم كل محركات Zygisk + 🛟 إصلاح واجهة فارغة + 💬 وصف FALCON TRICKY + 🔧 busybox/dex |

## 🧩 وحدة FALCON TRICKY المرافقة

وحدة مرئية في مدير الروت تعمل كـ **مرصد تخفٍّ** — تُثبَّت تلقائياً مع الوحدة الأم:

* 🔗 **الحذف متبادل وفوري**: حذف إحدى الوحدتين يحذف الأخرى نهائياً (سكربتا حذف + حراسة عند الإقلاع).
* 🛡️ **لا تُشغّل أي محرّك** — محرّك واحد فقط يملك `keystore2` (تشغيله مرتين = تجمّد الجهاز).
* 🗑️ **حذف قسري فوري** لأي وحدة أو ملحق يخص TrickyStore عند التثبيت وعند كل إقلاع — بالكشف من الاسم **و** `module.prop`، مع عدم المساس بـ `/data/adb/tricky_store` (كيبوكسك و`target.txt`).
* 📣 **أزرار تيليجرام أسفل الواجهة**: المطوّر **@falcon_kernel** — والقناة **@FALCON_KERNEL_PRO**.

### 📖 شرح كل قائمة في واجهة FALCON TRICKY

**🔝 الأعلى:** رادار + اسم الواجهة + **📊 عداد المستخدمين النشطين** (نقطة خضراء نابضة + العدد الحقيقي)، وزر **⟳ تحديث** (يقرأ حالة الملفات من جديد — لحظي).

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
* **🩺 فحص الإبطال (CRL)** — يفحص هل كيبوكسك أُبطل من جوجل عبر قائمة الإبطال الرسمية (بلا طباعة أي محتوى مفاتيح في السجل).
* **💣 مسح شامل لجوجل (الخيار الأخير)** — يمسح بيانات المتجر + GMS + GSF ثم **يعيد التشغيل تلقائياً** — يُخرج الحسابات، فلا تستخدمه إلا إن استعصى الاعتماد.
* **🩺 فحص الجسر** — تشخيص كامل (الجسر · الكتابة · الصلاحيات · المسارات) — أرسل نتيجته عند أي مشكلة.
* **📄 نسخ السجل** — نافذة بكل السجل لتحديده ونسخه.
* **📋 استعراض القائمة الخام** — يطبع `target.txt` سطراً سطراً كما هو على الجهاز.
* **🧰 صيانة الوحدة الأم** — 12 أداة (كيبوكس ذكي/جلب إنترنت · RKP · خدمات جوجل · اعتماد المتجر · SOTER · بصمة · محرك) مع **شرح منسدل يظهر تحت كل زر عند الضغط**.
* **📣 أزرار تيليجرام** — أسفل الواجهة: المطوّر @falcon_kernel · القناة @FALCON_KERNEL_PRO.

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
* 🧹 الموديول **لا يمسح أي بيانات من تلقاء نفسه** — لا شيء يُمسح إلا بضغطتك: «إجبار اعتماد متجر Play» (المتجر وحده، وحسابك لا يُمس) أو «💣 المسح الشامل لجوجل» (وهو وحده الذي يُخرج الحسابات — باختيارك أنت).

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

* 📥 **التحميل:** [FALCONINTEGITY_FIX_V3.19.zip](https://github.com/AHMED2111X/AHMED2111X/releases/download/v3.19/FALCONINTEGITY_FIX_V3.19.zip)
* 📢 **القناة الرسمية:** https://t.me/FALCON_KERNEL_PRO
* 👨‍💻 **تواصل المطور:** https://t.me/falcon_kernel
* 🐙 **مستودع التحديثات:** https://github.com/AHMED2111X/AHMED2111X

━━━━━━━━━━━━━━━━━━━━
## 🇬🇧 English Summary

**FALCON INTEGRITY FIX v3.19** — a complete root module that passes **Play Integrity 3/3** without locking the bootloader and without any automatic wipe (BASIC / DEVICE / STRONG).

* 🎭 **PIF fingerprint** — Pixel 6a (bluejay beta · Canary ZP11.260918.007) with matching security patch `2026-10-05`.
* 🔐 **Keybox attestation** — open-source **Tricky Store OSS v3.1.0** hooking `keystore2`, so the unlocked bootloader is hidden from Google.
* 🧩 **Keybox fetch fixed (v3.18)** — the “Fetch keybox (internet)” button now works on every phone: it used to depend on `curl` (missing on most devices) and then `wget -T` (unsupported by Android's default wget), from a single source. Now: **4 sources in order** (Falcon raw → Falcon GitHub → TrickyStoreOSS → davidepalma.it) + **3 download tools** in a fallback ladder (`curl` → `busybox wget` → system `wget`) + **strict validation** (root tag + private key + at least 2 certificates) + a **staged diagnostic log** showing exactly where it stopped.
* 🖥️ **Unified Stealth Radar UI (v3.17/3.18)** — refined card design, full-width refresh button under the title, a maintenance section with **per-button collapsible explanations**, **complete 4-language localization** (including maintenance descriptions and diagnostic reports), and Telegram footer buttons (developer + official channel).
* 🩺 **Automatic RKP key repair** for Red Magic / ZTE / Nubia devices.
* ⚡ **Instant UI (v3.14)** — no more 10-second “operation in progress”: saving no longer re-lists packages, and app icons are served as plain files from the module webroot instead of travelling over the root bridge.
* ✔️ **Select all / Clear all (v3.14)** — hide or unhide every app currently on screen with one tap, with a live “can hide / can show” counter.
* 🗑️ **Forced cleanup of TrickyStore addons (v3.15)** — any module or add-on tied to the original Tricky Store is detected from its folder name **and** its `module.prop` (id + name) and **hard-deleted instantly** at install (plus a safety known-id list), then re-checked on every boot. Your engine data in `/data/adb/tricky_store` is never touched, and the description-only weak signal just disables instead of deleting.
* 🔗 **Instant two-way unlink (v3.15)** — removing either FALCON INTEGRITY FIX or FALCON TRICKY immediately removes the other one (with a guard flag so a running script is never deleted mid-execution, plus a boot-time orphan sweep).
* 📜 **Live progress everywhere (v3.16)** — root cause found and fixed: the background operation used to hold the bridge pipe open, so the UI hit its 20 s timeout before streaming even started. Now every long operation streams its lines live with a 20 s reassurance and a clear success/fail result (measured: 4 s wait → 0).
* ✅ **Force Play certification (v3.16)** — a button that resets the Play Store alone so it re-reads the certification status; your Google account is never touched (it lives in GMS).
* 💣 **Full Google wipe (v3.16, last resort)** — clears Play Store + GMS + GSF data and reboots automatically; it signs you out of Google accounts (your photos, files and apps are untouched).
* 📊 **Active-users counter in FALCON TRICKY (v3.16)** — the same live counter as the main UI, in all 4 languages.
* 🩺 **CRL keybox-revocation check (both UIs) + on-demand Canary fingerprint updater + guarded boot line (v3.16).**
* 📱 **FALCON TRICKY companion WebUI** in 4 languages (AR/EN/TR/RU) with a real **Save** button, instant load, auto-hide of newly installed apps, an on-device **hide log**, one-tap keybox import, and app icons extracted straight from the installed APKs.
* ⚡ **Instant app icons (v3.19):** icons are now fetched directly from the Android system via the WebUI host's `ksu://icon/<package>` protocol (same technique as TrickyAddonModule) — real icons appear instantly for every app, with a safe fallback (extracted icon → letter avatar). Plus: **support for every Zygisk engine** (ZygiskNext · NeoZygisk · ReZygisk · BreZygisk · built-in Magisk) in install messages + module card.
* 🔑 Keybox is transferred automatically to `/data/adb/tricky_store/keybox.xml` on install and every boot.
* 🚫 Standalone `tricky_store` modules and any TrickyStore add-on are hard-removed at install and re-checked every boot (double injection into `keystore2` deadlocks the device).
* 🔒 Nothing is ever wiped automatically — the Play-certification reset (Play Store only; your account lives in GMS) and the optional last-resort full Google wipe only run when you tap their buttons. The full wipe signs you out of Google accounts — your choice; photos, files and apps are untouched.

**Install:** flash the ZIP → reboot → wait 15–20 min → check Play Integrity once.
**Requirements:** Android 10+, KernelSU-Next / Magisk / APatch, Zygisk Next.

━━━━━━━━━━━━━━━━━━━━
🦅 **FALCON INTEGRITY FIX** | المطور: **ABUFARID**
━━━━━━━━━━━━━━━━━━━━

`#Falcon_Integrity_Fix` `#PlayIntegrity` `#Root` `#KernelSU` `#Magisk` `#IntegrityFix` `#TrickyStore`
