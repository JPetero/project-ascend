# Staging Deployment Guide

S13 Part 16-27, corrected in S15 Part 1 (see below). How to actually
stand up and point a build at a staging environment — distinct from
local development (`docker compose up -d` + `flutter run --flavor dev`,
see the root README) and from a real production deploy (which
additionally needs every item in
[founder-setup-checklist.md](founder-setup-checklist.md)). Staging exists
to run the exact same code against a real, shared backend before it goes
to production — so treat its secrets with the same care as production's:
never reuse a staging JWT secret in production or vice versa.

**This sandboxed build environment has no staging infrastructure of its
own** (no cloud account, no DNS, no managed Postgres) — this document is
the real, standard procedure for setting one up, written so a human with
infrastructure access can follow it directly, not something that has
been run end-to-end in this session.

## S15 Part 1 correction: NODE_ENV vs ASCEND_ENV

This document previously told operators to set `NODE_ENV=staging`. That
was a real, P0 bug: `services/api/src/config/env.validation.ts` only
ever accepted `NODE_ENV` values of `development`, `test`, or
`production` — the documented staging procedure could never actually
boot. Fixed by introducing a second, separate variable:

| Environment | `NODE_ENV` | `ASCEND_ENV` |
|---|---|---|
| Local development | `development` | `development` |
| Automated tests | `test` | `development` |
| **Staging** | **`production`** | **`staging`** |
| Production | `production` | `production` |

`NODE_ENV` stays exactly the three values the wider Node ecosystem
(Express and friends) expects when it branches on it for
production-optimized behavior — never a fourth `staging` value.
`ASCEND_ENV` is Ascend's own "which real-world environment is this"
signal, and it's what every deployment-safety check in
`services/api/src/config/deployment-config-validation.ts` actually
gates on: a staging deployment is internet-reachable and must reject
the same dangerous configuration (dev/short/duplicate JWT secrets, a
wildcard CORS origin, a `localhost` `DATABASE_URL`/`APP_PUBLIC_URL`) that
production does — see that file's doc comment for the full model. A
deployment that sets `NODE_ENV=production` without also setting
`ASCEND_ENV` is still treated as a real deployed environment for safety
purposes (see `resolveAscendEnv`'s doc comment) — omitting the new
variable can never silently weaken protection, only an explicit
`ASCEND_ENV=development` override can.

## Backend

1. Provision a Postgres 16+ instance and an application host (any
   container platform that can run the Docker image `infrastructure/docker/`
   builds, or a plain Node 20+ host running `pnpm build && pnpm start:prod`).
2. Set `NODE_ENV=production` and `ASCEND_ENV=staging`, plus every
   variable in
   [founder-setup-checklist.md](founder-setup-checklist.md#backend-secrets-servicesapienv)
   for this environment specifically — a staging JWT secret, a staging
   CORS origin (the staging mobile build's actual origin, never `*`),
   staging (not production) copies of whichever third-party
   integrations you want to test against. It's fine — often preferable —
   to leave optional integrations (push, IAP, research) unconfigured in
   staging if you're not testing those flows yet; `GET /admin/release-readiness`
   reports each one honestly rather than pretending. See
   [release/staging-config-contract.md](release/staging-config-contract.md)
   for the full categorized variable list and
   `services/api/.env.staging.example` for a starting point.
3. Run `pnpm prisma:deploy` against the staging database before first
   boot, and after every subsequent deploy that adds a migration — or
   run `pnpm staging:bootstrap` (S15 Part 8), which does this plus the
   reference-data and beta-feature-profile seeds in the correct order.
4. Create the first admin account:
   `ADMIN_BOOTSTRAP_EMAIL=you@example.com pnpm bootstrap:admin` (S15
   Part 9). No credentials are hardcoded anywhere — supply
   `ADMIN_BOOTSTRAP_PASSWORD` yourself (16+ chars) or omit it and a
   strong one is generated and printed exactly once. The script refuses
   to run if any admin already exists, so it can safely stay in the
   image; every subsequent admin is promoted from the Admin app by an
   account holding `MANAGE_ADMINS`.
5. Confirm `GET /livez` (process alive, no database check) and
   `GET /readyz` (database-aware — S14 Part 6 split these apart; the
   older `GET /health` still exists as an alias identical to `/readyz`,
   kept only for anything already pointed at it) both return
   `{ "status": "ok" }`, and `GET /admin/release-readiness` (as a
   `MANAGE_PLATFORM` admin) shows `migrations.upToDate: true`,
   `ascendEnv: "staging"`, and every integration you configured as
   green. `pnpm staging:smoke` (S15 Part 14) automates exactly this
   check plus a handful of real API calls.

## Mobile

Build against staging with the `staging` Android flavor and a
`--dart-define=ENVIRONMENT=staging`, always paired with an explicit
`API_BASE_URL` pointed at the real staging backend host from step 1
above — there is no default staging URL (see `AppConfig`'s doc comment
for why one is never guessed at):

```bash
cd apps/mobile
flutter run --flavor staging \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=API_BASE_URL=https://staging-api.<your-domain>
```

or for a release build to hand to testers:

```bash
flutter build apk --release --flavor staging \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=API_BASE_URL=https://staging-api.<your-domain>
```

The `staging` flavor's applicationId (`com.projectascend.mobile.staging`)
lets this be installed side by side with a `dev` or `prod` build on the
same device — see `apps/mobile/android/app/build.gradle.kts`'s
`productFlavors`. The small orange "STAGING" corner ribbon
(`EnvironmentBanner`) is the at-a-glance confirmation a tester is running
the right build; a `prod`-flavor build never shows any ribbon.

## Admin app

`apps/admin` isn't covered by the Backend/Mobile sections above — see
[admin-deployment.md](admin-deployment.md) (S14 Part 28-29) for its own
Docker image, security headers, and the network-level access
restriction it needs beyond application-level RBAC.

## What staging is for (and isn't)

Staging is for exercising the real backend/integration surface — auth,
payments sandbox modes, push delivery, AI provider calls — against
something closer to production than local dev, before promoting.
It is **not** a substitute for the manual device/OS QA pass in
`qa/release-device-matrix.md`, which still needs to run against an actual
release-signed build on real hardware regardless of which backend
environment it points at.
