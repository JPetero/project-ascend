# Build Session 1 — Autonomous Build Log

Append-only. Each entry records what was actually done, commands actually run, and their real
output. Nothing in this file is aspirational — if a step wasn't executed, it says so explicitly.

---

## Session start

2026-08-06T02:41:25Z — session start, branch claude/new-session-qy6hzm at ef525b5

## P0.1 — Flutter SDK consistency: VERIFIED, no changes needed

`apps/mobile/pubspec.yaml` (`sdk: ^3.12.2`), `.github/workflows/mobile.yml`
(`flutter-version: "3.44.8"`, `channel: "stable"`), and `README.md` were already fully aligned
from prior session work. Confirmed against the actually-installed toolchain:

```
$ flutter --version
Flutter 3.44.8 • channel stable • https://github.com/flutter/flutter.git
```

Matches exactly. No drift found.

## P0.2 — Refresh-token family security: mostly pre-existing, closed two real gaps

Inspected `services/api/src/modules/auth/auth.service.ts` and its tests. The core security
property was already implemented correctly from prior session work:
- `RefreshToken.familyId` links every token descended from one login.
- Rotation runs inside `prisma.$transaction`, using a `revokedAt: null` guard on `updateMany` as
  a compare-and-swap — a concurrent request racing to rotate the same token affects 0 rows and is
  routed into the same reuse-handling path (`RefreshTokenReuseError` -> `handleRefreshTokenReuse`).
- Reuse of an already-rotated/revoked token revokes every active token in the family and records
  an `auth.refresh_token_reuse_detected` audit event.
- The client only ever sees a generic "Refresh token is invalid or expired." 401.
- `tokenHash` only; the raw secret is never stored (argon2 hash, verified with `argon2.verify`).

Two genuine gaps closed this session:
1. **`reusedAt` timestamp** — the spec asked for a "reuse-detection timestamp" distinct from the
   generic `revokedAt`. Added `RefreshToken.reusedAt DateTime?`, set only inside
   `handleRefreshTokenReuse`, never on an ordinary rotation revoke — an auditor can now tell
   "rotated normally" from "killed by reuse handling" directly from the row.
2. **`POST /auth/logout-all`** — no "sign out everywhere" endpoint existed. Added
   `AuthService.logoutAll(userId)` (revokes every active token across every family for the user,
   records an `auth.logout_all` audit event) and the authenticated controller route.

Not implemented, by deliberate choice: literal `parentTokenId`/`replacedByTokenId` relations. The
existing `familyId` + `revokedAt` design already gives every required security property (rotate
once, old token dead, reuse kills the whole lineage) without a parent/child chain, and rebuilding
that as a literal graph would add join complexity for no behavior change. Documented here per the
instruction to record reasonable engineering decisions rather than implement them silently.

