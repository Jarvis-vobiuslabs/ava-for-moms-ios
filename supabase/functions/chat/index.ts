import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import Anthropic from "https://esm.sh/@anthropic-ai/sdk@0.24.0"

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

const anthropic = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY")! })

// ── Tool definitions ─────────────────────────────────────────────────────────

const TOOLS: Anthropic.Tool[] = [
  {
    name: "add_calendar_event",
    description: "Add an event to the user's Ava calendar. Use this when the user asks Ava to schedule, book, or add something to their calendar.",
    input_schema: {
      type: "object",
      properties: {
        title:     { type: "string", description: "Event title" },
        starts_at: { type: "string", description: "Start time in ISO 8601 format, e.g. 2026-05-24T14:00:00Z" },
        ends_at:   { type: "string", description: "End time in ISO 8601 format" },
        detail:    { type: "string", description: "Optional notes or location" }
      },
      required: ["title", "starts_at", "ends_at"]
    }
  },
  {
    name: "add_grocery_item",
    description: "Add one or more items to the user's grocery list. Use this when the user asks Ava to add something to the shopping list.",
    input_schema: {
      type: "object",
      properties: {
        items: {
          type: "array",
          description: "List of items to add",
          items: {
            type: "object",
            properties: {
              name:     { type: "string", description: "Item name" },
              quantity: { type: "string", description: "Optional quantity, e.g. '2' or '1 litre'" }
            },
            required: ["name"]
          }
        }
      },
      required: ["items"]
    }
  },
  {
    name: "add_task",
    description: "Add a task or to-do item to the user's task list.",
    input_schema: {
      type: "object",
      properties: {
        title:    { type: "string", description: "Task title" },
        priority: { type: "string", enum: ["normal", "urgent"], description: "Task priority" },
        note:     { type: "string", description: "Optional note" }
      },
      required: ["title"]
    }
  },
  {
    name: "save_note",
    description: "Save an important note for the user. Use this when the user shares something they want remembered: a password, PIN, where they left something important, school form locations, or any information they explicitly ask you to note down.",
    input_schema: {
      type: "object",
      properties: {
        title:   { type: "string", description: "Short descriptive title, e.g. 'WiFi Password' or 'School Forms Location'" },
        content: { type: "string", description: "The full note content" }
      },
      required: ["title", "content"]
    }
  }
]

// ── Timezone helpers ──────────────────────────────────────────────────────────

// Compute UTC offset in minutes from an IANA timezone identifier.
// e.g. "America/Chicago" in CDT → -300, in CST → -360
function getOffsetMinutesFromTz(tz: string): number {
  try {
    const now = new Date()
    const parts = new Intl.DateTimeFormat("en-US", {
      timeZone: tz, hour12: false,
      year: "numeric", month: "2-digit", day: "2-digit",
      hour: "2-digit", minute: "2-digit", second: "2-digit",
    }).formatToParts(now)
    const get = (t: string) => parseInt(parts.find(p => p.type === t)?.value ?? "0")
    const h = get("hour") % 24
    const asUtc = Date.UTC(get("year"), get("month") - 1, get("day"), h, get("minute"), get("second"))
    return Math.round((asUtc - now.getTime()) / 60000)
  } catch {
    return 0
  }
}

// ── Tool executor ────────────────────────────────────────────────────────────

// Strip any timezone from Claude's timestamp and reattach the user's real offset.
// This ensures "3pm" is always stored as 3pm local, regardless of what Claude appended.
function applyUserOffset(ts: string, offsetMinutes: number): string {
  if (!ts) return ts
  const bare = ts.replace(/Z$/, "").replace(/[+-]\d{2}:\d{2}$/, "")
  const sign = offsetMinutes >= 0 ? "+" : "-"
  const h = String(Math.floor(Math.abs(offsetMinutes) / 60)).padStart(2, "0")
  const m = String(Math.abs(offsetMinutes) % 60).padStart(2, "0")
  return bare + sign + h + ":" + m
}

