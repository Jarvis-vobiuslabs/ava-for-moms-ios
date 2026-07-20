import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

// Higgsfield image generation — 10/month per user (all plans).
// Failed / moderated / timed-out generations are refunded (status 'refunded'
// doesn't count against the cap) and the user is told to try again.

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}
const MONTHLY_CAP = 10
const MODEL = "higgsfield-ai/soul/standard"
const REFUND_MESSAGE = "Hmm, that image didn't come through — your credit's been refunded, please try again 💛"

function json(obj: unknown, status = 200): Response {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  })
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS })

  try {
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) return json({ error: "Missing auth" }, 401)

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    )
    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) return json({ error: "Unauthorized" }, 401)

    const { prompt } = await req.json()
    if (!prompt || typeof prompt !== "string" || !prompt.trim()) {
      return json({ error: "prompt required" }, 400)
    }

    // ── Monthly cap ──────────────────────────────────────────────────────
    const monthStart = new Date()
    monthStart.setUTCDate(1)
    monthStart.setUTCHours(0, 0, 0, 0)

    const usedCount = async (): Promise<number> => {
      const { count } = await admin.from("image_generations")
        .select("id", { count: "exact", head: true })
        .eq("user_id", user.id)
        .neq("status", "refunded")
        .gte("created_at", monthStart.toISOString())
      return count ?? 0
    }

    if (await usedCount() >= MONTHLY_CAP) {
      return json({
        error: "limit",
        message: `You've used all ${MONTHLY_CAP} image creations this month — they refresh on the 1st 💛`,
        remaining: 0,
      })
    }

    // ── Record the attempt, then generate ────────────────────────────────
    const { data: genRow, error: insErr } = await admin.from("image_generations")
      .insert({ user_id: user.id, prompt: prompt.trim(), status: "queued" })
      .select("id")
      .single()
    if (insErr || !genRow) return json({ error: "could not record generation" }, 500)
    const genId = genRow.id

    const refund = async (message: string): Promise<Response> => {
      await admin.from("image_generations").update({ status: "refunded" }).eq("id", genId)
      return json({ error: "rejected", message, remaining: MONTHLY_CAP - await usedCount() })
    }

    const key = Deno.env.get("HIGGSFIELD_API_KEY")!
    const secret = Deno.env.get("HIGGSFIELD_SECRET")!
    const hfAuth = { "Authorization": `Key ${key}:${secret}` }

    const submit = await fetch(`https://platform.higgsfield.ai/${MODEL}`, {
      method: "POST",
      headers: { ...hfAuth, "Content-Type": "application/json" },
      body: JSON.stringify({ prompt: prompt.trim(), aspect_ratio: "3:4", resolution: "720p" }),
    })
    if (!submit.ok) {
      console.error("higgsfield submit failed:", submit.status, await submit.text())
      return await refund(REFUND_MESSAGE)
    }
    const submitData = await submit.json()
    const requestId = submitData.request_id ?? submitData.id
    if (!requestId) return await refund(REFUND_MESSAGE)

    // ── Poll until completed / failed / timeout ──────────────────────────
    let imageUrl: string | null = null
    const deadline = Date.now() + 110_000
    while (Date.now() < deadline) {
      await new Promise((r) => setTimeout(r, 2500))
      const st = await fetch(`https://platform.higgsfield.ai/requests/${requestId}/status`, { headers: hfAuth })
      if (!st.ok) continue
      const s = await st.json()
      if (s.status === "completed") {
        imageUrl = s.images?.[0]?.url ?? null
        break
      }
      if (s.status === "nsfw" || s.status === "failed") {
        return await refund(REFUND_MESSAGE)
      }
    }
    if (!imageUrl) return await refund(REFUND_MESSAGE)

    // ── Store in the user's private folder ───────────────────────────────
    const imgRes = await fetch(imageUrl)
    if (!imgRes.ok) return await refund(REFUND_MESSAGE)
    const contentType = imgRes.headers.get("content-type") ?? "image/jpeg"
    const ext = contentType.includes("png") ? "png" : "jpg"
    const path = `${user.id}/gen-${genId}.${ext}`
    const blob = new Blob([await imgRes.arrayBuffer()], { type: contentType })
    const { error: upErr } = await admin.storage.from("chat-images")
      .upload(path, blob, { contentType, upsert: true })
    if (upErr) {
      console.error("storage upload failed:", upErr.message)
      return await refund(REFUND_MESSAGE)
    }

    await admin.from("image_generations")
      .update({ status: "completed", image_path: path })
      .eq("id", genId)

    return json({ imagePath: path, remaining: MONTHLY_CAP - await usedCount() })
  } catch (err) {
    console.error("generate-image error:", err)
    return json({ error: String(err) }, 500)
  }
})
