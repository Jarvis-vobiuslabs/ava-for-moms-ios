# Ava For Moms — Update Roadmap

Working checklist from Nathan's notes (July 2026). One at a time; check off as shipped.

## 🐛 Bugs (do first)

- [x] **1. Today page loads empty on launch** — fixed July 14: MainTabView now
  loads all four stores on auth (parallel), plus a non-prompting calendar
  access check so connected calendars show on Home at launch.
- [x] **2. Buttons only clickable on the text** — fixed July 16: added
  `.contentShape(Rectangle())` to all 86 plain-style buttons across 23 views,
  so the full padded/framed area is tappable (tab bar was the worst case).
- [ ] **3. Duplicate events in calendar** — EventKit two-way sync tracks IDs in
  UserDefaults, which breaks across reinstalls/devices and can double-import.
  Fix: rethink sync bookkeeping (store sync state in Supabase or EK notes tag).
- [x] **4. Adding to today's reminders/calendar fails without a time** —
  fixed & deployed July 16: add_task gained optional due_date (date-only →
  local 8pm), add_calendar_event's ends_at now optional (+1h default) with
  all_day support, and Ava is instructed to never demand a time.
- [x] **5. Time understanding / local timezone per account** — done July 16:
  profiles.timezone column live (migration 006), app writes it on profile load
  (ships next build), morning-brief now sweeps hourly and fires at 7am LOCAL.
- [ ] **6. Calendar permission stuck after first decline** — iOS never re-shows
  the system prompt. Fix: detect `.denied` and show a "Connect calendar" card
  that deep-links to Settings.

## 🔔 Notifications bundle (shared infra — do together)

- [ ] **7. Morning AND evening daily notifications that actually work** —
  morning half DONE (hourly sweep at 7am local, deployed July 16).
  Remaining: evening notification function.
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