Migration: `20260806024532_p0_refresh_token_reuse_and_device_key` (see P0.3 below — combined into
one migration since both touch this session's schema at once).

Tests added:
- `auth.service.spec.ts`: `logoutAll` unit test (revokes all active tokens for the user, distinct
  audit action from reuse handling). Updated the two existing reuse-path assertions to expect the
  new `reusedAt` field.
- `app.e2e-spec.ts`: `logs out of all sessions and revokes every active refresh token for the
  user` — logs in twice (two separate token families for the same user), calls `/auth/logout-all`
  with one session's access token, confirms both refresh tokens are rejected afterward.

Not added: a literal "two simultaneous real HTTP requests" concurrency test — the race is proven
by the existing unit test that mocks the transaction boundary losing the compare-and-swap
(`tx.refreshToken.updateMany` returning `count: 0`), plus the reasoning above about Postgres READ
COMMITTED making the guarded `updateMany` a safe CAS. Same standard as the earlier Sprint 0/1
audit in this repo.

## P0.3 — Device connection uniqueness: closed

Previous constraint was `@@unique([userId, provider])` — one connection per provider, full stop,
even though `externalAccountId` existed as an unused nullable field. This silently prevented ever
registering two physical devices from the same provider (e.g. two paired Garmin watches).

Added `DeviceConnection.connectionKey String @default("default")`, changed the constraint to
`@@unique([userId, provider, connectionKey])`, and added an index-backed composite key. Chose a
default-valued required column (not `externalAccountId` itself, which stays nullable/informational)
because Postgres treats `NULL` as distinct in unique constraints — a nullable uniqueness column
would not have prevented duplicates for the common case of no `externalAccountId` being supplied.
`CreateDeviceDto.connectionKey` is optional (`^[A-Za-z0-9._:-]+$`, max 200 chars); omitting it
preserves the original one-connection-per-provider upsert behavior for simulated/basic providers.

Tests added: `app.e2e-spec.ts` — "a distinct connectionKey registers a second physical device for
the same provider" (asserts a second row is created, not upserted, and both appear in `/devices`).

## Verification after P0.2 + P0.3

```
$ pnpm api:lint         -> PASSED, 0 errors/warnings
$ pnpm api:test         -> PASSED, 21/21 (was 20; +1 logoutAll unit test)
$ pnpm api:test:e2e     -> PASSED, 33/33 (was 31; +1 connectionKey, +1 logout-all)
$ pnpm api:build        -> PASSED
```

Migration applied and verified against both `ascend_dev` and `ascend_test` via `prisma migrate
deploy` (real local PostgreSQL 16, not Docker — see Docker note below).

## P0.4 — Splash and session resilience: VERIFIED pre-existing, added missing test coverage

Read `apps/mobile/lib/features/auth/presentation/providers/auth_controller.dart`,
`.../screens/splash_screen.dart`, and `core/routing/app_router.dart`'s `_redirect()`. All of the
required behaviors were already implemented from prior session work:
- `AuthController._bootstrap()` retries a profile-fetch network error up to 3 times with backoff,
  but never wipes a valid session on a transient failure — only a confirmed 401 or exhausted
  retries end the session.
- `SplashScreen` renders `_SplashError` (Try again / Sign out) when `profileControllerProvider`
  is `AsyncError`, instead of an unrecoverable spinner.
- `ApiClient`'s automatic refresh-and-retry-on-401 calls `onSessionExpired` on failure, which bumps
  `sessionExpiredNotifierProvider`; `AuthController` listens on that and calls
  `handleSessionExpired()`, clearing tokens + Drift cache and setting `unauthenticated`.
- `AuthRepository.logout()` clears local tokens in a `finally`-equivalent path regardless of
  whether the server-side `/auth/logout` call succeeds.
- Auth status is derived only from `AuthController`'s own state (token presence + `/auth/me`
  result), never from cached profile data, so a stale local profile cannot resurrect a session.
- `_redirect()` in `app_router.dart` was traced by hand for cycles: every branch either returns
  `null` (stay) or a fixed target gated by a condition that itself returns `null` once satisfied.
  No cycle exists, including for the Workout Engine's top-level routes added in Sprint 2.

Gap found: none of this had test coverage. Added `test/core/splash_resilience_test.dart` (3
tests): profile-fetch failure shows the recoverable error state (not an infinite spinner) and
"Try again" actually recovers once connectivity returns; "Sign out" from the error state clears
the session and returns to Welcome; and a simulated `sessionExpiredNotifierProvider` bump (the
real trigger path from a failed silent refresh) clears the authenticated session and returns to
Welcome. Required extending `FakeProfileRepository` with a `failFetch` toggle.

## P0.5 — Onboarding persistence: VERIFIED pre-existing, no changes needed