async function executeTool(name: string, input: any, admin: any, userId: string, offsetMinutes: number): Promise<string> {
  if (name === "add_calendar_event") {
    const { error } = await admin.from("calendar_events").insert({
      user_id:   userId,
      title:     input.title,
      detail:    input.detail || null,
      starts_at: applyUserOffset(input.starts_at, offsetMinutes),
      ends_at:   applyUserOffset(input.ends_at, offsetMinutes),
      color_hex: "#D46A47",
      source:    "ava",
      all_day:   false,
    })
    if (error) throw new Error("calendar insert failed: " + error.message)
    return "Event added: " + input.title
  }

  if (name === "add_grocery_item") {
    // Find or create active grocery list
    const { data: lists } = await admin.from("grocery_lists")
      .select("id").eq("user_id", userId).eq("archived", false).limit(1)
    let listId: string
    if (lists && lists.length > 0) {
      listId = lists[0].id
    } else {
      const { data: newList, error: listErr } = await admin.from("grocery_lists")
        .insert({ user_id: userId, archived: false }).select("id").single()
      if (listErr) throw new Error("grocery list create failed: " + listErr.message)
      listId = newList.id
    }
    const rows = (input.items as any[]).map((item: any) => ({
      list_id:  listId,
      user_id:  userId,
      name:     item.name,
      quantity: item.quantity || null,
      checked:  false,
      added_by: "ava",
    }))
    const { error } = await admin.from("grocery_items").insert(rows)
    if (error) throw new Error("grocery insert failed: " + error.message)
    return "Added to grocery list: " + (input.items as any[]).map((i: any) => i.name).join(", ")
  }

  if (name === "add_task") {
    const { error } = await admin.from("tasks").insert({
      user_id:   userId,
      title:     input.title,
      note:      input.note || null,
      priority:  input.priority || "normal",
      completed: false,
    })
    if (error) throw new Error("task insert failed: " + error.message)
    return "Task added: " + input.title
  }

  if (name === "save_note") {
    const { error } = await admin.from("notes").insert({
      user_id: userId,
      title:   input.title,
      content: input.content,
      source:  "ava",
    })
    if (error) throw new Error("note insert failed: " + error.message)
    return "Note saved: " + input.title
  }

  throw new Error("Unknown tool: " + name)
}

