import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import Anthropic from "https://esm.sh/@anthropic-ai/sdk@0.24.0"

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

const anthropic = new Anthropic({
  apiKey: Deno.env.get("ANTHROPIC_API_KEY")!,
})

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS })
  }

  try {
    // ── Auth ────────────────────────────────────────────────────────────
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing auth" }), { status: 401, headers: CORS })
    }

    // User-scoped client (respects RLS)
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    )

    // Service client for inserts that need to bypass RLS edge cases
    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401, headers: CORS })
    }

    // ── Request ─────────────────────────────────────────────────────────
    const { message, conversationId } = await req.json()
    if (!message || !conversationId) {
      return new Response(JSON.stringify({ error: "message and conversationId required" }), { status: 400, headers: CORS })
    }

    // ── User context ─────────────────────────────────────────────────────
    const [profileRes, subscriptionRes, messagesRes, memoriesRes] = await Promise.all([
      supabase.from("profiles").select("*, family_members(*)").eq("id", user.id).single(),
      supabase.from("subscriptions").select("tier, status").eq("user_id", user.id).single(),
      supabase.from("messages").select("role, content")
        .eq("conversation_id", conversationId)
        .order("created_at", { ascending: false })
        .limit(12),
      supabase.from("ava_memories").select("key, value, category")
        .eq("user_id", user.id)
        .order("updated_at", { ascending: false })
        .limit(25),
    ])

    const profile = profileRes.data
    const subscription = subscriptionRes.data
    const recentMessages = (messagesRes.data || []).reverse()
    const memories = memoriesRes.data || []

    // ── Model selection ──────────────────────────────────────────────────
    // Pro users get Sonnet, standard users get Haiku
    const isPro = subscription?.tier === "pro" &&
                  (subscription?.status === "active" || subscription?.status === "trial")
    const model = isPro ? "claude-sonnet-4-6" : "claude-haiku-4-5-20251001"

    // ── Ensure conversation row exists (iOS may fail to create it silently) ─
    await admin.from("conversations").upsert({
      id: conversationId,
      user_id: user.id,
      title: "Chat",
      last_message_at: new Date().toISOString(),
    }, { onConflict: "id", ignoreDuplicates: false })

    // ── Save user message ────────────────────────────────────────────────
    await admin.from("messages").insert({
      conversation_id: conversationId,
      user_id: user.id,
      role: "user",
      content: message,
      model,
    })

    // ── Build system prompt (cached) ─────────────────────────────────────
    const systemPrompt = buildSystemPrompt(profile, memories)

    // ── Conversation history ─────────────────────────────────────────────
    const history = recentMessages.map((m: any) => ({
      role: m.role as "user" | "assistant",
      content: m.content,
    }))
    history.push({ role: "user", content: message })

    // ── Stream from Claude ────────────────────────────────────────────────
    const claudeStream = await anthropic.messages.create({
      model,
      max_tokens: 1024,
      system: [
        {
          type: "text",
          text: systemPrompt,
          // Prompt caching: system prompt is stable per user — cache saves ~70% cost
          cache_control: { type: "ephemeral" },
        } as any,
      ],
      messages: history,
      stream: true,
    })

    const encoder = new TextEncoder()
    let fullResponse = ""
    let inputTokens = 0
    let outputTokens = 0

    const body = new ReadableStream({
      async start(controller) {
        try {
          for await (const event of claudeStream) {
            if (event.type === "content_block_delta" && event.delta.type === "text_delta") {
              const text = event.delta.text
              fullResponse += text
              controller.enqueue(encoder.encode(`data: ${JSON.stringify({ text })}\n\n`))
            }

            if (event.type === "message_delta" && event.usage) {
              outputTokens = event.usage.output_tokens
            }

            if (event.type === "message_start" && event.message.usage) {
              inputTokens = event.message.usage.input_tokens
            }

            if (event.type === "message_stop") {
              // Save assistant response
              await admin.from("messages").insert({
                conversation_id: conversationId,
                user_id: user.id,
                role: "assistant",
                content: fullResponse,
                model,
                input_tokens: inputTokens,
                output_tokens: outputTokens,
              })

              // Update conversation timestamp
              await admin.from("conversations")
                .update({ last_message_at: new Date().toISOString() })
                .eq("id", conversationId)

              controller.enqueue(encoder.encode(`data: [DONE]\n\n`))
              controller.close()
            }
          }
        } catch (err) {
          controller.enqueue(encoder.encode(`data: ${JSON.stringify({ error: String(err) })}\n\n`))
          controller.close()
        }
      },
    })

    return new Response(body, {
      headers: {
        ...CORS,
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        "X-Model": model,
      },
    })
  } catch (err: any) {
    console.error("chat function error:", err)
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...CORS, "Content-Type": "application/json" },
    })
  }
})

// ── System prompt builder ──────────────────────────────────────────────────
// This is what makes each user's Ava feel personal.
// Cached by Claude so it's only billed once per TTL window (~5 min).

function buildSystemPrompt(profile: any, memories: any[]): string {
  const family = profile?.family_members || []
  const partner = family.find((m: any) => m.relationship === "partner")
  const kids = family.filter((m: any) => m.relationship === "child")

  // Build family line without nested template literals (avoids Deno parser issues)
  const familyParts: string[] = []
  if (partner) familyParts.push("Partner: " + partner.name)
  if (kids.length) {
    const kidNames = kids.map((k: any) => k.age ? k.name + " (" + k.age + ")" : k.name).join(", ")
    familyParts.push("Kids: " + kidNames)
  }
  const familyLine = familyParts.join(", ")

  const memoriesText = memories.length
    ? memories.map((m: any) => "- " + m.key + ": " + m.value).join("\n")
    : "Still getting to know you."

  const name = profile?.name || "you"
  const workStatus = profile?.work_status?.replace(/_/g, " ") || ""
  const loadAreas = profile?.mental_load_areas?.join(", ") || ""
  const today = new Date().toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric", year: "numeric" })

  const lines = [
    "You are Ava, " + name + "'s warm, brilliant personal assistant. Think of yourself as the most organised best friend she's ever had: someone who remembers everything, judges nothing, and always has her back.",
    "",
    "## Who you're talking to",
    "Name: " + name,
    familyLine ? "Family: " + familyLine : "",
    workStatus ? "Work: " + workStatus : "",
    profile?.has_school_pickup ? "Does school pickup: yes" : "",
    loadAreas ? "What weighs on her most: " + loadAreas : "",
    "",
    "## What you know about " + name,
    memoriesText,
    "",
    "## How to talk",
    "- Warm, direct, like a best friend - never robotic or corporate",
    "- Use " + name + "'s name occasionally (not every message)",
    "- Keep replies under 120 words unless she asks for more detail",
    "- Proactively spot things she might have missed based on her life context",
    "- When she's venting, listen first - don't rush to solutions",
    "- You can use a single emoji where it fits naturally",
    "",
    "## What you can help with",
    "Calendar, tasks, grocery lists, meal ideas, family scheduling, managing the mental load, reminders, thinking things through, and just being there.",
    "",
    "Today's date: " + today,
  ]

  return lines.filter(l => l !== null && l !== undefined).join("\n")
}
