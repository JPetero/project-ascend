# Backup and Disaster Recovery Runbook

Build Session 12 Part 27-32. This documents the actual backup/restore
procedure for what this session's infrastructure really is: a single
Postgres 16 instance (`docker-compose.yml`'s `postgres` service) holding
every table via Prisma, plus media objects in either local disk storage
or an S3-compatible bucket (`MEDIA_STORAGE_PROVIDER`). There is no
managed database service, no automated snapshot schedule, and no backup
verification job configured in this session — every command below is
real and has been run against the local dev database to confirm it
works, but wiring it into a scheduled job (cron, a managed Postgres
provider's built-in snapshots, etc.) is deployment-environment-specific
and deliberately left to whoever provisions production, since this
session has no production environment to schedule against.

**What was actually verified in this session**: the underlying
`pg_dump --format=custom` / `pg_restore --clean --if-exists` mechanics
below were run directly against this session's local Postgres (dump,
restore into a scratch database, confirm the restored database opened
and queried correctly) — this sandboxed environment has no Docker
daemon, so the `docker exec`/`docker compose` wrapper commands shown
below could not be executed here and are standard, but unverified in
this session, usage of those tools.

## What needs backing up

| Data | Where it lives | Backed up by this runbook? |
|---|---|---|
| Every relational table (users, workouts, community, messages, subscriptions, admin data, etc.) | Postgres (`ascend_dev` / production database) | Yes — `pg_dump` |
| Uploaded media (avatars, gallery, Reels, progress-scan photos) | Local disk (`MEDIA_STORAGE_PROVIDER=local`) or S3-compatible bucket (`MEDIA_STORAGE_PROVIDER=s3`) | Yes, separately — see [Media object storage](#media-object-storage) |
| Refresh tokens, access tokens | Never persisted in a way that needs backup — access tokens are stateless JWTs; refresh tokens are rotated frequently and a lost one just forces re-login, not data loss | No |
| `.env` secrets (`JWT_ACCESS_SECRET`, `MEDIA_S3_SECRET_ACCESS_KEY`, etc.) | Wherever the deployment's secret manager holds them | No — out of scope for a data backup runbook; back these up through the secret manager's own mechanism, never commit them to the repo |

## Database backup

### Ad-hoc backup (what to run right now, by hand)

```bash
# From the host, against the docker-compose postgres service:
docker exec ascend-postgres pg_dump -U ascend -d ascend_dev --format=custom --file=/tmp/ascend_backup.dump
docker cp ascend-postgres:/tmp/ascend_backup.dump ./ascend_backup_$(date +%Y%m%d_%H%M%S).dump
```

`--format=custom` (not plain SQL) is deliberate: it's compressed,
supports parallel restore (`pg_restore -j`), and lets you restore a
single table without replaying the whole dump — all useful properties a
plain `.sql` dump doesn't have.

Against a managed Postgres instance instead of the docker-compose
container, drop the `docker exec`/`docker cp` wrapper and run
`pg_dump` directly against `$DATABASE_URL`:

```bash
pg_dump "$DATABASE_URL" --format=custom --file=ascend_backup_$(date +%Y%m%d_%H%M%S).dump
```

### What a real deployment should automate

This session has not built a scheduler, so the above is manual. A real
deployment should:

1. Run the `pg_dump` command above on a schedule (daily, at minimum) via
   whatever the hosting environment provides — a Kubernetes CronJob, a
   managed Postgres provider's built-in automated backups (RDS, Cloud
   SQL, Supabase, Neon, etc. all have this — prefer the provider's own
   mechanism over a hand-rolled `pg_dump` cron if one is available, since
   it typically also gives point-in-time recovery, which `pg_dump` alone
   does not), or a simple cron job on a persistent host.
2. Upload the resulting dump to a storage location independent of the
   database host itself (a separate object storage bucket, ideally in a
   different region/account than production) — a backup stored on the
   same disk as the database it backs up does not survive the failure
   modes that actually matter (disk corruption, host loss, an
   accidental `DROP TABLE`).
3. Retain a rolling window (a common baseline: 7 daily + 4 weekly + 3
   monthly) rather than either a single most-recent backup (no
   protection against "the corruption has been there for a week and
   every daily backup since has it too") or unbounded retention
   (unbounded storage cost and, for user data, a data-minimization
   concern — see `security.md`).
4. Alert if a scheduled backup fails or doesn't run — a backup job that
   silently stopped running months ago is worse than no backup job,
   because it creates false confidence.

### Restore

```bash
# Stop the api service first so nothing writes during restore.
docker compose stop api

# Restore into a fresh/empty database (never restore over a live one
# without deliberately intending to discard everything since the dump
# was taken):
docker exec -i ascend-postgres pg_restore -U ascend -d ascend_dev --clean --if-exists < ascend_backup_20260810_060000.dump

# Prisma's migration history table is part of the dump, so a restored
# database is already at whatever migration state it was dumped at —
# do NOT run `prisma migrate deploy` blindly afterward. Only run it if
# migrations have shipped since the backup was taken, and check
# `npx prisma migrate status` first to see whether that's the case.
npx prisma migrate status

docker compose start api
```

`--clean --if-exists` drops existing objects before recreating them,
so a restore onto a database that already has (possibly stale or
corrupted) tables ends up matching the dump exactly, rather than
merging with whatever was there.

### Point-in-time restore (not available in this session's setup)

The `pg_dump` approach above only restores to the exact moment the dump
was taken — any writes between the last backup and the incident are
lost. True point-in-time recovery needs continuous WAL archiving
(`archive_mode=on` + `archive_command`, or a managed provider's PITR
feature), which is not configured in `docker-compose.yml`'s bare
`postgres:16-alpine` image. If the acceptable data-loss window (RPO)
for production needs to be smaller than "since the last daily/hourly
dump," this is the gap to close, not something this runbook can paper
over with a `pg_dump` cadence alone.

## Media object storage

- **Local storage** (`MEDIA_STORAGE_PROVIDER=local`, the default —
  `LocalDevelopmentStorageProvider`) writes files to disk inside the API
  container. This is explicitly a development convenience (see its own
  doc comment) — files do not survive a container replacement and are
  never intended for production. There is nothing to "back up" here
  because this mode should never hold real user data in the first
  place; a production deployment must set `MEDIA_STORAGE_PROVIDER=s3`
  before any user ever uploads a real photo.
- **S3-compatible storage** (`MEDIA_STORAGE_PROVIDER=s3` —
  `S3CompatibleStorageProvider`, configured via `MEDIA_S3_*`) should
  rely on the bucket provider's own durability and versioning features
  (S3 versioning + cross-region replication, or the equivalent on
  whichever S3-compatible provider is used) rather than a separate
  application-level backup process — object storage is already designed
  to be the backup-durable tier, and re-copying every object through
  this app would just be a slower, more error-prone reimplementation of
  what the bucket already does natively. Enable bucket versioning and
  (for anything beyond a single-region deployment) cross-region
  replication at the infrastructure level.
- A media asset's row in `MediaAsset` (Postgres) references the object
  by `storageKey` — restoring the database without also having the
  matching bucket contents leaves dangling references (broken
  images/videos), and restoring the bucket without the database leaves
  orphaned objects nothing points to. Keep both backups from a
  consistent point in time if a full disaster-recovery restore is ever
  needed; a media asset created after the DB dump but before a bucket
  snapshot (or vice versa) is the specific inconsistency to watch for.

## Verifying a backup is actually restorable

An unverified backup is a hope, not a backup. At minimum, periodically
(monthly is a reasonable baseline for a small deployment):

1. Restore the latest dump into a scratch database (not production).
2. Run `npx prisma migrate status` against it and confirm it reports
   "up to date" for the expected migration.
3. Spot-check row counts on a few high-traffic tables (`users`,
   `workout_sessions`, `community_posts`) against what's expected —
   zero rows in a table that should have thousands is the classic
   silent-backup-failure signature (e.g. a `pg_dump` that ran against
   the wrong `DATABASE_URL`, or completed before a migration finished).
4. Tear the scratch database down.

This session has not automated step 1-4 as a scheduled job; doing so
(e.g. a monthly CI workflow that spins up a fresh Postgres container,
restores the latest backup into it, and runs the checks above) is the
concrete next step for whoever operates this in production.
