# Beta Feature Profile & Demo-Data Audit

S14 Part 34-35. What should be ON, conditional, or OFF for the first
internal Android beta — and confirmation that no fake user/post/message
data exists anywhere that could seed into staging or production.

## Feature profile

Project Ascend already gates the riskiest surfaces behind
`AscendFeatureKey` flags (`services/api/src/modules/feature-flags/feature-flag-registry.ts`).
That registry's defaults are tuned for a fully-configured *production*
deployment. For the very first beta — before Firebase, Google OAuth, an
AI provider key, Brave Search, or Play Console are actually set up —
several of those defaults would present a broken button or an error
message instead of the feature just being absent.

`services/api/prisma/seed-beta-feature-flags.ts` seeds explicit
`FeatureFlag` overrides for the beta environment only. It never edits the
registry file, so production keeps the registry's defaults unless an
admin explicitly changes them — this only ever affects whichever database
`DATABASE_URL` points at when you run it, and refuses to run at all
against `ASCEND_ENV=production`.

*(S15 Part 3 corrected that guard: it previously checked
`NODE_ENV=production`, which would have refused to run against staging
too — since staging correctly runs `NODE_ENV=production` — i.e. against
exactly the environment this script exists to seed. See
[staging-deployment.md](../staging-deployment.md#s15-part-1-correction-node_env-vs-ascend_env).)*

```bash
cd services/api
DATABASE_URL=<staging database URL> ASCEND_ENV=staging pnpm seed:beta-feature-flags
```

This profile is exactly the **Stage B** feature set — see
[release-stages.md](release-stages.md) for what each release stage does
and does not require. Every flag below being off at Stage B is the
intended configuration, not a gap.

### ON for the first beta (no flag exists — always on)

Train (Workout Engine), Fuel (Nutrition), Community, Friends/DM,
Rankings, Basic Ascend AI (the non-paid Atlas/Nova companion path —
distinct from Live Ascend AI below), Achievements, GPS Cardio, Gallery,
Nutrition Library, Support.

### Conditional — off until its dependency is configured, then an admin flips it on

| Flag | Depends on | Where to configure |
| --- | --- | --- |
| `GOOGLE_SIGN_IN` | Google OAuth client | founder-setup-checklist.md |
| `REMOTE_PUSH` | Firebase project | founder-setup-checklist.md |
| `VISION_FORM_COACH` | Vision physical-device QA passing on real hardware — never inferred from a unit/e2e test | qa/vision-physical-device-checklist.md |
| `LIVE_AI` | An AI provider API key (Anthropic/OpenAI/Gemini) | founder-setup-checklist.md |
| `RESEARCH_MODE` | Brave Search API key (+ an AI provider for generative synthesis) | founder-setup-checklist.md |

Turn each on from the Admin web app's Feature Flags page once its
dependency is real — `GET /admin/release-readiness` (S14 Part 7) reports
exactly this status per integration.

### OFF for the entire initial beta, regardless of configuration

- `STORE_PURCHASES` — sandbox receipt verification, restore, cancellation,
  and grace-period behavior haven't been manually tested yet (see
  beta-blockers.md Part 40). Configuring real Play Billing/StoreKit
  credentials does **not** change this — see Release Readiness V3's
  `playBilling`/`storeKit` items, which stay at `STORE_SETUP_REQUIRED`
  rather than `READY` even once credentials exist.
- `ASCEND_PROMOTE` — depends on Store Purchases.

Apple Sign In is untouched by the beta profile (stays at the registry
default): this first beta is Android-only (see build-session-14.md and
android-sideload-beta.md), so the button is simply unreachable rather
than actively broken.

## Demo-data audit

Audited every seed/fixture path in the backend for fake user, post, or
message data that could leak into a real environment:

- `services/api/prisma/seed.ts` — exercise catalog, workout plans,
  nutrient/food reference data, muscle groups, equipment types, legal
  document versions, achievement definitions. All of it is genuine
  reference/catalog data, safe to run in every environment (including
  production) — it creates zero `User`, `CommunityPost`,
  `DirectMessage`, or any other user-generated-content rows.
- No other seed script exists in the repository. There is no
  `faker`-style random-user generator, no `@example.com` fixture
  data, and no "demo mode" data path anywhere outside test files.
- The only places fake users/posts/messages exist at all are `*.spec.ts`
  unit tests and `test/*.e2e-spec.ts` suites, which run against an
  isolated test database (`resetDatabase`) that is never the same
  database a staging or production deployment points at.

Conclusion: there is nothing to remove. `seed.ts` is already correctly
scoped to reference data only, and it's safe to run against staging or
production without ever risking fake social content appearing in front
of a real user.