// ── Main handler ─────────────────────────────────────────────────────────────

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS })
  }

  try {
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing auth" }), { status: 401, headers: CORS })
    }

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
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401, headers: CORS })
    }

    const { message, conversationId, timezone, timezoneOffsetMinutes } = await req.json()
    if (!message || !conversationId) {
      return new Response(JSON.stringify({ error: "message and conversationId required" }), { status: 400, headers: CORS })
    }

    // Resolve UTC offset: prefer IANA name (handles DST correctly), fall back to numeric, then UTC
    const resolvedOffset: number = timezone
      ? getOffsetMinutesFromTz(timezone)
      : (typeof timezoneOffsetMinutes === "number" ? timezoneOffsetMinutes : 0)

    // ── Load user context in parallel ────────────────────────────────────
    const [profileRes, subscriptionRes, messagesRes, memoriesRes, notesRes] = await Promise.all([
      supabase.from("profiles").select("*, family_members(*)").eq("id", user.id).single(),
      supabase.from("subscriptions").select("tier, status").eq("user_id", user.id).maybeSingle(),
      supabase.from("messages").select("role, content")
        .eq("conversation_id", conversationId)
        .order("created_at", { ascending: false }).limit(12),
      supabase.from("ava_memories").select("key, value, category")
        .eq("user_id", user.id)
        .order("updated_at", { ascending: false }).limit(25),
      supabase.from("notes").select("title, content")
        .eq("user_id", user.id)
        .order("updated_at", { ascending: false }).limit(30),
    ])

    const profile      = profileRes.data
    const subscription = subscriptionRes.data
    const history      = (messagesRes.data || []).reverse().map((m: any) => ({
      role: m.role as "user" | "assistant",
      content: m.content,
    }))
    const memories = memoriesRes.data || []
    const notes    = notesRes.data    || []

    const isPro = subscription?.tier === "pro" &&
                  (subscription?.status === "active" || subscription?.status === "trial")
    const model = isPro ? "claude-sonnet-4-6" : "claude-haiku-4-5-20251001"

    const isFirstMessage = history.length === 0
    const systemPrompt = buildSystemPrompt(profile, memories, notes, timezone, resolvedOffset, isFirstMessage)

    // ── Ensure conversation exists ───────────────────────────────────────
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

    history.push({ role: "user", content: message })

    // ── Stream from Claude with tool support ─────────────────────────────
    const encoder = new TextEncoder()
    let fullResponse = ""
    let inputTokens  = 0
    let outputTokens = 0
    const toolsExecuted: string[] = []

    const body = new ReadableStream({
      async start(controller) {
        try {
          // ── Pass 1: initial call with tools ──────────────────────────
          const stream1 = await anthropic.messages.create({
            model,
            max_tokens: 1024,
            system:  [{ type: "text", text: systemPrompt }] as any,
            tools:   TOOLS as any,
            messages: history,
            stream:  true,
          })

          // Collect content blocks and stream text
          const pass1Content: any[] = []
          let stopReason = "end_turn"

          for await (const event of stream1 as any) {
            if (event.type === "content_block_start") {
              pass1Content.push({ ...event.content_block, inputStr: "", text: "" })
            }
            if (event.type === "content_block_delta") {
              const blk = pass1Content[event.index]
              if (event.delta.type === "text_delta") {
                blk.text += event.delta.text
                fullResponse += event.delta.text
                controller.enqueue(encoder.encode("data: " + JSON.stringify({ text: event.delta.text }) + "\n\n"))
              }
              if (event.delta.type === "input_json_delta") {
                blk.inputStr += event.delta.partial_json
              }
            }
            if (event.type === "message_delta") {
              if (event.delta?.stop_reason) stopReason = event.delta.stop_reason
              if (event.usage) outputTokens = event.usage.output_tokens
            }
            if (event.type === "message_start" && event.message?.usage) {
              inputTokens = event.message.usage.input_tokens
            }
          }

          // ── Pass 2: execute tools and get follow-up if needed ────────
          if (stopReason === "tool_use") {
            const toolUseBlocks = pass1Content.filter((b: any) => b.type === "tool_use")
            const toolResultContent: any[] = []

            for (const blk of toolUseBlocks) {
              let toolInput: any = {}
              try { toolInput = JSON.parse(blk.inputStr || "{}") } catch (_) { /* */ }

              let resultText = ""
              try {
                resultText = await executeTool(blk.name, toolInput, admin, user.id, resolvedOffset)
                toolsExecuted.push(blk.name)
              } catch (e) {
                resultText = "Error: " + String(e)
              }

              toolResultContent.push({
                type: "tool_result",
                tool_use_id: blk.id,
                content: resultText,
              })
            }

            // Notify iOS which tools ran so it can refresh the right stores
            if (toolsExecuted.length > 0) {
              controller.enqueue(encoder.encode("data: " + JSON.stringify({ tools: toolsExecuted }) + "\n\n"))
            }

            // Build follow-up messages
            const assistantMsg = {
              role: "assistant" as const,
              content: pass1Content.map((b: any) => {
                if (b.type === "text")     return { type: "text", text: b.text }
                if (b.type === "tool_use") return { type: "tool_use", id: b.id, name: b.name, input: JSON.parse(b.inputStr || "{}") }
                return b
              }),
            }
            const toolResultMsg = { role: "user" as const, content: toolResultContent }

            const stream2 = await anthropic.messages.create({
              model,
              max_tokens: 512,
              system:   [{ type: "text", text: systemPrompt }] as any,
              messages: [...history, assistantMsg, toolResultMsg],
              stream:   true,
            })

            fullResponse = "" // replace with the spoken confirmation
            for await (const event of stream2 as any) {
              if (event.type === "content_block_delta" && event.delta.type === "text_delta") {
                fullResponse += event.delta.text
                controller.enqueue(encoder.encode("data: " + JSON.stringify({ text: event.delta.text }) + "\n\n"))
              }
              if (event.type === "message_delta" && event.usage) {
                outputTokens += event.usage.output_tokens
              }
            }
          }

          // ── Save assistant response and finish ───────────────────────
          await admin.from("messages").insert({
            conversation_id: conversationId,
            user_id:         user.id,
            role:            "assistant",
            content:         fullResponse,
            model,
            input_tokens:    inputTokens,
            output_tokens:   outputTokens,
          })

          await admin.from("conversations")
            .update({ last_message_at: new Date().toISOString() })
            .eq("id", conversationId)

          controller.enqueue(encoder.encode("data: [DONE]\n\n"))
          controller.close()

          // Background memory extraction
          const session = await supabase.auth.getSession()
          const token = session.data.session?.access_token
          if (token) {
            extractMemoriesBackground(conversationId, token)
          }

        } catch (err) {
          controller.enqueue(encoder.encode("data: " + JSON.stringify({ error: String(err) }) + "\n\n"))
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
    console.error("chat error:", err)
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...CORS, "Content-Type": "application/json" },
    })
  }
})

