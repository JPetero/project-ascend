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

- **Node.js** 20+
- **pnpm** 9+ (`npm install -g pnpm`)
- **Docker** and **Docker Compose** (for PostgreSQL, and optionally the API)
- **Flutter** 3.24+ stable (includes Dart) — see https://docs.flutter.dev/get-started/install
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

## Definition of Done checklist

- [x] `docker compose up` starts PostgreSQL and the API
- [x] Prisma migrations apply successfully
- [x] Backend tests pass (`pnpm api:test`, `pnpm api:test:e2e`)
- [x] The Flutter app analyzes without errors (`flutter analyze`)
- [x] Flutter tests pass (`flutter test`)
- [x] A user can register
- [x] A user can sign in
- [x] A user can complete onboarding
- [x] Atlas or Nova is persisted
- [x] The dashboard shows the user's first name
- [x] Wearable preferences can be added and removed
- [x] The companion quick sheet works
- [x] Theme mode can change
- [x] Sign out works
- [x] Setup is fully documented (this file)
