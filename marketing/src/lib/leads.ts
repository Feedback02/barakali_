// Browser-side lead capture. Posts to our own /api/lead Cloudflare Pages
// Function (same origin), which verifies the Turnstile token server-side and
// inserts into Supabase. Keeping the insert server-side means the Supabase key
// is not shipped to the browser and the CAPTCHA secret stays private.

export type LeadTable = 'waitlist_signups' | 'merchant_leads';

export async function insertLead(
  table: LeadTable,
  row: Record<string, unknown>,
  token: string,
): Promise<void> {
  const res = await fetch('/api/lead', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ table, row, token }),
  });

  if (!res.ok) {
    throw new Error(`Lead submit failed: ${res.status}`);
  }
}
