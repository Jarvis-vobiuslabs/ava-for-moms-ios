import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

// ── APNs JWT (uses Web Crypto — no external deps needed) ──────────────────

function base64url(input: Uint8Array | string): string {
  const str = typeof input === "string"
    ? input
    : String.fromCharCode(...input)
  return btoa(str).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_")
}

async function createAPNsJWT(): Promise<string> {
  const pem     = Deno.env.get("APNS_PRIVATE_KEY")!
  const keyId   = Deno.env.get("APNS_KEY_ID")!
  const teamId  = Deno.env.get("APNS_TEAM_ID")!
  const now     = Math.floor(Date.now() / 1000)

  const header  = base64url(JSON.stringify({ alg: "ES256", kid: keyId }))
  const payload = base64url(JSON.stringify({ iss: teamId, iat: now }))
  const input   = `${header}.${payload}`

  const keyData = pem.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\n|\r/g, "").replace(/\s/g, "")
  const keyBytes = Uint8Array.from(atob(keyData), c => c.charCodeAt(0))

  const privateKey = await crypto.subtle.importKey(
    "pkcs8", keyBytes,
    { name: "ECDSA", namedCurve: "P-256" },
    false, ["sign"]
  )

  const sig = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    privateKey,
    new TextEncoder().encode(input)
  )

  return `${input}.${base64url(new Uint8Array(sig))}`
}

// ── Send one push ─────────────────────────────────────────────────────────

async function sendPush(
  deviceToken: string,
  title: string,
  body: string,
  data: Record<string, unknown> = {}
): Promise<{ ok: boolean; status: number }> {
  const jwt      = await createAPNsJWT()
  const bundleId = Deno.env.get("APNS_BUNDLE_ID")!

  const res = await fetch(
    `https://api.push.apple.com/3/device/${deviceToken}`,
    {
      method: "POST",
      headers: {
        "Authorization": `bearer ${jwt}`,
        "apns-topic":     bundleId,
        "apns-push-type": "alert",
        "apns-priority":  "10",
        "content-type":   "application/json",
      },
      body: JSON.stringify({
        aps: { alert: { title, body }, sound: "default" },
        ...data,
      }),
    }
  )

  return { ok: res.ok, status: res.status }
}

// ── Handler ───────────────────────────────────────────────────────────────

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS })

  try {
    const authHeader = req.headers.get("Authorization")!
    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    // Verify caller
    const userClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    )
    const { data: { user }, error } = await userClient.auth.getUser()
    if (error || !user) return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401, headers: CORS })

    const { userId, title, body, data: extraData } = await req.json()

    // Fetch device token for target user (allow sending to self, or admin-called)
    const { data: tokenRow } = await admin
      .from("device_tokens")
      .select("token")
      .eq("user_id", userId ?? user.id)
      .single()

    if (!tokenRow?.token) {
      return new Response(JSON.stringify({ error: "No device token" }), { status: 404, headers: CORS })
    }

    const result = await sendPush(tokenRow.token, title, body, extraData ?? {})

    return new Response(JSON.stringify(result), {
      headers: { ...CORS, "Content-Type": "application/json" },
    })
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...CORS, "Content-Type": "application/json" },
    })
  }
})
