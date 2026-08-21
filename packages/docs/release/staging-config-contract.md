# Staging Configuration Contract

S15 Part 7. The complete, categorized list of every environment variable
the API reads, and exactly what each one must be for a **staging**
deployment (`NODE_ENV=production`, `ASCEND_ENV=staging`).

This is the authoritative variable list — it is derived from
`services/api/src/config/env.validation.ts` and
`services/api/src/config/configuration.ts`, which are the only two places
the backend actually reads configuration. `services/api/.env.staging.example`
is a fill-in-the-blanks copy of the same thing.

Variables are grouped by whether staging can boot without them:

- **REQUIRED** — the API refuses to boot without a valid value.
- **REQUIRED FOR STAGING** — optional in local dev, but
  `DeploymentConfigValidation` hard-fails a deployed environment without
  a safe value.
- **RECOMMENDED** — staging boots fine without it, but something
  degrades in a way you should know about.
- **OPTIONAL** — leave unset for Stage B; each corresponds to a feature
  flag that stays off until its dependency is real (see
  [beta/release-stages.md](../beta/release-stages.md)).

---

## REQUIRED — the API will not boot without these

| Variable | Staging value | Enforced by |
|---|---|---|
| `DATABASE_URL` | Real Postgres 16+ connection string. Host must **not** be `localhost`/`127.0.0.1`/`0.0.0.0`. | `DeploymentConfigValidation` |
| `JWT_ACCESS_SECRET` | 32+ random chars (`openssl rand -base64 48`). Must not start with `dev_`. Must differ from the refresh secret. Must differ from production's. | `DeploymentConfigValidation` |
| `JWT_REFRESH_SECRET` | Same rules, different value. | `DeploymentConfigValidation` |

## REQUIRED FOR STAGING — safe in dev, hard-fail once deployed

| Variable | Staging value | Why |
|---|---|---|
| `NODE_ENV` | `production` | Node/Nest production-optimized behavior. A deployed `ASCEND_ENV` with any other `NODE_ENV` is rejected at boot. |
| `ASCEND_ENV` | `staging` | Ascend's deployment tier. See [staging-deployment.md](../staging-deployment.md#s15-part-1-correction-node_env-vs-ascend_env). |
| `CORS_ORIGIN` | Explicit comma-separated origin allowlist — the staging admin app's real origin. Never `*`. | An open CORS policy on an internet-reachable host is a real vulnerability, not a staging convenience. |
| `APP_PUBLIC_URL` | The real `https://` URL this staging API is reachable at. Must be https, must not be a local address. | Password-reset and email-verification links are built from it; a wrong value ships dead links in real email. |

## RECOMMENDED — staging boots without these, but something degrades

| Variable | Default if unset | What degrades |
|---|---|---|
| `PORT` | `3000` | Nothing — set it only if your host requires a specific port. |
| `EMAIL_PROVIDER` + `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `EMAIL_FROM_ADDRESS`, `EMAIL_FROM_NAME` | `console` — emails are logged, not sent | **Password reset and email verification cannot be completed by a tester on a real phone**, because the link only ever appears in the server log. Fine if testers only ever sign up and stay signed in; set up real SMTP the moment you want to test either flow. `GET /admin/release-readiness` reports `email` as `CONFIG_REQUIRED` in a deployed environment when left on `console`. |
| `MEDIA_STORAGE_PROVIDER=s3` + `MEDIA_S3_BUCKET`, `MEDIA_S3_REGION`, `MEDIA_S3_ENDPOINT`, `MEDIA_S3_ACCESS_KEY_ID`, `MEDIA_S3_SECRET_ACCESS_KEY`, `MEDIA_S3_PUBLIC_BASE_URL` | `local` — files written to the container filesystem | Uploaded media (Gallery, profile photos, Community posts) **does not survive a container restart or redeploy**, and is not shared across instances. Acceptable for a single-container staging box where losing test uploads is fine; not acceptable for production. |
| `JWT_ACCESS_TTL` / `JWT_REFRESH_TTL` | `15m` / `30d` | Nothing — override only to test token-expiry behavior deliberately. |

## OPTIONAL — leave unset for Stage B

Each of these corresponds to a feature flag that stays **off** for the
connected Android internal beta. Leaving them unset is the intended
configuration, not a gap — the corresponding feature is absent rather
than broken, and `GET /admin/release-readiness` reports each honestly.

| Variable(s) | Feature | Flag that stays off |
|---|---|---|
| `GOOGLE_OAUTH_CLIENT_ID` | Google sign-in (note: the **mobile** app takes `GOOGLE_CLIENT_ID` as a `--dart-define`, a different name for the same client id) | `GOOGLE_SIGN_IN` |
| `APPLE_CLIENT_ID` | Apple sign-in | (iOS only — Stage D) |
| `AI_PROVIDER` + `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` / `GEMINI_API_KEY` (and optional `*_MODEL` overrides) | Live Ascend AI | `LIVE_AI` |
| `BRAVE_SEARCH_API_KEY` | Research Mode retrieval | `RESEARCH_MODE` |
| `FCM_SERVICE_ACCOUNT_JSON`, `FCM_PROJECT_ID` | Remote push notifications | `REMOTE_PUSH` |
| `APPLE_IAP_SHARED_SECRET` | Apple purchase verification | `STORE_PURCHASES` |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`, `GOOGLE_PLAY_PACKAGE_NAME` | Google Play purchase verification | `STORE_PURCHASES` |

The free, deterministic Atlas/Nova companion path works with no AI key
at all, and email/password auth works with no OAuth client at all — both
are fully functional at Stage B.

---

## Staging secrets are not production secrets

Never reuse a value between the two environments — especially the JWT
secrets. A staging box is inherently less locked down (more people have
access, more things get logged, it gets rebuilt casually), so treating
its secrets as disposable-but-real is the only safe posture. A leaked
staging JWT secret that also signs production tokens is a production
incident.

The reverse also holds: `DeploymentConfigValidation` applies the *same*
strength requirements to staging as to production. Staging is
internet-reachable, so "it's only staging" is not a reason to use a weak
secret.

## Verifying the contract is satisfied

After deploying with these values set:

```bash
# 1. Process alive, and database-aware readiness
curl https://staging-api.<your-domain>/livez
curl https://staging-api.<your-domain>/readyz

# 2. Everything above, as a structured report (needs a MANAGE_PLATFORM admin)
curl -H "Authorization: Bearer <token>" \
  https://staging-api.<your-domain>/admin/release-readiness
```

Confirm `ascendEnv: "staging"`, `migrations.upToDate: true`, and
`security.productionSafe: true`. `pnpm staging:smoke` (S15 Part 14)
automates exactly this.
