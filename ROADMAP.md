# Ava For Moms — Update Roadmap

Working checklist from Nathan's notes (July 2026). One at a time; check off as shipped.

## 🐛 Bugs (do first)

- [x] **1. Today page loads empty on launch** — fixed July 14: MainTabView now
  loads all four stores on auth (parallel), plus a non-prompting calendar
  access check so connected calendars show on Home at launch.
- [ ] **2. Buttons only clickable on the text** — no `.contentShape(Rectangle())`
  anywhere in the codebase; plain-style buttons only hit-test drawn pixels.
  Fix: sweep all buttons, add contentShape + minimum 44pt targets. *(diagnosed, small)*
- [ ] **3. Duplicate events in calendar** — EventKit two-way sync tracks IDs in
  UserDefaults, which breaks across reinstalls/devices and can double-import.
  Fix: rethink sync bookkeeping (store sync state in Supabase or EK notes tag).
- [ ] **4. Adding to today's reminders/calendar fails without a time** —
  `add_task` tool has no `due_date` field at all, and `add_calendar_event`
  requires `starts_at`+`ends_at`. Fix: add optional due_date to add_task,
  make ends_at optional (default +1h), support all-day events, prompt Ava to
  default to "today" when no date given. *(backend-only, no app release)*
- [ ] **5. Time understanding / local timezone per account** — store the user's
  IANA timezone on `profiles` (updated from app at launch), use it in
  morning-brief (currently fires 7:00 UTC for everyone) and all Ava date math.
- [ ] **6. Calendar permission stuck after first decline** — iOS never re-shows
  the system prompt. Fix: detect `.denied` and show a "Connect calendar" card
  that deep-links to Settings.

## 🔔 Notifications bundle (shared infra — do together)

- [ ] **7. Morning AND evening daily notifications that actually work** —
  needs timezone from #5; add evening cron + per-user local-time windows.
- [ ] **8. Evening task nag** — "Ava reminder if tasks not checked off" —
  fold into evening notification: unfinished-task count + warm nudge.
- [ ] **9. Quote of the day toggle** — profiles column + Settings toggle;
  morning notification includes a motivational quote when enabled.

## 🎨 UX

- [ ] **10. Bigger text/buttons for older users** — bump AvaTheme sizes, adopt
  Dynamic Type support, larger tap targets (pairs with #2).
- [ ] **11. Post-onboarding "how to use Ava" welcome page** — e.g. "tell her all
  the birthdays you need for the year and she'll add + remind you."
- [ ] **12. Chat history viewer + clear history** — all-time history for viewing
  (not model context), plus a clear-history action.

## ✨ Features

- [ ] **13. Upgrade celebration** — confetti on standard→pro upgrade + star next
  to name. DECIDED: UI-only; Apple's same-group upgrades already apply instantly
  with prorated billing, no entitlement workaround needed.
- [ ] **14. Voice input button for chat** — SFSpeechRecognizer dictation.
- [ ] **15. Better recent-chat memory** — DECIDED: consider fixed by the July 14
  constraint repair; re-open only if it still feels weak after memories accumulate.
- [ ] **16. Image upload in chat (50/month cap)** — photo picker → storage →
  Claude vision; per-user monthly counter.
- [ ] **17. Higgsfield image generation** — DECIDED: 10 generations/month included
  in BOTH plans. Prompt idea chips in chat (e.g. "colouring sheet with your
  kid's name", "birthday card"). Must support saving/downloading the image
  to Photos. Per-user monthly counter like #16.

## Done

- [x] Fix silent memory-save failure (missing unique constraint) — July 14, 2026
- [x] Upgrade chat models: Pro → Claude Sonnet 5, standard → Haiku 4.5 — July 14, 2026
