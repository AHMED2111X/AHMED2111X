# FALCON COUNTER SERVER v4.0 — دليل النشر

هذا المجلد يحتوي نسخة مُصلحة من سيرفر العدّاد. لا تُغيّر رابط السيرفر في الوحدة؛
الاسم في `wrangler.toml` هو نفسه `falcon-counter-server`، لذا سيبقى الرابط:

```
https://falcon-counter-server.ahmedsibero199847-0ba.workers.dev
```

## ما الذي يختلف عن النسخة القديمة؟

- كان العدّاد يعتمد على متغيّر/ذاكرة داخل نسخة Worker واحدة. Cloudflare تشغّل
  عدة نسخ (Isolates) في مناطق مختلفة، فكل نسخة ترى رقماً مختلفاً أو صفراً.
- النسخة الجديدة تستخدم **Durable Object** واحدة اسمها `Counter`، وكل الطلبات
  تمرّ عبرها بالتسلسل، فيكون الرقم واحداً ودقيقاً لكل المستخدمين.
- لا يوجد أي اعتماد على Express أو Cors أو قاعدة بيانات خارجية، فزمن الاستجابة
  أقل (طلبات داخلية فقط).
- `POST /ping` يُسجّل الحضور ويُعيد العدد.
- `GET /count` و`GET /ping` يقرآن العدد فقط (لا يُسجّلان جهازاً)، لذلك فتح
  الواجهة لا يُحتسب كجهاز إضافي.
- TTL = 45 ثانية. الجهاز الذي يتوقف عن الإرسال أكثر من 45 ثانية يخرج تلقائياً.

## النشر عبر GitHub + Cloudflare (الطريقة التي تستخدمها)

1. افتح مستودع GitHub الخاص بالسيرفر:
   `https://github.com/AHMED2111X/falcon-counter-server`
2. استبدل الملفات الثلاثة `server.js` و`wrangler.toml` و`package.json`
   بالملفات الموجودة في هذا المجلد.
3. اعمل Commit على فرع `main`.
4. إذا كان المشروع مربوطاً بـ Cloudflare Workers Builds، سيبدأ النشر تلقائياً.
5. تأكد من وجود Binding باسم `COUNTER` مرتبط بالصنف `Counter`:
   - Cloudflare Dashboard ← Workers & Pages ← `falcon-counter-server`
   - Settings ← Bindings ← Durable Objects ← أضف `COUNTER` → `Counter`
   - أو اترك `wrangler.toml` يتولى ذلك أثناء `wrangler deploy`.
6. بعد النشر جرّب:

```bash
curl -s -X POST "https://falcon-counter-server.ahmedsibero199847-0ba.workers.dev/ping" \
  -H "Content-Type: application/json" \
  -d '{"deviceId":"test-123"}'
```

يجب أن ترى:

```json
{"ok":true,"onlineUsers":1,"updatedAt":...,"version":4}
```

ثم:

```bash
curl -s "https://falcon-counter-server.ahmedsibero199847-0ba.workers.dev/count"
```

## النشر اليدوي (بديل)

إذا كان لديك Node.js وWrangler:

```bash
cd server
npm install
npx wrangler login
npx wrangler deploy
```

> ملاحظة: أول نشر لـ Durable Object يحتاج تطبيق الترحيل `v1` الموجود في
> `wrangler.toml`. لا تحذف قسم `[[migrations]]`.

## إذا ظهر خطأ `new_sqlite_classes`

بعض الحسابات القديمة تحتاج `new_classes` بدلاً من `new_sqlite_classes`.
في هذه الحالة غيّر السطر داخل `[[migrations]]` إلى:

```toml
new_classes = ["Counter"]
```

ثم أعد النشر.

## اختبار سريع

- من المتصفح: افتح `COUNTER_DEMO.html` الموجود في المجلد الأعلى.
- من الهاتف: بعد تركيب ملف الـ ZIP التجريبي، افتح واجهة FALCON TRICKY.
  يجب أن يظهر العداد خلال ثوانٍ بدل `--` أو `0`.
- من Windows: استخدم أوامر curl أعلاه.
