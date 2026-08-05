# Project Ascend

An AI-first fitness, nutrition, progress, social, and wellness app. This repository is the
**Sprint 0 + Sprint 1 foundation**: a real, runnable monorepo containing a NestJS backend and a
Flutter mobile client, covering the first vertical slice — register, onboard, pick a companion
(Atlas or Nova), land on a personalized dashboard, and navigate the main app shell.

See [`packages/docs/architecture.md`](packages/docs/architecture.md) for how the system fits
together, [`packages/docs/security.md`](packages/docs/security.md) for current controls and
known gaps, [`packages/docs/wearables.md`](packages/docs/wearables.md) for the device-integration
strategy, and [`packages/docs/roadmap.md`](packages/docs/roadmap.md) for what's next.

## Repository structure

```text
project-ascend/
├── apps/mobile/          Flutter app (Dart)
├── services/api/         NestJS backend (TypeScript)
├── packages/docs/        Architecture, security, wearables, roadmap docs
├── infrastructure/docker/  Dockerfiles
└── docker-compose.yml     PostgreSQL + API for local dev
```

## 1. Prerequisites

- **Node.js** 20+ (verified with Node 22)
- **pnpm** 9+ (`npm install -g pnpm`)
- **Docker** and **Docker Compose** (for PostgreSQL, and optionally the API)
- **Flutter 3.44.8 (stable)**, which bundles **Dart 3.12.2** — this is the exact version
  pinned in CI (`.github/workflows/mobile.yml`) and required by `apps/mobile/pubspec.yaml`'s
  `sdk: ^3.12.2` constraint. Install via https://docs.flutter.dev/get-started/install, then
  `flutter version 3.44.8` if you have a different version active. Using an older Flutter (e.g.
  3.24, which bundles Dart ~3.5) will fail to resolve dependencies against this SDK constraint.
- A configured Android emulator or iOS simulator (or a physical device) to run the mobile app

## 2. Clone the repository

```bash
git clone https://github.com/JPetero/project-ascend.git
cd project-ascend
```

## 3. Install dependencies

```bash
# Backend (installs only the API workspace and its dependencies)
pnpm install --filter @project-ascend/api...
```

```bash
# Mobile
cd apps/mobile
flutter pub get
cd ../..
```

## 4. Set environment variables

```bash
cp services/api/.env.example services/api/.env
```

The defaults in `.env.example` work out of the box with the `docker-compose.yml` PostgreSQL
service. For anything beyond local development, replace `JWT_ACCESS_SECRET` and
`JWT_REFRESH_SECRET` with strong random values (e.g. `openssl rand -base64 48`) — the API refuses
to start in `NODE_ENV=production` with the checked-in development secrets.

## 5. Start PostgreSQL

```bash
docker compose up -d postgres
```

This starts PostgreSQL on `localhost:5432` with the credentials from `docker-compose.yml`
(`ascend` / `ascend_dev_password`, database `ascend_dev`), matching `.env.example`.

Don't have Docker available? Point `DATABASE_URL` in `services/api/.env` at any PostgreSQL 14+
instance you have running locally instead.

## 6. Run the Prisma migration

```bash
cd services/api
pnpm prisma:migrate
cd ../..
```

This applies the committed migration in `services/api/prisma/migrations/` and regenerates the
Prisma client. Use `pnpm prisma:deploy` instead in CI/production (applies migrations without
prompting to create a new one).

## 7. Start the API

```bash
pnpm api:dev
```

The API listens on `http://localhost:3000` by default. Swagger/OpenAPI docs are served at
`http://localhost:3000/docs`. Confirm it's up:

```bash
curl http://localhost:3000/health
```

Alternatively, run the whole backend (PostgreSQL + API) in Docker:

```bash
docker compose up -d
```

## 8. Start the Flutter app

With the API running, launch an emulator/simulator or connect a device, then:

```bash
cd apps/mobile
flutter run
```

