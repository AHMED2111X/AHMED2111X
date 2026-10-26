/**
 * FALCON COUNTER SERVER v4.0
 * ---------------------------------------------------------------------------
 * عدّاد مستخدمين نشطين لحظي ودقيق لوحدة FALCON INTEGRITY FIX.
 *
 * لماذا Durable Object؟
 *   التخزين في متغيّر عام داخل Worker عادي يكون لكل نسخة/منطقة (Isolate/PoP)
 *   على حدة، فتظهر أرقام مختلفة أو صفر للمستخدمين. Durable Object واحدة
 *   (global) تجمع كل الأجهزة في مكان واحد، فتحصل على رقم واحد صحيح للجميع.
 *
 * واجهات البرمجة:
 *   POST /ping   {"deviceId":"..."}  ← تُسجّل الجهاز وتُعيد العدد (service.sh)
 *   GET  /ping                        ← قراءة العدد فقط (لا تُسجّل جهازاً)
 *   GET  /count                       ← قراءة العدد فقط (الواجهة الجديدة)
 *   GET  /health | /stats             ← فحص الصحة + العدد
 *   GET  /                            ← رسالة نصية
 *   OPTIONS *                         ← CORS
 *
 * استجابة نموذجية:
 *   {"ok":true,"onlineUsers":12,"updatedAt":1792975373015,"version":4}
 *
 * ملاحظة: TTL افتراضي 45 ثانية. الجهاز يُعتبر متصلاً إذا أرسل Ping خلال آخر
 * 45 ثانية. service.sh يُرسل كل 6-8 ثوانٍ، والواجهة تقرأ كل 5 ثوانٍ.
 */

const DEFAULT_TTL_MS = 45_000;
const SAVE_EVERY_MS = 10_000;
const PRUNE_EVERY_MS = 2_000;
const MAX_DEVICES = 50_000;

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Cache-Control, X-Requested-With",
  "Access-Control-Max-Age": "86400",
  "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
  "X-Content-Type-Options": "nosniff",
};

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...CORS_HEADERS,
      "Content-Type": "application/json; charset=utf-8",
    },
  });
}

function cleanDeviceId(value) {
  if (typeof value !== "string") return "";
  const id = value.trim().slice(0, 128);
  return /^[A-Za-z0-9._:-]+$/.test(id) ? id : "";
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    if (request.method === "GET" && (url.pathname === "/" || url.pathname === "")) {
      return new Response("Falcon Counter Server v4 is active on Cloudflare Workers!", {
        headers: { ...CORS_HEADERS, "Content-Type": "text/plain; charset=utf-8" },
      });
    }

    const isPingPath = url.pathname === "/ping" || url.pathname === "/update";
    const isReadPath =
      url.pathname === "/count" ||
      url.pathname === "/stats" ||
      url.pathname === "/health" ||
      (isPingPath && request.method === "GET");

    if (!isPingPath && !isReadPath) {
      return jsonResponse({ ok: false, error: "not_found" }, 404);
    }

    let deviceId = cleanDeviceId(url.searchParams.get("deviceId"));

    if (request.method === "POST" && isPingPath) {
      const contentType = (request.headers.get("content-type") || "").toLowerCase();
      if (contentType.includes("application/json")) {
        const body = await request.json().catch(() => null);
        if (body && typeof body.deviceId === "string") {
          deviceId = cleanDeviceId(body.deviceId);
        }
      } else {
        const text = await request.text().catch(() => "");
        const params = new URLSearchParams(text);
        deviceId = cleanDeviceId(params.get("deviceId")) || deviceId;
      }
    }

    // لا نُسجّل جهازاً فارغاً أو غير صالح؛ نُعيد القراءة فقط.
    const wantsPing = request.method === "POST" && isPingPath && deviceId !== "";

    const id = env.COUNTER.idFromName("global");
    const stub = env.COUNTER.get(id);

    const internal = new URL("https://counter.internal/" + (wantsPing ? "ping" : "count"));
    if (wantsPing) internal.searchParams.set("deviceId", deviceId);

    const result = await stub.fetch(internal.toString(), { method: "GET" });
    const data = await result.json().catch(() => ({ onlineUsers: 0 }));

    return jsonResponse({
      ok: true,
      onlineUsers: Number(data.onlineUsers) || 0,
      updatedAt: Number(data.updatedAt) || Date.now(),
      version: 4,
    });
  },
};

/**
 * Durable Object واحدة لكل العدّاد (global).
 * كل الطلبات تمرّ من هنا بالتسلسل، فلا تفقد أي عملية تحديث.
 */
export class Counter {
  constructor(state, env) {
    this.state = state;
    this.env = env;
    this.sessions = new Map();
    this.lastSave = 0;
    this.lastPrune = 0;

    // تحميل اللقطة المحفوظة قبل معالجة أي طلب (مرة واحدة عند الإقلاع).
    this.ready = this.state.blockConcurrencyWhile(async () => {
      try {
        const saved = await this.state.storage.get("sessions");
        if (Array.isArray(saved)) {
          for (const entry of saved) {
            if (Array.isArray(entry) && entry.length === 2) {
              const id = cleanDeviceId(String(entry[0]));
              const ts = Number(entry[1]);
              if (id && Number.isFinite(ts)) this.sessions.set(id, ts);
            }
          }
        }
      } catch (_) {
        // لا نُفشل الخدمة إذا كانت اللقطة تالفة؛ نبدأ من صفر.
      }
    });
  }

  async fetch(request) {
    await this.ready;

    const url = new URL(request.url);
    const now = Date.now();
    const ttl = Math.max(15_000, Number(this.env.ONLINE_TTL_MS) || DEFAULT_TTL_MS);

    let changed = false;

    if (url.pathname === "/ping") {
      const id = cleanDeviceId(url.searchParams.get("deviceId"));
      if (id) {
        this.sessions.set(id, now);
        changed = true;
        if (this.sessions.size > MAX_DEVICES) this.prune(now, ttl, true);
      }
    }

    // تنظيف دوري سريع (كل ثانيتين) حتى ينخفض العدد فور انتهاء TTL.
    if (now - this.lastPrune >= PRUNE_EVERY_MS) {
      this.prune(now, ttl, false);
      this.lastPrune = now;
    }

    // حفظ دوري فقط، حتى لا نضيف زمن كتابة لكل Ping.
    if (changed && now - this.lastSave >= SAVE_EVERY_MS) {
      this.lastSave = now;
      try {
        await this.state.storage.put("sessions", Array.from(this.sessions.entries()));
      } catch (_) {
        // الحفظ اختياري: إذا فشل نُكمل من الذاكرة.
      }
    }

    return jsonResponse({
      ok: true,
      onlineUsers: this.sessions.size,
      updatedAt: now,
    });
  }

  prune(now, ttl, force) {
    for (const [id, ts] of this.sessions) {
      if (now - ts > ttl) this.sessions.delete(id);
    }
    if (force && this.sessions.size > MAX_DEVICES) {
      const sorted = Array.from(this.sessions.entries()).sort((a, b) => a[1] - b[1]);
      const extra = sorted.length - MAX_DEVICES;
      for (let i = 0; i < extra; i++) this.sessions.delete(sorted[i][0]);
    }
  }
}