`OnboardingController` (`apps/mobile/lib/features/onboarding/presentation/providers/onboarding_controller.dart`)
already does exactly what the spec asks, structurally rather than via a debounce timer: every
field edit (`updateDraft`/`setCompanion`) writes to the local Drift draft immediately and *only*
that — no API call happens per keystroke. The API is only ever called from `goNext()`, i.e. on
page advance and at completion (last page sets `onboardingCompleted: true`). A failed `goNext()`
sync preserves the local draft and current page, surfaces `OnboardingState.syncError`
non-blockingly, and the same "Next" tap retries. Already covered by
`test/features/onboarding/onboarding_navigation_test.dart`. No debounce timer was added since the
existing design already satisfies "do not call the API for every minor interaction" without one.

## P0.6 — Docker and migrations: verified by direct execution; `docker compose up --build` itself unverified

`infrastructure/docker/api.Dockerfile` and `docker-compose.yml` were inspected and already
implement every required property from prior session work: multi-stage build (`build` ->
`migrate`/`runtime`), `runtime` stage contains only compiled `dist/`, production `node_modules`,
and the generated Prisma client (no pnpm, no dev deps), runs as a non-root `ascend` user, has a
`HEALTHCHECK` hitting `/health`, and `docker-compose.yml` sequences `postgres` (health-gated) ->
`migrate` (runs `prisma migrate deploy`, never `migrate dev`) -> `api` (depends on migrate's
`service_completed_successfully`).

**`docker compose up --build -d` itself could not be run**: the Docker daemon is unreachable in
this sandbox (`Cannot connect to the Docker daemon at unix:///var/run/docker.sock`), and
`service docker start` fails with `ulimit: error setting limit (Operation not permitted)` — a
container-level privilege restriction, confirmed on two attempts including with an unsandboxed
shell. This is an environment limitation, not a defect in the Dockerfile/compose files, and
matches the same restriction hit in the prior Sprint 0/1 audit recorded in the root README.

To compensate, the `build` stage's logic was reproduced directly, for real, outside Docker:
- `pnpm deploy --prod <dir> --filter @project-ascend/api` (the exact command the Dockerfile runs)
  against a real temp directory.
- The generated Prisma client copied in exactly as the Dockerfile's fix-up step does.
- The deployed output run directly with production-shaped env vars
  (`NODE_ENV=production`, real Postgres) via `node dist/main.js`.
- `GET /health` returned `{"data":{"status":"ok",...}}`.
- `POST /auth/register` succeeded end-to-end (hashed password, issued tokens, wrote a real row) —
  this also confirms the new `/auth/logout-all` route registered correctly
  (`Mapped {/auth/logout-all, POST} route` appeared in the Nest startup log).

Not verified in this pass: the actual multi-stage Docker build, the `HEALTHCHECK` directive
executing inside a container, and the non-root user constraint enforced by the container runtime
itself. `docker-build` in `.github/workflows/backend.yml` (unchanged, already present) covers all
three on every push/PR — the workflow builds both the `runtime` and `migrate` targets.

## P0.7 — CI verification: VERIFIED, no changes needed

Read `.github/workflows/backend.yml` and `.github/workflows/mobile.yml` in full.

Backend CI already has every required step: frozen-lockfile install, `prisma validate`, a
format-then-`git diff --exit-code` formatting check, `prisma generate`, `prisma migrate deploy`
against a real CI Postgres service container, catalog seed, lint, unit tests, e2e tests, build,
and a separate `docker-build` job that builds both the `runtime` and `migrate` Dockerfile targets.

Mobile CI already has: pinned `flutter-version: "3.44.8"` / `channel: "stable"`, `flutter pub get`,
`flutter analyze`, `dart format --output=none --set-exit-if-changed .`, `flutter test`.

Path filters on both workflows (`paths:` under `push`/`pull_request`) already scope correctly to
their respective trees; no shared files were added this session that would need a filter update.

## P0.8 — Documentation truthfulness

See the "Build Session 1 (P0) — Verified Build Results" section added to the root `README.md`,
generated from the actual command output captured in this log — not from memory or assumption.
