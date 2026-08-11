# Staging Deployment Guide

S13 Part 16-27. How to actually stand up and point a build at a staging
environment — distinct from local development (`docker compose up -d` +
`flutter run --flavor dev`, see the root README) and from a real
production deploy (which additionally needs every item in
[founder-setup-checklist.md](founder-setup-checklist.md)). Staging exists
to run the exact same code against a real, shared backend before it goes
to production — so treat its secrets with the same care as production's:
never reuse a staging JWT secret in production or vice versa.

**This sandboxed build environment has no staging infrastructure of its
own** (no cloud account, no DNS, no managed Postgres) — this document is
the real, standard procedure for setting one up, written so a human with
infrastructure access can follow it directly, not something that has
been run end-to-end in this session.

## Backend

1. Provision a Postgres 16+ instance and an application host (any
   container platform that can run the Docker image `infrastructure/docker/`
   builds, or a plain Node 20+ host running `pnpm build && pnpm start:prod`).
2. Set `NODE_ENV=staging` and every variable in
   [founder-setup-checklist.md](founder-setup-checklist.md#backend-secrets-servicesapienv)
   for this environment specifically — a staging JWT secret, a staging
   CORS origin (the staging mobile build's actual origin, never `*`),
   staging (not production) copies of whichever third-party
   integrations you want to test against. It's fine — often preferable —
   to leave optional integrations (push, IAP, research) unconfigured in
   staging if you're not testing those flows yet; `GET /admin/release-readiness`
   reports each one honestly rather than pretending.
3. Run `pnpm prisma:deploy` against the staging database before first
   boot, and after every subsequent deploy that adds a migration.
4. Confirm `GET /health` returns `{ "status": "ok" }` and
   `GET /admin/release-readiness` (as a `MANAGE_PLATFORM` admin) shows
   `migrations.upToDate: true` and every integration you configured as
   green.

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

## What staging is for (and isn't)

Staging is for exercising the real backend/integration surface — auth,
payments sandbox modes, push delivery, AI provider calls — against
something closer to production than local dev, before promoting.
It is **not** a substitute for the manual device/OS QA pass in
`qa/release-device-matrix.md`, which still needs to run against an actual
release-signed build on real hardware regardless of which backend
environment it points at.
