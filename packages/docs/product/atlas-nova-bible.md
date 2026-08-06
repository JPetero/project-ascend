# Atlas & Nova Bible

Atlas and Nova are **presentations of one shared companion intelligence**,
not two different products or two different quality tiers. This document is
authoritative for anything involving companion voice, personality, coaching
style, or dialogue content.

## The shared core

Whichever companion a user picks, they get identical:
- **Safety rules** — the same list of things neither companion will ever
  say (see `wellness-ethics-bible.md`).
- **Knowledge** — the same underlying workout/nutrition logic, the same
  progression rules, the same deload logic.
- **Recommendation quality** — Atlas never gives a better plan than Nova or
  vice versa.

What differs is **presentation**: name, avatar, and a consistent voice
across the dialogue lines each surfaces. Today's implementation uses
deterministic local dialogue (no live third-party AI call) — see
`engineering-bible.md` for why, and for what "deterministic" means in
practice (canned, reviewed copy selected by context, not generated
per-request).

## Companion identity is independent of coaching style

A user's companion choice (Atlas or Nova) and their coaching style (Gentle,
Balanced, Direct, Tough, Athlete) are two separate preferences. Never label
a companion or a style "for men" or "for women." A male user choosing Nova,
or a female user choosing Atlas, is a normal, fully-supported choice.

Sex and any optional gender-related preference the user provides may
inform *physiological* context (e.g. BMR estimation inputs already used by
`MacroTargetsService`) but must never drive companion or style selection or
availability.

## Coaching styles

| Style | Voice | Hard limits (apply to every style) |
|---|---|---|
| Gentle | Encouraging, patient, low pressure | |
| Balanced | Straightforward, warm, the default | |
| Direct | Efficient, fewer pleasantries, still respectful | |
| Tough | Pushes for effort, high expectations | |
| Athlete | Performance-focused, technical language | |

Every style, including Tough, must:
- never insult or shame the user
- never encourage training through concerning pain, dizziness, chest pain,
  or breathing difficulty
- never override a safety rule to sound more motivating
- still explain uncertainty and defer to a professional when appropriate

"Tough" is intensity of *encouragement*, never permission to be unsafe or
unkind. If a dialogue line would only make sense for an unsafe or unkind
companion, it doesn't belong in any style's line set.

## What's stored

Per user, in preferences (synced across devices, same mechanism as today's
`PreferencesModel`):
- selected companion (`atlas` | `nova`)
- coaching style (`gentle` | `balanced` | `direct` | `tough` | `athlete`)
- tone intensity (a bounded 1–5 scale, independent of style, letting a user
  fine-tune within their chosen style)
- preferred form of address (free-text, optional, used when the UI later
  supports it — e.g. a nickname)

All four are changeable at any time from Settings, not just once at
onboarding.

## Dialogue content rules

- Never fabricate a statistic, a "you're in the top X%" claim, or a
  personal record the system hasn't actually recorded.
- Never use countdown/urgency language ("only 2 hours left to log today!").
- Celebrate real completions (a finished workout, a logged meal, a streak
  that actually happened) — never celebrate something that didn't happen.
- When a user's input suggests a symptom or condition outside safe scope
  (Scenario 1's list — pain, dizziness, breathing difficulty, chest pain),
  every companion and every style responds with the same safety redirect,
  word-for-word core content, regardless of voice.

## Future: live AI

When a live AI provider is integrated (out of scope for this build phase),
the same rules apply unchanged — the model behind Atlas and Nova must still
answer identically on safety-relevant content regardless of which companion
or style is presenting it. A shared system-prompt safety layer, not a
per-companion one, is the intended architecture — document this decision
here when that milestone begins so the constraint isn't rediscovered.
