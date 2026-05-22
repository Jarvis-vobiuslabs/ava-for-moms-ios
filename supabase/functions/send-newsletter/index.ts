import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY")!
const FROM = "Ava <hello@avaformoms.com>"
const ICON_URL = "https://raw.githubusercontent.com/Jarvis-vobiuslabs/ava-for-moms-ios/main/app-icon.png"

// ── Newsletter HTML wrapper ───────────────────────────────────────────────
// Pass your content HTML as `bodyHtml` — this wraps it in the branded shell.

function buildNewsletterEmail(subject: string, preheader: string, bodyHtml: string): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${subject}</title>
</head>
<body style="margin:0;padding:0;background:#FFF6EF;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;">
  <!-- Preheader (shows in inbox preview, hidden in email body) -->
  <div style="display:none;max-height:0;overflow:hidden;color:#FFF6EF;">${preheader}</div>

  <table width="100%" cellpadding="0" cellspacing="0" style="background:#FFF6EF;padding:40px 0;">
    <tr><td align="center">
      <table width="560" cellpadding="0" cellspacing="0" style="max-width:560px;width:100%;">

        <!-- Header -->
        <tr><td style="background:linear-gradient(135deg,#F5B8A5,#D46A47);border-radius:24px 24px 0 0;padding:28px 32px;text-align:left;">
          <table width="100%" cellpadding="0" cellspacing="0">
            <tr>
              <td>
                <img src="${ICON_URL}" width="44" height="44"
                     alt="Ava" style="border-radius:11px;display:block;" />
              </td>
              <td style="padding-left:12px;">
                <p style="margin:0;font-size:18px;font-weight:800;color:#ffffff;letter-spacing:-0.3px;">Ava for Moms</p>
                <p style="margin:0;font-size:12px;color:rgba(255,255,255,0.8);font-weight:600;">Monthly newsletter</p>
              </td>
            </tr>
          </table>
        </td></tr>

        <!-- Body -->
        <tr><td style="background:#FFFCF6;border-radius:0 0 24px 24px;padding:36px 40px;">
          ${bodyHtml}
        </td></tr>

        <!-- Footer -->
        <tr><td style="padding:28px 0 0;text-align:center;">
          <p style="margin:0 0 6px;font-size:13px;color:#B6A092;">
            You're receiving this because you subscribe to the Ava newsletter.
          </p>
          <p style="margin:0;font-size:12px;color:#B6A092;">
            <a href="https://avaformoms.com/privacy" style="color:#B6A092;text-decoration:underline;">Privacy Policy</a>
            &nbsp;·&nbsp;
            <a href="{{unsubscribe_url}}" style="color:#B6A092;text-decoration:underline;">Unsubscribe</a>
          </p>
          <p style="margin:8px 0 0;font-size:11px;color:#B6A092;">
            © 2026 Vobius Labs Inc. · avaformoms.com
          </p>
        </td></tr>

      </table>
    </td></tr>
  </table>
</body>
</html>`
}

// ── Handler ───────────────────────────────────────────────────────────────
// POST body: { subject, preheader, bodyHtml, recipientEmails? }
// If recipientEmails is omitted, fetches all profile emails from Supabase.

serve(async (req: Request) => {
  try {
    const { subject, preheader, bodyHtml, recipientEmails } = await req.json()

    if (!subject || !bodyHtml) {
      return new Response(JSON.stringify({ error: "subject and bodyHtml required" }), { status: 400 })
    }

    const html = buildNewsletterEmail(subject, preheader ?? subject, bodyHtml)

    let emails: string[] = recipientEmails ?? []

    // If no recipients provided, fetch from Supabase auth users
    if (emails.length === 0) {
      const admin = createClient(
        Deno.env.get("SUPABASE_URL")!,
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
      )
      // Get all users from auth (page through if needed)
      const { data: { users } } = await admin.auth.admin.listUsers({ perPage: 1000 })
      emails = users.map(u => u.email).filter(Boolean) as string[]
    }

    if (emails.length === 0) {
      return new Response(JSON.stringify({ sent: 0, message: "No recipients" }))
    }

    // Resend supports batch sending up to 100 at a time
    let sent = 0
    const batchSize = 50
    for (let i = 0; i < emails.length; i += batchSize) {
      const batch = emails.slice(i, i + batchSize)
      const res = await fetch("https://api.resend.com/emails/batch", {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${RESEND_API_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(batch.map(to => ({
          from: FROM,
          to: [to],
          subject,
          html,
        }))),
      })
      if (res.ok) sent += batch.length
    }

    return new Response(JSON.stringify({ sent, total: emails.length }), {
      headers: { "Content-Type": "application/json" },
    })
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})
