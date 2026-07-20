# Ava For Moms — Update Roadmap

Working checklist from Nathan's notes (July 2026). One at a time; check off as shipped.

## 🐛 Bugs (do first)

- [x] **1. Today page loads empty on launch** — fixed July 14: MainTabView now
  loads all four stores on auth (parallel), plus a non-prompting calendar
  access check so connected calendars show on Home at launch.
- [x] **2. Buttons only clickable on the text** — fixed July 16: added
  `.contentShape(Rectangle())` to all 86 plain-style buttons across 23 views,
  so the full padded/framed area is tappable (tab bar was the worst case).
- [x] **3. Duplicate events in calendar** — fixed July 16: native copies are
  now tagged with an avaformoms:// URL marker (survives reinstalls), sync
  checks the marker instead of only UserDefaults, title+time fingerprint
  dedupes legacy copies, and a re-entry guard stops concurrent double-sync.
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

- [x] **7. Morning AND evening daily notifications** — done July 16: morning
  brief at 7am local + evening brief at 8pm local, both hourly sweeps.
- [x] **8. Evening task nag** — done July 16: evening brief leads with open
  task count ("3 tasks still open") + a no-guilt nudge; congratulates when
  the list is clear.
- [x] **9. Quote of the day toggle** — done July 16: profiles.quote_of_day
  column live, toggle in Account → AVA section, morning brief leads with a
  motivational quote when enabled (backend deployed; toggle ships next build).

## 🎨 UX

- [x] **10. Bigger text/buttons for older users** — done July 16: AvaTheme
  fonts +8% with an 11.5pt floor, and Dynamic Type (iOS Text Size setting)
  now respected app-wide via UIFontMetrics. Tap targets done in #2.
- [x] **11. Post-onboarding welcome page** — done July 16: one-time full-screen
  "You're all set" page after onboarding with 4 example-driven tips (birthdays,
  reminders, grocery, notes) and a "Say hi to Ava" CTA straight into chat.
- [ ] **12. Chat history viewer + clear history** — all-time history for viewing
  (not model context), plus a clear-history action.

## ✨ Features

- [x] **13. Upgrade celebration** — done July 16: full-screen confetti rain +
  "Welcome to Ava Pro" card on any pro purchase (paywall & My Plans), gold
  star beside the name on Home for pro members.
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
