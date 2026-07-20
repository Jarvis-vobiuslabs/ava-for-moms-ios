import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

// Higgsfield image generation — 10/month per user (all plans), async flow:
//   POST {prompt}                        → submits, returns {generationId} fast
//   POST {action:"check", generationId}  → polls Higgsfield once; downloads &
//                                          stores the image when completed
// Failed / moderated / expired generations flip to 'refunded' (doesn't count
// against the cap) and the app tells the user to try again.

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}
const MONTHLY_CAP = 10
const MODEL = "higgsfield-ai/soul/standard"
const EXPIRY_MINUTES = 10
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

    const body = await req.json()

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

    const key = Deno.env.get("HIGGSFIELD_API_KEY")!
    const secret = Deno.env.get("HIGGSFIELD_SECRET")!
    const hfAuth = { "Authorization": `Key ${key}:${secret}` }

    // ─────────────────────────────────────────────────────────────────────
    // action: "check" — poll one pending generation
    // ─────────────────────────────────────────────────────────────────────
    if (body.action === "check") {
      const genId = body.generationId
      if (!genId) return json({ error: "generationId required" }, 400)

      const { data: row } = await admin.from("image_generations")
        .select("id, user_id, status, image_path, hf_request_id, created_at")
        .eq("id", genId)
        .single()
      if (!row || row.user_id !== user.id) return json({ error: "not found" }, 404)

      if (row.status === "completed" && row.image_path) {
        return json({ imagePath: row.image_path, remaining: MONTHLY_CAP - await usedCount() })
      }
      if (row.status === "refunded") {
        return json({ error: "rejected", message: REFUND_MESSAGE, remaining: MONTHLY_CAP - await usedCount() })
      }

      const refund = async (): Promise<Response> => {
        await admin.from("image_generations").update({ status: "refunded" }).eq("id", genId)
        return json({ error: "rejected", message: REFUND_MESSAGE, remaining: MONTHLY_CAP - await usedCount() })
      }

      if (!row.hf_request_id) return await refund()

      const st = await fetch(`https://platform.higgsfield.ai/requests/${row.hf_request_id}/status`, { headers: hfAuth })
      if (st.ok) {
        const s = await st.json()
        if (s.status === "nsfw" || s.status === "failed") return await refund()
        if (s.status === "completed") {
          const imageUrl = s.images?.[0]?.url
          if (!imageUrl) return await refund()

          const imgRes = await fetch(imageUrl)
          if (!imgRes.ok) return await refund()
          const contentType = imgRes.headers.get("content-type") ?? "image/jpeg"
          const ext = contentType.includes("png") ? "png" : "jpg"
          const path = `${user.id}/gen-${genId}.${ext}`
          const blob = new Blob([await imgRes.arrayBuffer()], { type: contentType })
          const { error: upErr } = await admin.storage.from("chat-images")
            .upload(path, blob, { contentType, upsert: true })
          if (upErr) {
            console.error("storage upload failed:", upErr.message)
            return await refund()
          }
          await admin.from("image_generations")
            .update({ status: "completed", image_path: path })
            .eq("id", genId)
          return json({ imagePath: path, remaining: MONTHLY_CAP - await usedCount() })
        }
      }

      // Still queued / in progress — give up only after the expiry window
      const ageMinutes = (Date.now() - new Date(row.created_at).getTime()) / 60000
      if (ageMinutes > EXPIRY_MINUTES) return await refund()
      return json({ status: "pending" })
    }

    // ─────────────────────────────────────────────────────────────────────
    // default — submit a new generation
    // ─────────────────────────────────────────────────────────────────────
    const prompt = body.prompt
    if (!prompt || typeof prompt !== "string" || !prompt.trim()) {
      return json({ error: "prompt required" }, 400)
    }

    if (await usedCount() >= MONTHLY_CAP) {
      return json({
        error: "limit",
        message: `You've used all ${MONTHLY_CAP} image creations this month — they refresh on the 1st 💛`,
        remaining: 0,
      })
    }

    const { data: genRow, error: insErr } = await admin.from("image_generations")
      .insert({ user_id: user.id, prompt: prompt.trim(), status: "queued" })
      .select("id")
      .single()
    if (insErr || !genRow) return json({ error: "could not record generation" }, 500)
    const genId = genRow.id

    const submit = await fetch(`https://platform.higgsfield.ai/${MODEL}`, {
      method: "POST",
      headers: { ...hfAuth, "Content-Type": "application/json" },
      body: JSON.stringify({ prompt: prompt.trim(), aspect_ratio: "3:4", resolution: "720p" }),
    })
    if (!submit.ok) {
      console.error("higgsfield submit failed:", submit.status, await submit.text())
      await admin.from("image_generations").update({ status: "refunded" }).eq("id", genId)
      return json({ error: "rejected", message: REFUND_MESSAGE, remaining: MONTHLY_CAP - await usedCount() })
    }
    const submitData = await submit.json()
    const requestId = submitData.request_id ?? submitData.id
    if (!requestId) {
      await admin.from("image_generations").update({ status: "refunded" }).eq("id", genId)
      return json({ error: "rejected", message: REFUND_MESSAGE, remaining: MONTHLY_CAP - await usedCount() })
    }

    await admin.from("image_generations").update({ hf_request_id: requestId }).eq("id", genId)
    return json({ generationId: genId, remaining: MONTHLY_CAP - await usedCount() })
  } catch (err) {
    console.error("generate-image error:", err)
    return json({ error: String(err) }, 500)
  }
})