// ── Background memory extraction ─────────────────────────────────────────────

function extractMemoriesBackground(conversationId: string, token: string) {
  const url = Deno.env.get("SUPABASE_URL") + "/functions/v1/extract-memory"
  fetch(url, {
    method: "POST",
    headers: { "Authorization": "Bearer " + token, "Content-Type": "application/json" },
    body: JSON.stringify({ conversationId }),
  }).catch(() => { /* best effort */ })
}

// ── System prompt builder ─────────────────────────────────────────────────────

function buildSystemPrompt(profile: any, memories: any[], notes: any[], timezone: string | undefined, resolvedOffset: number, isFirstMessage: boolean = false): string {
  const family  = profile?.family_members || []
  const partner = family.find((m: any) => m.relationship === "partner")
  const kids    = family.filter((m: any) => m.relationship === "child")

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

  const name       = profile?.name || "you"
  const workStatus = profile?.work_status?.replace(/_/g, " ") || ""
  const loadAreas  = profile?.mental_load_areas?.join(", ") || ""

  const tz = timezone || "UTC"
  const absH = Math.floor(Math.abs(resolvedOffset) / 60)
  const absM = Math.abs(resolvedOffset) % 60
  const sign = resolvedOffset >= 0 ? "+" : "-"
  const offsetStr = sign + String(absH).padStart(2, "0") + ":" + String(absM).padStart(2, "0")
  const exampleDate = new Date().toLocaleDateString("en-US", { year: "numeric", month: "2-digit", day: "2-digit", timeZone: tz }).replace(/(\d+)\/(\d+)\/(\d+)/, "$3-$1-$2")
  const isoExample = exampleDate + "T14:00:00" + offsetStr

  const today = new Date().toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric", year: "numeric", timeZone: tz })

  const lines = [
    "You are Ava, " + name + "'s warm, brilliant personal assistant. You are the most organised best friend she has ever had: you remember everything, judge nothing, and always have her back.",
    "",
    "## Who you are talking to",
    "Name: " + name,
    familyLine    ? "Family: " + familyLine    : "",
    workStatus    ? "Work: "   + workStatus    : "",
    profile?.has_school_pickup ? "Does school pickup: yes" : "",
    loadAreas     ? "Mental load areas: " + loadAreas : "",
    "",
    "## What you know about " + name,
    memoriesText,
    "",
    "## How to talk",
    "- Warm, direct, like a best friend - never robotic or corporate",
    "- Use " + name + "'s name occasionally (not every message)",
    "- Keep replies under 120 words unless she asks for more detail",
    "- When she's venting, listen first - do not rush to solutions",
    "- Proactively spot things she might have missed",
    "",
    notes.length ? "## Notes saved for " + name : "",
    notes.length ? notes.map((n: any) => "- " + n.title + ": " + n.content).join("\n") : "",
    notes.length ? "" : "",
    "## Actions you can take",
    "You have tools to add calendar events, grocery items, tasks, and save notes.",
    "When the user asks you to add or note something, USE THE TOOL - do not just say you will do it.",
    "Use save_note when the user shares a password, PIN, important location, or anything they want to remember.",
    "After using a tool, confirm briefly what you did in a warm, natural way.",
    "IMPORTANT: Always use the user's local time when setting starts_at and ends_at. Include the UTC offset in the ISO 8601 string (e.g. " + isoExample + "). Never use UTC (Z suffix) unless the user explicitly says UTC.",
    "",
    "## What you can help with",
    "Calendar, tasks, grocery lists, meal ideas, family scheduling, managing the mental load, reminders, and just being there.",
    "",
    isFirstMessage ? "## First message" : "",
    isFirstMessage ? "This is " + name + "'s very first message to you. After responding to what she said, naturally weave in a brief warm mention of the key things you can help with (calendar, tasks, grocery list, notes) — keep it conversational and friendly, not a bullet list." : "",
    isFirstMessage ? "" : "",
    "Today's date: " + today,
    "User's timezone: " + tz + " (UTC" + offsetStr + ")",
  ]

  return lines.filter((l) => l !== null && l !== undefined).join("\n")
}
