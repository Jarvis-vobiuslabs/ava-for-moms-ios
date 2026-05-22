import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import Anthropic from "https://esm.sh/@anthropic-ai/sdk@0.24.0"

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY")! })

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS })

  try {
    const authHeader = req.headers.get("Authorization")!
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    )
    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401, headers: CORS })

    const { conversationId } = await req.json()

    // Get the last 20 messages from this conversation
    const { data: messages } = await supabase
      .from("messages")
      .select("role, content")
      .eq("conversation_id", conversationId)
      .order("created_at", { ascending: false })
      .limit(20)

    if (!messages || messages.length < 2) {
      return new Response(JSON.stringify({ extracted: 0 }), { headers: CORS })
    }

    const transcript = messages
      .reverse()
      .map((m: any) => `${m.role === "user" ? "User" : "Ava"}: ${m.content}`)
      .join("\n")

    // Use Haiku to extract memories cheaply
    const extraction = await anthropic.messages.create({
      model: "claude-haiku-4-5-20251001",
      max_tokens: 512,
      messages: [
        {
          role: "user",
          content: `Extract factual things worth remembering about the user from this conversation.
Focus on: preferences, routines, family details, recurring tasks, things they mentioned struggling with.
Do NOT include things already obvious from the conversation context.
Return ONLY a JSON array like: [{"key": "prefers evening workouts", "value": "yes, after kids are in bed", "category": "routine"}]
Category must be one of: preference, routine, family, health, general

Conversation:
${transcript}

JSON array (empty array [] if nothing new to remember):`,
        },
      ],
    })

    const content = extraction.content[0].type === "text" ? extraction.content[0].text : "[]"

    // Parse and save memories
    let memories: any[] = []
    try {
      const match = content.match(/\[[\s\S]*\]/)
      if (match) memories = JSON.parse(match[0])
    } catch {
      memories = []
    }

    const valid = memories.filter(
      (m: any) =>
        m.key && m.value &&
        ["preference", "routine", "family", "health", "general"].includes(m.category)
    )

    if (valid.length > 0) {
      await admin.from("ava_memories").upsert(
        valid.map((m: any) => ({
          user_id: user.id,
          key: m.key,
          value: m.value,
          category: m.category,
          updated_at: new Date().toISOString(),
        })),
        { onConflict: "user_id,key" }
      )
    }

    return new Response(JSON.stringify({ extracted: valid.length }), {
      headers: { ...CORS, "Content-Type": "application/json" },
    })
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...CORS, "Content-Type": "application/json" },
    })
  }
})
