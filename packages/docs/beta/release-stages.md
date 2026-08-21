# Release Stages A–E

S15 Part 5. "Is Ascend ready for beta?" has no single answer, and
answering it as one yes/no has been actively misleading: it makes an
Android install test look like it needs an Apple Developer account, and
it makes a genuinely reachable next step look unreachable.

This document splits release readiness into five explicit stages. Each
stage lists **only** what that stage actually requires. Anything not
listed for a stage is genuinely not needed to reach it — that is the
whole point of the split, and it is what makes Stage B achievable now
rather than "after everything in `founder-setup-checklist.md`."

Stages are strictly cumulative: Stage C assumes Stage B is done.

| Stage | What it proves | Blocked on today |
|---|---|---|
| **A** | The app installs and runs on a real Android phone | Nothing — reachable now |
| **B** | The app works end-to-end against a real backend | External infrastructure (Founder) |
| **C** | The app distributes through Google Play internal testing | Play Console + signing (Founder) |
| **D** | The app runs on real iOS hardware via TestFlight | Apple Developer Program (Founder) |
| **E** | The app is publicly available | Everything above + store review |

---

## Stage A — Install-only Android smoke test

**Proves:** the APK installs on real hardware, the app launches, the UI
renders correctly on a real screen, and navigation works. Nothing that
requires a server.

**Requires — the complete list:**

1. A GitHub Actions run of `Mobile CI` that produced an APK artifact
   (this already happens on every push to `main` — S14 Part 4 observed a
   real run doing exactly this).
2. An Android phone running **Android 8.0 (API 26) or newer** — see
   [android-min-sdk.md](android-min-sdk.md) for why that floor exists.
3. The install steps in
   [android-sideload-beta.md](android-sideload-beta.md).

**Does NOT require:** a staging server, a database, a domain name, TLS, a
Play Console account, an Apple account, Firebase, Google OAuth, an AI
provider key, Brave Search, IAP credentials, or a signing keystore.

**What will not work at Stage A, by design:** login, sign-up, and every
server-backed screen. The `ascend-development-sideload` build's default
API address (`http://10.0.2.2:3000`) is an Android-**emulator**-only NAT
alias and is unreachable from a physical phone under any circumstances —
so network calls fail to connect rather than returning errors. That is
expected, not a bug. Confirming *the app installs, opens, and renders* is
the entire scope of Stage A.

**Status: reachable today.** Nothing external is missing.

---

## Stage B — Connected Android internal beta

**Proves:** the real app talks to a real backend over real HTTPS — signup,
login, workouts, nutrition, community, and everything else server-backed
actually functioning against a real PostgreSQL database on a real device.
This is the first stage at which Ascend is meaningfully testable as a
product.

**Requires — the complete list:**

1. A **staging PostgreSQL 16+ database** the API can reach.
2. A **host running the API** (any container platform, or a Node 20+ box)
   with `NODE_ENV=production` and `ASCEND_ENV=staging` — see
   [staging-deployment.md](../staging-deployment.md) and
   [release/staging-config-contract.md](../release/staging-config-contract.md).
3. **A domain name with working HTTPS/TLS** in front of that API. Not
   optional: Android blocks cleartext HTTP by default, and
   `DeploymentConfigValidation` refuses to boot a deployed environment
   whose `APP_PUBLIC_URL` is not `https://`.
