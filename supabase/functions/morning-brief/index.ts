import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import Anthropic from "https://esm.sh/@anthropic-ai/sdk@0.24.0"

const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY")! })

function base64url(input: Uint8Array | string): string {
  const str = typeof input === "string" ? input : String.fromCharCode(...input)
  return btoa(str).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_")
}

async function createAPNsJWT(): Promise<string> {
  const pem    = Deno.env.get("APNS_PRIVATE_KEY")!
  const keyId  = Deno.env.get("APNS_KEY_ID")!
  const teamId = Deno.env.get("APNS_TEAM_ID")!
  const now    = Math.floor(Date.now() / 1000)
  const header  = base64url(JSON.stringify({ alg: "ES256", kid: keyId }))
  const payload = base64url(JSON.stringify({ iss: teamId, iat: now }))
  const input   = `${header}.${payload}`
  const keyData = pem.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\n|\r/g, "").replace(/\s/g, "")
  const keyBytes = Uint8Array.from(atob(keyData), c => c.charCodeAt(0))
  const privateKey = await crypto.subtle.importKey(
    "pkcs8", keyBytes, { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"]
  )
  const sig = await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, privateKey, new TextEncoder().encode(input))
  return `${input}.${base64url(new Uint8Array(sig))}`
}

async function sendPush(token: string, title: string, body: string) {
  const jwt      = await createAPNsJWT()
  const bundleId = Deno.env.get("APNS_BUNDLE_ID")!
  await fetch(`https://api.push.apple.com/3/device/${token}`, {
    method: "POST",
    headers: {
      "Authorization": `bearer ${jwt}`,
      "apns-topic":     bundleId,
      "apns-push-type": "alert",
      "apns-priority":  "10",
      "content-type":   "application/json",
    },
    body: JSON.stringify({ aps: { alert: { title, body }, sound: "default" } }),
  })
}

async function generateBrief(name: string, urgentCount: number, totalCount: number): Promise<string> {
  const res = await anthropic.messages.create({
    model: "claude-haiku-4-5-20251001",
    max_tokens: 100,
    messages: [{
      role: "user",
      content: `Write a warm, friendly morning notification for ${name}.
She has ${urgentCount} urgent task(s) and ${totalCount} total task(s) today.
Keep it under 100 characters, warm and encouraging, like a best friend.
No punctuation at the end. Just the message text, nothing else.`,
    }],
  })
  return res.content[0].type === "text" ? res.content[0].text.trim() : `Good morning ${name}! Ready for today?`
}

serve(async (_req: Request) => {
  try {
    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    // Get all users who have a device token
    const { data: tokens } = await admin
      .from("device_tokens")
      .select("user_id, token")

    if (!tokens?.length) {
      return new Response(JSON.stringify({ sent: 0 }), { headers: { "Content-Type": "application/json" } })
    }

    let sent = 0

    for (const { user_id, token } of tokens) {
      try {
        // Get profile + incomplete task count
        const [profileRes, tasksRes] = await Promise.all([
          admin.from("profiles").select("name").eq("id", user_id).single(),
          admin.from("tasks").select("id, priority").eq("user_id", user_id).eq("completed", false),
        ])

        const name         = profileRes.data?.name ?? "there"
        const tasks        = tasksRes.data ?? []
        const urgentCount  = tasks.filter((t: any) => t.priority === "urgent").length
        const totalCount   = tasks.length

        const briefBody = await generateBrief(name, urgentCount, totalCount)
        const title     = urgentCount > 0 ? `${urgentCount} urgent task${urgentCount > 1 ? "s" : ""} today` : "Good morning ☀️"

        await sendPush(token, title, briefBody)
        sent++
      } catch (err) {
        console.error(`Failed for user ${user_id}:`, err)
      }
    }

    return new Response(JSON.stringify({ sent }), { headers: { "Content-Type": "application/json" } })
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})
