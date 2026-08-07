# Ascend Admin

A thin React + Vite web client over `services/api`'s existing `admin` module (Build Session 8 Part 17). Lets an ADMIN-role account work the support-ticket queue, community-report moderation queue, affordability-eligibility review queue, and Ascend Promote campaign review queue.

## Scope

Covers the four moderation queues the backend already exposes under `/admin`. Does not implement refresh-token rotation (an expired session just signs the admin out) or a user/role-management screen — promoting an account to ADMIN is still a direct database operation, same as the backend's own e2e tests do it.

## Running locally

```bash
pnpm install
cp apps/admin/.env.example apps/admin/.env   # point VITE_API_BASE_URL at your running API
pnpm admin:dev
```

Requires `services/api` running locally (`pnpm api:dev`) and an account with `role: ADMIN`.

## Scripts

- `pnpm admin:dev` — Vite dev server
- `pnpm admin:build` — type-check and production build
- `pnpm admin:test` — Vitest
- `pnpm admin:lint` — ESLint
