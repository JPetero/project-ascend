# Staging Deployment Bundle

S15 Part 12. Everything needed to run Project Ascend's staging
environment on a single host, using the images CI publishes.

This bundle exists because the root `docker-compose.yml` is **not** safe
to reuse here. That file is a local development convenience: it hardcodes
`dev_access_secret_change_me`, publishes Postgres to the host, runs
pgadmin, and builds images from source. Quietly reusing it is exactly how
a staging box ends up with development secrets signing real tokens.

## Files

| File | Purpose |
|---|---|
| `docker-compose.staging.yml` | The stack: postgres, migrate (one-shot), api, admin |
| `.env.staging.template` | Copy to `.env.staging` and fill in |
| `.gitignore` | Ensures the filled-in `.env.staging` is never committed |

## What you need first

This bundle assumes the Stage B prerequisites are already in place — see
[beta/release-stages.md](../../packages/docs/beta/release-stages.md):

1. A host that can run Docker and Docker Compose.
2. A domain name pointed at that host.
3. A reverse proxy terminating TLS in front of it — **required**, see
   [release/reverse-proxy-tls-contract.md](../../packages/docs/release/reverse-proxy-tls-contract.md).
   The compose file binds everything to `127.0.0.1`; without the proxy
   nothing is reachable.

## Procedure

```bash
# 1. Get the bundle onto the host.
git clone https://github.com/<owner>/project-ascend.git
cd project-ascend/infrastructure/staging

# 2. Fill in configuration. Every value is explained in
#    packages/docs/release/staging-config-contract.md.
cp .env.staging.template .env.staging
chmod 600 .env.staging
$EDITOR .env.staging

# 3. Authenticate to GHCR so the images can be pulled.
#    Needs a personal access token with read:packages.
echo "$GITHUB_TOKEN" | docker login ghcr.io -u <your-github-username> --password-stdin

# 4. Start the stack. Migrations run automatically before the API
#    starts — the api service waits for migrate to exit 0.
docker compose --env-file .env.staging -f docker-compose.staging.yml up -d

# 5. Seed reference data and the Stage B feature profile.
docker compose --env-file .env.staging -f docker-compose.staging.yml \
  exec -e ASCEND_ENV=staging api node -e "console.log('see note below')"
```

> **Note on step 5.** The runtime image is deliberately pruned — it
> contains no Prisma CLI and no `ts-node`, so the seed scripts cannot run
> inside it. Run them from a checkout with the toolchain installed,
> pointed at the staging database:
>
> ```bash
> cd services/api
> DATABASE_URL="<staging DATABASE_URL>" ASCEND_ENV=staging NODE_ENV=production \
>   pnpm staging:bootstrap
> ```
>
> `staging:bootstrap` is idempotent, so it is safe to re-run. Because the
> compose stack already applied migrations in step 4, its first step is a
> no-op.

```bash
# 6. Create the first admin. No credentials are hardcoded anywhere —
#    a strong password is generated and printed exactly once.
cd services/api
DATABASE_URL="<staging DATABASE_URL>" ASCEND_ENV=staging NODE_ENV=production \
  ADMIN_BOOTSTRAP_EMAIL=you@example.com pnpm bootstrap:admin

# 7. Verify.
pnpm staging:smoke --base-url https://staging-api.<your-domain>
```

## Pin the image tag

`IMAGE_TAG` in `.env.staging` should be a **commit SHA**, not `main`.

A SHA makes a redeploy reproducible and makes rollback a real target
("go back to `abc1234`") rather than a guess about what `main` pointed at
yesterday. Find the SHA in the Backend CI run summary for the commit you
want to deploy.

To upgrade:

```bash
$EDITOR .env.staging          # change IMAGE_TAG to the new SHA
docker compose --env-file .env.staging -f docker-compose.staging.yml pull
docker compose --env-file .env.staging -f docker-compose.staging.yml up -d
```

Migrations re-run automatically on each `up`, and the API waits for them.

## A caveat about the admin image

The admin app is a static bundle, so its API host is baked in **at build
time** — unlike the API, it cannot be reconfigured by an environment
variable at run time.

The published `project-ascend-admin` image is built with whatever
`STAGING_API_BASE_URL` repository variable was set when CI ran. If that
variable is unset, the image is built with a placeholder and the admin
app will not reach your API. Two options:

1. Set the `STAGING_API_BASE_URL` repository variable to your real
   staging API URL and let CI rebuild. (This also makes Mobile CI produce
   a real connected staging APK — the same variable does both jobs.)
2. Build the admin image on the host yourself:
   ```bash
   docker build -f ../docker/admin.Dockerfile \
     --build-arg VITE_API_BASE_URL=https://staging-api.<your-domain> \
     --target runtime -t project-ascend-admin:local ../..
   ```
   then point `docker-compose.staging.yml`'s admin service at that tag.

## What this bundle deliberately does not do

- **No automated backups.** Staging data is disposable by policy — see
  [release/staging-data-policy.md](../../packages/docs/release/staging-data-policy.md).
  Production needs real backups; see the backup runbook.
- **No secret manager.** Secrets come from an env file with `chmod 600`.
  That is proportionate for staging on a single host; a production
  deployment should use whatever its platform provides.
- **No pgadmin, no exposed database port.** A database admin UI on a
  public host is a liability, and nothing outside the compose network
  needs to reach Postgres directly.
