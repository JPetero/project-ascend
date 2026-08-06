# Security

This document describes the controls actually implemented in this sprint, and the gaps that
exist before this could run in production.

## Implemented controls

### Authentication

- Passwords hashed with **Argon2** (`argon2` npm package, default parameters), never stored or
  logged in plaintext.
- **Short-lived JWT access tokens** (15 minutes by default, `JWT_ACCESS_TTL`), signed with a
  server-side secret, sent as a Bearer token.
- **Rotating refresh tokens**: opaque, `{tokenId}.{secret}` format. Only the Argon2 hash of the
  secret is stored in `refresh_tokens.tokenHash` — the raw secret exists only in the token
  handed to the client, never persisted server-side. Revoking the presented token and creating
  its replacement happen inside a single Prisma transaction, so a client can never observe (or
  race) a moment where both are simultaneously valid.
- **Refresh-token family tracking & reuse detection**: every token descended from the same
  login/register shares a `familyId`. Presenting a token that's already been rotated out (or
  revoked) is treated as possible theft: `AuthService.handleRefreshTokenReuse` revokes every
  still-active token in that family and records an `auth.refresh_token_reuse_detected` audit
  event, without exposing the reason to the client beyond a generic "invalid or expired" 401.
- Every route requires a valid access token by default (`JwtAuthGuard` registered as a global
  `APP_GUARD`); routes opt out explicitly with `@Public()`, not the other way around — a new
  route is locked down unless someone deliberately opens it.
- Refresh tokens are scoped with an expiry (`JWT_REFRESH_TTL`, 30 days by default) and can carry a
  `deviceName`, laying the groundwork for a future "manage your sessions/devices" screen.
- Mobile client stores tokens exclusively via `flutter_secure_storage` (platform keychain/
  keystore) — never in `shared_preferences` or any other unencrypted storage.

### Input validation & output hygiene

- Every DTO uses `class-validator` decorators; the global `ValidationPipe` runs with
  `whitelist: true` and `forbidNonWhitelisted: true` — unexpected fields are rejected outright,
  not silently dropped.
- `AllExceptionsFilter` normalizes every error into the shared envelope and **never forwards a
  raw exception message, stack trace, or database error to the client** for 5xx errors; those are
  logged server-side only, and the client gets a generic "Something went wrong" message.
- Cross-user access is checked explicitly: `DevicesService` verifies a device connection belongs
  to the requesting user before allowing update/delete, returning 404 (not 403) for someone
  else's device, to avoid confirming the resource's existence to an unauthorized caller.

### Transport & headers

- `helmet()` applied globally for standard security headers.
- CORS is configured (not left wide open by accident) via `CORS_ORIGIN`.
- Rate limiting via `@nestjs/throttler`: 100 requests/minute per client by default, tightened to
  10 requests/minute (tracked per route, not shared) on `/auth/register`, `/auth/login`, and
  `/auth/refresh` specifically, since those are the credential-guessing-prone endpoints.

### Privacy defaults

- Profiles are private by default; there is no public-by-default sharing surface in this sprint.
- No location sharing exists yet at all (not even opt-in) — nothing to default incorrectly.
- The `AscendShareService` (`apps/mobile/lib/features/sharing`) lets a user explicitly hide
  weight, body measurements, and route/location before generating a shareable achievement card;
  those fields are hidden by default and must be explicitly opted into per share.
- Wearable connections are simulated in this sprint (see [wearables.md](wearables.md)) — no real
  health data leaves the device, so there is nothing to leak yet, by construction.
- `AuditEvent` metadata is populated by call sites that are instructed never to include secrets,
  passwords, or raw tokens — see the comment in `AuditService.record`.

### Configuration

- `env.validation.ts` fails fast at boot if required secrets (`DATABASE_URL`,
  `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`) are missing or malformed, and additionally refuses
  to start in `NODE_ENV=production` if either JWT secret still has the checked-in `dev_` prefix —
  a deliberate guardrail against shipping the example secrets.
- `.env` is gitignored; `.env.example` documents every variable with safe local defaults only.

## Known gaps before production

These are explicitly **not** implemented in this sprint and must be addressed before a real
launch:

- **Email verification.** Registration does not confirm the email address belongs to the user.
  The code is structured so this can be added without reshaping `AuthService` (a
  `status: PENDING_VERIFICATION` on `User`, a verification-token flow, and a guard on
  sensitive actions), but it does not exist yet.
- **Password reset.** The Sign In screen has a "Forgot password?" placeholder that shows a
  message and does nothing else. No reset-token flow exists.
- **User-facing notification of detected token reuse.** Reuse of a rotated-out refresh token
  already revokes the entire token family and records an audit event server-side (see
  "Implemented controls" above), but the affected user isn't notified (email/push) that a
  session was force-revoked, and there's no admin/security-alerts UI surfacing these events yet.
- **Account lockout / brute-force protection beyond rate limiting.** `/auth/login` is throttled
  to 10 requests/minute per client, but there is no per-account lockout or exponential backoff
  after repeated failed attempts against a single account from different clients/IPs.
- **Secrets management.** `.env` files are fine for local development; production needs a real
  secrets manager (e.g., AWS Secrets Manager, GCP Secret Manager, Vault) rather than environment
  variables set by hand.
- **Dependency/vulnerability scanning.** No `npm audit`/Dependabot/Snyk-equivalent is wired into
  CI yet.
- **Security headers beyond Helmet's defaults** (e.g., a tuned Content-Security-Policy) have not
  been reviewed for this specific API's needs.
- **PII/health-data handling policy.** As real health data (from wearables) and body-measurement
  fields become populated, this needs an explicit data-retention and deletion policy (and likely
  encryption at rest for sensitive fields) beyond what a generic PostgreSQL deployment provides
  by default.
- **Camera-based body estimates.** Not implemented in this sprint. When they are, the disclaimer
  requirements in the product identity section (no claims of clinical accuracy, no diagnosis)
  need to be enforced in the UI copy at the point of use, not just in this document.
- **Audit log review tooling.** `AuditEvent` rows are written, but there is no admin surface to
  review them yet.
