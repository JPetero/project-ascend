# Admin App Deployment & Hardening

S14 Part 28-29. `apps/admin` never had a deployment story of its own —
`staging-deployment.md` covers the backend and mobile, but not this. The
admin app is a thin React/Vite client over `services/api`'s `admin`
module (support tickets, moderation queues, feature flags, release
readiness, granular RBAC management), so a misconfigured or openly
reachable copy of it is a real risk surface, not just a broken build.

**Not build-verified in this sandbox** — no privileged Docker daemon is
available here (`docker version` connects to the client but not a
running daemon), so `infrastructure/docker/admin.Dockerfile` follows the
same well-established multi-stage pattern already used by
`api.Dockerfile`, but nobody has run `docker build` against it yet.
Do that once before relying on it for a real deploy.

## What ships in this session's work

- **`infrastructure/docker/admin.Dockerfile`** — a Node build stage
  (`vite build`) feeding a minimal `nginxinc/nginx-unprivileged:1.27-alpine`
  runtime stage. That base image (not plain `nginx:alpine`) means the
  container never runs as root at any point, listening on port 8080
  instead of 80 — matching `api.Dockerfile`'s own fully-non-root
  `USER ascend` runtime stage.
- **`infrastructure/docker/nginx-admin.conf`** — security headers
  appropriate for an internal tool: `X-Frame-Options: DENY`,
  `X-Content-Type-Options: nosniff`, `Referrer-Policy`,
  `X-Robots-Tag: noindex, nofollow`, a restrictive `Permissions-Policy`,
  and a `Content-Security-Policy` (`default-src 'self'`, no inline
  scripts, `object-src`/`frame-ancestors 'none'`). See the file's own
  comment for why `connect-src` is scoped to `https:` rather than one
  exact origin — the real backend host is only known at the admin app's
  own build time, not at this static nginx config's build time.
- **`apps/admin/public/robots.txt`** (`Disallow: /`) and an
  `index.html` `<meta name="robots" content="noindex, nofollow">` —
  belt-and-suspenders with the `X-Robots-Tag` header above.
- **`apps/admin/src/config/apiConfigValidation.ts`** — mirrors the
  mobile app's `AppConfigValidation` (S14 Part 2): a production build
  (`vite build`, not the dev server) now refuses to render the real app
  if `VITE_API_BASE_URL` is unset, non-`https://`, or points at
  `localhost`/`127.0.0.1` — showing `ConfigurationErrorScreen` instead of
  silently talking to nothing. `.github/workflows/admin.yml`'s CI build
  step now passes a placeholder `VITE_API_BASE_URL` so the pipeline
  itself keeps working; that placeholder is not a real deployment target.
- **Root `.dockerignore`** — every Dockerfile in this repo builds with
  the repo root as context; without this, that context included `.git`,
  every workspace's `node_modules`, and any local `.env` file.
- **`docker-compose.yml`'s `api`/`migrate` services** gained
  `cap_drop: ["ALL"]` and `security_opt: ["no-new-privileges:true"]` —
  safe for these specifically because both are plain Node processes
  already running as the non-root `ascend` user and binding an
  unprivileged port, so they need zero Linux capabilities.
  **Deliberately not applied to `postgres`/`pgadmin`**: those official
  images' entrypoints need real capabilities (`CHOWN`/`SETUID`/`SETGID`/
  `DAC_OVERRIDE`) to fix data-directory ownership on first boot, and
  with no Docker daemon available here to verify a change, guessing
  wrong would risk breaking every future session's `docker compose up`
  for local development. A human with Docker access can test
  `cap_drop`/`no-new-privileges` there and add them if verified safe.

## The one thing hardening the app itself can't fix

RBAC (`AdminPermission`) and the config validation above are
*application-layer* controls — they assume a request already reached the
app. An admin panel this powerful (feature flags, moderation actions,
release readiness, RBAC grants) should never be placed on the open
internet relying on login-screen auth alone. Put it behind one of:

- A VPN or private network the admin host only accepts traffic from.
- An IP allowlist at the load balancer/reverse proxy in front of it.
- An SSO/identity-aware proxy (Cloudflare Access, a cloud provider's
  IAP, etc.) that authenticates *before* any request reaches this
  container.

None of that infrastructure exists in this sandbox to configure or
verify — this is the same category of gap as `staging-deployment.md`'s
"no staging environment provisioned," documented here rather than
silently assumed away.

## Building and running

```bash
docker build \
  --build-arg VITE_API_BASE_URL=https://your-real-api-host \
  -f infrastructure/docker/admin.Dockerfile \
  -t ascend-admin .

docker run --rm -p 8080:8080 ascend-admin
```

`VITE_API_BASE_URL` is baked into the JS bundle at build time (standard
Vite behavior — there is no runtime env var to change afterward), so a
new backend host means a new image build, not a container restart.
