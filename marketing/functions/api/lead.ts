// Cloudflare Pages Function: POST /api/lead
//
// The forms submit here instead of hitting Supabase directly, so the Supabase
// key stays server-side and the Cloudflare Turnstile token can be verified with
// the secret (a static site cannot verify a CAPTCHA client-side).
//
// Graceful activation:
//   - If TURNSTILE_SECRET is set, a valid Turnstile token is REQUIRED.
//     If it is not set, submissions pass without a CAPTCHA (current behavior).
//   - Inserts use SUPABASE_SERVICE_ROLE_KEY if present (RLS bypass, so the anon
//     insert path can be locked down later); otherwise it falls back to the
//     PUBLIC_SUPABASE_ANON_KEY (anon insert-only RLS), so it works immediately.
//
// Env (set in Cloudflare Pages -> Settings -> Environment variables):
//   TURNSTILE_SECRET            (secret; from the Turnstile widget)
//   SUPABASE_URL or PUBLIC_SUPABASE_URL
//   SUPABASE_SERVICE_ROLE_KEY   (secret; optional but recommended)
//   PUBLIC_SUPABASE_ANON_KEY    (fallback insert key)

const ALLOWED: Record<string, string[]> = {
  waitlist_signups: ["email", "phone", "locale", "source"],
  merchant_leads: [
    "business_name",
    "contact_name",
    "phone",
    "email",
    "city",
    "message",
    "locale",
  ],
};

const MAXLEN: Record<string, number> = {
  email: 320,
  phone: 32,
  source: 64,
  business_name: 160,
  contact_name: 120,
  city: 80,
  message: 2000,
};

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function str(v: unknown): string {
  return typeof v === "string" ? v.trim() : "";
}

// Pragmatic single-line email shape check (no full RFC 5322): local@domain.tld,
// no spaces. Rejects obvious junk before it reaches the DB.
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

async function verifyTurnstile(
  secret: string,
  token: string,
  ip: string,
): Promise<boolean> {
  if (!token) return false;
  const form = new URLSearchParams({ secret, response: token });
  if (ip) form.set("remoteip", ip);
  try {
    const r = await fetch(
      "https://challenges.cloudflare.com/turnstile/v0/siteverify",
      { method: "POST", body: form },
    );
    const data = (await r.json()) as { success?: boolean };
    return data.success === true;
  } catch {
    return false;
  }
}

export const onRequestPost = async (context: {
  request: Request;
  env: Record<string, string | undefined>;
}): Promise<Response> => {
  const { request, env } = context;

  let payload: {
    table?: string;
    row?: Record<string, unknown>;
    token?: string;
  };
  try {
    payload = await request.json();
  } catch {
    return json(400, { error: "bad_request" });
  }

  const table = payload.table ?? "";
  const cols = ALLOWED[table];
  if (!cols) return json(400, { error: "bad_table" });
  const rowIn = payload.row;
  if (!rowIn || typeof rowIn !== "object") {
    return json(400, { error: "bad_row" });
  }

  // CAPTCHA (only enforced once the secret is configured). If the secret is
  // absent this endpoint accepts anonymous submissions with NO bot protection,
  // so log loudly: in production TURNSTILE_SECRET must be set (see README).
  if (env.TURNSTILE_SECRET) {
    const ip = request.headers.get("CF-Connecting-IP") ?? "";
    const ok = await verifyTurnstile(
      env.TURNSTILE_SECRET,
      str(payload.token),
      ip,
    );
    if (!ok) return json(403, { error: "captcha_failed" });
  } else {
    console.warn("lead: TURNSTILE_SECRET unset — accepting without CAPTCHA");
  }

  // Whitelist + length-bound the columns; drop anything else.
  const row: Record<string, string> = {};
  for (const key of cols) {
    const v = str((rowIn as Record<string, unknown>)[key]);
    if (!v) continue;
    if (MAXLEN[key] && v.length > MAXLEN[key]) {
      return json(400, { error: "too_long", field: key });
    }
    row[key] = v;
  }
  const locale = ["ru", "uz", "en"].includes(row.locale) ? row.locale : "ru";
  row.locale = locale;

  // Reject a malformed email rather than storing junk (both tables accept email).
  if (row.email && !EMAIL_RE.test(row.email)) {
    return json(400, { error: "bad_email" });
  }

  // Shape validation mirroring the DB CHECKs (fail fast).
  if (table === "waitlist_signups" && !row.email && !row.phone) {
    return json(400, { error: "missing_contact" });
  }
  if (table === "merchant_leads" && (!row.business_name || !row.phone)) {
    return json(400, { error: "missing_required" });
  }

  const url = env.SUPABASE_URL ?? env.PUBLIC_SUPABASE_URL;
  const key = env.SUPABASE_SERVICE_ROLE_KEY ?? env.PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !key) return json(500, { error: "server_misconfigured" });

  const res = await fetch(`${url}/rest/v1/${table}`, {
    method: "POST",
    headers: {
      apikey: key,
      Authorization: `Bearer ${key}`,
      "Content-Type": "application/json",
      Prefer: "return=minimal",
    },
    body: JSON.stringify(row),
  });
  if (!res.ok) return json(502, { error: "insert_failed" });

  return json(200, { ok: true });
};
