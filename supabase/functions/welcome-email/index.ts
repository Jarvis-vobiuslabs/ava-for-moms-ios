import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY")!
const FROM = "Ava <hello@avaformoms.com>"
const ICON_URL = "https://raw.githubusercontent.com/Jarvis-vobiuslabs/ava-for-moms-ios/main/app-icon.png"

// ── Branded HTML email ────────────────────────────────────────────────────

function buildWelcomeEmail(name: string): string {
  const firstName = name?.split(" ")[0] || "there"
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Welcome to Ava</title>
</head>
<body style="margin:0;padding:0;background:#FFF6EF;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#FFF6EF;padding:40px 0;">
    <tr><td align="center">
      <table width="560" cellpadding="0" cellspacing="0" style="max-width:560px;width:100%;">

        <!-- Logo -->
        <tr><td align="center" style="padding-bottom:32px;">
          <img src="${ICON_URL}" width="72" height="72"
               alt="Ava" style="border-radius:18px;display:block;" />
        </td></tr>

        <!-- Hero card -->
        <tr><td style="background:linear-gradient(135deg,#F5B8A5,#D46A47);border-radius:24px;padding:40px 40px 36px;">
          <p style="margin:0 0 6px;font-size:13px;font-weight:700;letter-spacing:0.8px;color:rgba(255,255,255,0.85);text-transform:uppercase;">Welcome</p>
          <h1 style="margin:0 0 16px;font-size:32px;font-weight:800;color:#ffffff;line-height:1.15;letter-spacing:-0.5px;">
            Hey ${firstName}, I'm Ava 💛
          </h1>
          <p style="margin:0 0 28px;font-size:17px;line-height:1.6;color:rgba(255,255,255,0.92);">
            I'm your personal AI assistant — here to help you carry the mental load so you can breathe a little easier.
          </p>
          <a href="https://apps.apple.com/app/id6740244915"
             style="display:inline-block;background:#ffffff;color:#B04A2A;font-size:15px;font-weight:800;text-decoration:none;padding:14px 28px;border-radius:50px;">
            Open Ava →
          </a>
        </td></tr>

        <!-- What Ava does -->
        <tr><td style="padding:28px 0 0;">
          <table width="100%" cellpadding="0" cellspacing="0">
            <tr>
              <!-- Card 1 -->
              <td width="33%" style="padding-right:8px;">
                <table width="100%" cellpadding="0" cellspacing="0" style="background:#FFFCF6;border-radius:18px;padding:20px 16px;">
                  <tr><td style="font-size:28px;padding-bottom:10px;">🧠</td></tr>
                  <tr><td style="font-size:14px;font-weight:800;color:#3A2A1E;padding-bottom:6px;">Remembers everything</td></tr>
                  <tr><td style="font-size:12px;color:#7A6455;line-height:1.5;">Family, routines, preferences — all of it.</td></tr>
                </table>
              </td>
              <!-- Card 2 -->
              <td width="33%" style="padding:0 4px;">
                <table width="100%" cellpadding="0" cellspacing="0" style="background:#FFFCF6;border-radius:18px;padding:20px 16px;">
                  <tr><td style="font-size:28px;padding-bottom:10px;">📋</td></tr>
                  <tr><td style="font-size:14px;font-weight:800;color:#3A2A1E;padding-bottom:6px;">Handles the list</td></tr>
                  <tr><td style="font-size:12px;color:#7A6455;line-height:1.5;">Tasks, grocery, calendar — all in one place.</td></tr>
                </table>
              </td>
              <!-- Card 3 -->
              <td width="33%" style="padding-left:8px;">
                <table width="100%" cellpadding="0" cellspacing="0" style="background:#FFFCF6;border-radius:18px;padding:20px 16px;">
                  <tr><td style="font-size:28px;padding-bottom:10px;">🔒</td></tr>
                  <tr><td style="font-size:14px;font-weight:800;color:#3A2A1E;padding-bottom:6px;">Stays private</td></tr>
                  <tr><td style="font-size:12px;color:#7A6455;line-height:1.5;">Everything lives on your phone.</td></tr>
                </table>
              </td>
            </tr>
          </table>
        </td></tr>

        <!-- Tip -->
        <tr><td style="padding:24px 0 0;">
          <table width="100%" cellpadding="0" cellspacing="0" style="background:#FFFCF6;border-radius:18px;padding:24px 28px;">
            <tr><td>
              <p style="margin:0 0 8px;font-size:12px;font-weight:800;letter-spacing:0.8px;color:#D46A47;text-transform:uppercase;">Start here</p>
              <p style="margin:0;font-size:15px;line-height:1.6;color:#3A2A1E;">
                Open Ava and say hello. Tell her what's on your mind today — she'll start learning what matters to you and your family from the very first message.
              </p>
            </td></tr>
          </table>
        </td></tr>

        <!-- Footer -->
        <tr><td style="padding:32px 0 0;text-align:center;">
          <p style="margin:0 0 6px;font-size:13px;color:#B6A092;">
            Made with 💛 for moms everywhere
          </p>
          <p style="margin:0;font-size:12px;color:#B6A092;">
            <a href="https://avaformoms.com/privacy" style="color:#B6A092;text-decoration:underline;">Privacy Policy</a>
            &nbsp;·&nbsp;
            <a href="https://avaformoms.com/terms" style="color:#B6A092;text-decoration:underline;">Terms</a>
            &nbsp;·&nbsp;
            <a href="mailto:hello@avaformoms.com" style="color:#B6A092;text-decoration:underline;">Contact</a>
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

serve(async (req: Request) => {
  try {
    const { userId, email, name } = await req.json()

    // If we have a userId but no name, fetch it from profiles
    let displayName = name
    if (!displayName && userId) {
      const admin = createClient(
        Deno.env.get("SUPABASE_URL")!,
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
      )
      const { data } = await admin.from("profiles").select("name").eq("id", userId).single()
      displayName = data?.name
    }

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: FROM,
        to: [email],
        subject: `Welcome to Ava, ${displayName?.split(" ")[0] || "friend"} 💛`,
        html: buildWelcomeEmail(displayName || ""),
      }),
    })

    const result = await res.json()
    return new Response(JSON.stringify({ ok: res.ok, ...result }), {
      headers: { "Content-Type": "application/json" },
    })
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})