4. **Real staging secrets** — `JWT_ACCESS_SECRET` and
   `JWT_REFRESH_SECRET` (each 32+ chars, different from each other,
   different from production's), plus an explicit non-wildcard
   `CORS_ORIGIN`.
5. **`STAGING_API_BASE_URL`** set as a GitHub Actions repository
   *variable* so Mobile CI builds a real `ascend-staging-internal` APK
   instead of the development-sideload fallback.
6. Migrations applied against that database (`pnpm prisma:deploy`, or
   `pnpm staging:bootstrap`).

**Does NOT require — explicitly, because assuming otherwise is what made
this stage look unreachable:**

- ❌ An AI provider key (Anthropic/OpenAI/Gemini) — `LIVE_AI` stays off;
  the free deterministic Atlas/Nova companion path works without it.
- ❌ A Brave Search key — `RESEARCH_MODE` stays off.
- ❌ Google OAuth — `GOOGLE_SIGN_IN` stays off; email/password signup is
  the tested path and is fully functional.
- ❌ Firebase/FCM — `REMOTE_PUSH` stays off; local notifications and
  in-app notification history still work.
- ❌ Apple/Google IAP credentials — `STORE_PURCHASES` is off for the
  entire initial beta regardless of configuration.
- ❌ A Play Console account, an upload keystore, an Apple Developer
  account, or a signed AAB. Stage B distributes by direct APK install,
  exactly like Stage A.

Those five flags staying off is not a degraded mode — it is the
deliberate Stage B feature profile, seeded by
`pnpm seed:beta-feature-flags` and documented in
[beta-feature-profile.md](beta-feature-profile.md). Each one flips on
independently, later, from the Admin Feature Flags page once its
dependency is real.

**Status: BLOCKED on external infrastructure only.** Every code, CI, and
configuration task this stage needs is done — items 1–3 above are
accounts and servers a human must provision. See
[connected-beta-setup.md](connected-beta-setup.md) for the
non-technical, step-by-step version.

---

## Stage C — Google Play internal test track

**Proves:** distribution through Play's own internal-testing channel —
testers install from the Play Store rather than sideloading, and the
build is signed with a real upload key.

**Adds on top of Stage B:**

1. A **Google Play Console account** ($25 one-time).
2. A **confirmed final package ID.** `com.projectascend.mobile` is
   currently *provisional* — see
   [package-id-decision.md](package-id-decision.md). A package ID is
   permanent once published; this is the last moment it can change.
3. A **real upload keystore** plus the `ASCEND_KEYSTORE_BASE64`,
   `ASCEND_KEYSTORE_PASSWORD`, `ASCEND_KEY_ALIAS`, and
   `ASCEND_KEY_PASSWORD` GitHub Actions secrets.
4. `PROD_API_BASE_URL` pointed at a real production (not staging) API.
5. A signed **AAB** from the `production-build` CI job (which stays
   skipped until secrets 3–4 exist).
6. Play Console store listing basics: app name, icon, description,
   privacy policy URL, data-safety declaration, content rating.

**Status: BLOCKED** on the Founder's Play Console account and keystore.

---

## Stage D — iOS TestFlight

**Proves:** the app runs on real iOS hardware.

**Adds on top of Stage C:**

1. An **Apple Developer Program membership** ($99/year).
2. iOS signing — a distribution certificate and provisioning profiles.
3. An **APNs key** if remote push is wanted on iOS.
4. A macOS machine (or macOS CI runner) to build and upload the archive.
5. Apple Sign In configured — Apple *requires* it for any app offering
   third-party social login.

**Status: BLOCKED,** and deliberately deprioritized: the first beta is
Android-only.

---

## Stage E — Public release

**Proves:** anyone can install Ascend.

**Adds on top of Stage D:**

1. Everything in [beta-blockers.md](../beta-blockers.md) at `CLOSED`.
2. A full pass of `qa/release-device-matrix.md` on real hardware.
3. Physical-device Vision QA (`qa/vision-physical-device-checklist.md`).
4. Store review approval on both stores.
5. Automated database backups actually scheduled — see
   [backup-and-restore-runbook.md](../backup-and-restore-runbook.md).
6. If monetization ships: full sandbox purchase QA (verification,
   restore, cancellation, grace period) before `STORE_PURCHASES` is
   enabled.
7. A production environment separate from staging, with its own secrets.

**Status: BLOCKED** on all of the above.

---

## How this maps to Release Readiness

`GET /admin/release-readiness` reports per-item status using its own
vocabulary (`READY`, `CODE_READY`, `CREDENTIALS_REQUIRED`,
`DEVICE_QA_REQUIRED`, `STORE_SETUP_REQUIRED`, `BLOCKED`, `DISABLED`).
That endpoint answers *"what is configured in this environment right
now"*; this document answers *"what do I need to reach the next
milestone."* They are complementary, and neither replaces the other.

An item showing `CREDENTIALS_REQUIRED` is only a blocker for the stage
that actually needs it — `liveAi` at `DISABLED` is the *correct,
intended* state for Stages A and B, not a gap to close.