By default the app targets `http://10.0.2.2:3000` (the Android emulator's alias for your
machine's `localhost` — see the troubleshooting note below). To point at a different host, e.g.
an iOS simulator or a physical device on your network:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000       # iOS simulator
flutter run --dart-define=API_BASE_URL=http://192.168.1.23:3000    # physical device
```

## 9. Running tests

```bash
# Backend unit tests
pnpm api:test

# Backend end-to-end tests (needs PostgreSQL reachable at DATABASE_URL,
# e.g. `docker compose up -d postgres` first)
pnpm api:test:e2e

# Backend lint
pnpm api:lint
```

```bash
# Mobile static analysis
cd apps/mobile && flutter analyze

# Mobile tests
cd apps/mobile && flutter test

# Mobile formatting check
cd apps/mobile && dart format --output=none --set-exit-if-changed .
```

## 10. Troubleshooting: Android emulator and `localhost`

The Android emulator runs in its own virtual network, so `localhost`/`127.0.0.1` inside the
emulator refers to the emulator itself, not your host machine. Use the special alias
**`10.0.2.2`** instead — this is already the mobile app's default (`AppConfig.apiBaseUrl` in
`apps/mobile/lib/core/config/app_config.dart`), so no extra configuration is needed when running
against a locally-hosted API.

If you're using a physical Android/iOS device instead of an emulator/simulator, it can't reach
`10.0.2.2` or `localhost` at all — pass your machine's LAN IP address via
`--dart-define=API_BASE_URL=http://<your-lan-ip>:3000` as shown above, and make sure the device
and your machine are on the same network with port 3000 reachable (check firewall rules).

iOS Simulator (unlike Android) shares the host's network namespace, so `http://localhost:3000`
works there without any special alias.

## Verified Build Results

The results below are from an actual foundation-stabilization pass, run in a sandboxed Linux
container. Every command was executed for real; nothing here is inferred or assumed. Where a
step could not be completed, that is stated explicitly rather than marked done.

**Environment**

| | |
|---|---|
| OS | Ubuntu 24.04.4 LTS (`Linux 6.18.5-fc-v18`, x86_64) |
| Node.js | v22.22.2 |
| pnpm | 10.33.0 |
| Flutter | 3.44.8 (stable) |
| Dart | 3.12.2 |
| PostgreSQL | 16 (Docker service, per `docker-compose.yml`) |

**Backend**

| Check | Command | Result |
|---|---|---|
| Install deps (frozen lockfile) | `pnpm install --filter @project-ascend/api... --frozen-lockfile` | PASSED |
| Prisma client generation | `pnpm api:prisma:generate` | PASSED |
| Prisma schema validation/format | `prisma validate`, `prisma format` + `git diff --exit-code` | PASSED |
| Migrations applied to a live Postgres | `pnpm --filter @project-ascend/api prisma:deploy` (against `ascend_dev` and `ascend_test`) | PASSED |
| Lint | `pnpm api:lint` | PASSED, 0 errors/warnings |
| Unit tests | `pnpm api:test` | **PASSED — 8/8 tests** |
| E2E tests (real Postgres, real HTTP via Supertest) | `pnpm api:test:e2e` | **PASSED — 19/19 tests**, run twice for reproducibility |
| Build | `pnpm api:build` | PASSED |
| `GET /health` | `curl http://localhost:3000/health` against a directly-run instance of the built output (`node dist/main.js`) | PASSED — `{"data":{"status":"ok","timestamp":"..."},"meta":{},"error":null}` |

The e2e suite exercises registration, login, refresh (including rotation and family-wide
revocation on reuse), profile, preferences, devices (including duplicate-connection upserting),
onboarding, and logout end-to-end against a real database.

**Docker**

`docker build` / `docker compose build` / `docker compose up` **could not be executed** in this
sandbox: outbound pulls of the `node:20-alpine` base image are blocked by the sandbox's egress
policy (`production.cloudfront.docker.com` returns `403`, confirmed via the proxy's own
diagnostics). This is an environment restriction, not a defect in the Dockerfile or compose
config, and it was not worked around (no alternate registries, no disabling of the policy).

To compensate, the logic the multi-stage `api.Dockerfile` performs was validated directly on the
host, outside Docker:
- `pnpm --filter @project-ascend/api deploy --prod --legacy <dir>` was run to reproduce the
  `build` stage's self-contained output.
- The generated Prisma client (`.prisma/client`) was confirmed present in that output (this was
  not true on the first attempt — see Known Limitations).
- The deployed output was run directly (`node dist/main.js`) with the same environment variables
  the `runtime` stage would set, and `/health`, `/auth/register`, and `/auth/login` were all
  confirmed to work against a real Postgres instance.
- `docker compose config --quiet` (which doesn't require pulling images) was run to confirm
  `docker-compose.yml` is syntactically valid and its `migrate`/`api` dependency ordering
  (`service_healthy` / `service_completed_successfully`) is well-formed.

Because of this, the Docker health check and the "runs as non-root without pnpm at runtime"
property are believed correct by construction (the `runtime` stage never installs pnpm and the
`HEALTHCHECK` calls the same `/health` endpoint verified above) but were **not** verified inside
an actual container in this sandbox.

**Mobile**

| Check | Command | Result |
|---|---|---|
| `flutter --version` | — | `Flutter 3.44.8 • Dart 3.12.2` |
| Dependencies | `flutter pub get` | PASSED |
| Static analysis | `flutter analyze` | PASSED — "No issues found!" |
| Formatting | `dart format --output=none --set-exit-if-changed .` | PASSED |
| Tests | `flutter test` | **PASSED — 18/18 tests** |

**Known limitations**

- Docker images were never literally built or run as containers in this sandbox (see above);
  the underlying `pnpm deploy` + Prisma-client packaging logic was validated by direct execution
  instead. Anyone with unrestricted Docker Hub access should run `docker compose build && docker
  compose up -d` to get a final container-level confirmation — the `docker-build` job added to
  `.github/workflows/backend.yml` does this automatically on every push/PR.
- Concurrent refresh-token reuse (two simultaneous requests racing to rotate the same token) is
  proven via unit tests that mock the transaction boundary, plus reasoning about PostgreSQL's
  default READ COMMITTED isolation making the guarded `updateMany` a safe compare-and-swap — not
  via literal simultaneous real HTTP requests hitting a live server.
