# Founder Setup Checklist

S13 Part 16-27. This repository is referenced from three places
(`.github/workflows/mobile.yml`, `apps/mobile/android/app/build.gradle.kts`,
`packages/docs/qa/release-device-matrix.md`) as "the Founder setup
checklist" — this is that document. Every item below is something this
sandboxed build environment genuinely cannot provision (no real
credentials, no Apple/Google developer accounts, no production
infrastructure) and that a human with account access has to do once,
outside of any AI session. Each item names the exact env var(s)/file it
sets and the exact [Release Readiness](#release-readiness-cross-check)
check that turns green once it's done, so there's a single source of
truth for "is this actually configured" rather than trusting a checklist
someone forgot to update.

Nothing here is optional for a real beta — every unchecked row is either
a feature that silently won't work (e.g. no Google sign-in button
succeeding) or a build that can't ship (e.g. an unsigned Android release).

## Backend secrets (`services/api/.env`)

| # | What | Env var(s) | Where to get it | Release Readiness check |
|---|---|---|---|---|
| 1 | Strong JWT signing secrets | `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET` | `openssl rand -base64 48`, twice — never reuse the checked-in `dev_...` defaults in staging/production. S14 Part 12 also hard-fails boot in production if either secret is under 32 characters or the two are identical, not just the `dev_` prefix check. | `security.usingDevJwtSecrets` |
| 2 | Locked-down CORS origin | `CORS_ORIGIN` | Your actual mobile/admin origin(s), never `*` in production | `security.corsWildcard` |
| 3 | Your real public app URL | `APP_PUBLIC_URL` | The real `https://` domain this backend is reachable at — used to build password-reset/email-verification links. S14 Part 12 removed the old fabricated `https://app.projectascend.com` fallback and now hard-fails boot in production if this is unset, non-https, or a localhost address, since a missing value used to silently ship broken links in real emails. | (not yet its own Release Readiness field) |
| 4 | Media storage | `MEDIA_STORAGE_PROVIDER=s3` + `MEDIA_S3_*` vars | An S3-compatible bucket (AWS S3, Cloudflare R2, MinIO, etc.) | `integrations.mediaStorage` |
| 5 | Transactional email | `EMAIL_PROVIDER=smtp` + `EMAIL_SMTP_*` vars | Any SMTP provider (SES, Postmark, SendGrid SMTP, etc.) — needed for password reset/verification emails | `integrations.email` |
| 6 | Google sign-in | `GOOGLE_CLIENT_ID` (backend + mobile) | A Google Cloud OAuth 2.0 client — see https://developers.google.com/identity/sign-in/android/start-integrating | `integrations.googleSignIn` |
| 7 | Apple sign-in | `APPLE_CLIENT_ID` | An Apple Developer Program "Sign in with Apple" services ID | `integrations.appleSignIn` |
| 8 | Live AI provider | one of `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` / `GEMINI_API_KEY`, matching `AI_PROVIDER` | The chosen provider's console | `integrations.aiProvider` |
| 9 | Research mode | `BRAVE_SEARCH_API_KEY` | https://brave.com/search/api/ | `integrations.research` |
| 10 | Remote push notifications | `FCM_SERVICE_ACCOUNT_JSON`, `FCM_PROJECT_ID` | A Firebase project's service account key (Firebase Console → Project Settings → Service Accounts) | `integrations.remotePush` |
| 11 | Apple in-app purchases | `APPLE_IAP_SHARED_SECRET` | App Store Connect → your app → App Information → App-Specific Shared Secret | `integrations.appleIap` |
| 12 | Google Play in-app purchases | `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`, `GOOGLE_PLAY_PACKAGE_NAME` | Google Play Console → API access → a service account with Play Developer API access | `integrations.googleIap` |

Copy `services/api/.env.example` as a starting point; it documents every
variable's shape. `GET /admin/release-readiness` (Admin app → Release
readiness) reflects every row above live, without exposing the secret
values themselves.

## Database

| # | What | How |
|---|---|---|
| 13 | Run every committed migration against the real database | `pnpm prisma:deploy` (never `prisma:migrate` outside local dev — that command can prompt to create a new migration, which isn't what a deploy should do) |
| 14 | Confirm migrations actually applied | Release Readiness's `migrations.upToDate` — see [release-readiness.service.ts](../../services/api/src/modules/admin/release-readiness.service.ts) |

## Android release signing

| # | What | How |
|---|---|---|
| 15 | Generate a real upload keystore | `keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload` — see https://flutter.dev/to/reference-keystore |
| 16 | Populate `android/key.properties` | Copy `apps/mobile/android/key.properties.example` to `apps/mobile/android/key.properties` (never committed — see `apps/mobile/android/.gitignore`) and fill in the real `storePassword`/`keyPassword`/`keyAlias`/`storeFile` |
| 17 | Confirm the release build is actually signed with it, not the debug keystore | Build `flutter build apk --release --flavor prod`, then `keytool -printcert -jarfile build/app/outputs/flutter-apk/app-prod-release.apk` and confirm the certificate is your real upload key, not the Flutter debug keystore — see `qa/release-device-matrix.md` row 28 |

Until step 16 is done, `flutter build apk --release --flavor prod` and
`--flavor staging`/`--flavor dev` release builds all still work locally
(signed with the debug keystore) — but as of S14 Part 1,
`assembleProdRelease`/`bundleProdRelease` (the `prod` flavor specifically)
now **fails the build outright** rather than silently shipping a
debug-signed binary. Populate `android/key.properties` (local builds) or
the CI secrets below before attempting a real `prod` build.

## GitHub Actions secrets/variables (`.github/workflows/mobile.yml`, S14 Part 3)

| # | What | Type | Where used |
|---|---|---|---|
| 18 | `STAGING_API_BASE_URL` | Repository **variable** (not secret — it's just a hostname, e.g. `https://staging-api.example.com`) | `staging-or-dev-build` job. Unset → CI builds a `dev`-flavor "development-sideload" APK instead (see `packages/docs/beta/android-sideload-beta.md`), never a fake staging URL. |
| 19 | `ASCEND_KEYSTORE_BASE64` | Repository **secret** — `base64 -w0 upload-keystore.jks` (never commit the raw `.jks`) | `production-build` job, decoded to a temp file and fed to `ASCEND_KEYSTORE_PATH` |
| 20 | `ASCEND_KEYSTORE_PASSWORD`, `ASCEND_KEY_ALIAS`, `ASCEND_KEY_PASSWORD` | Repository **secrets** | Same job — mirrors `android/key.properties`'s fields exactly |
| 21 | `PROD_API_BASE_URL` | Repository **secret** (treated as sensitive alongside signing, even though the URL itself isn't secret, for one consistent "production" secret group) | `production-build` job's `--dart-define=API_BASE_URL=...` |

`production-build` is a guarded job: it only runs on a push to `main`,
and only when every one of secrets #19-21 above is set — until then it's
simply skipped, not failed, so CI stays green while production remains
unconfigured. Once all four exist, every push to `main` produces a real
release-signed `ascend-prod-signed-aab`/`ascend-prod-signed-apk` — never
auto-published to the Play Store.

## iOS (out of scope for this sandbox entirely)

This environment has no Xcode and no Apple Developer Program membership,
so nothing iOS-side beyond the Info.plist branding fix (S13 Part 16-27)
has been touched. A human with Apple Developer access needs to: create
an App ID, generate a real signing certificate/provisioning profile, and
configure the Push Notifications capability before any of
`UIBackgroundModes: remote-notification` in `Info.plist` actually
delivers a push — see `build-session-11.md`'s disclosed limitation on
this exact point.

## Release Readiness cross-check

Every "Release Readiness check" column above is a live field returned by
`GET /admin/release-readiness` (Admin app → Release readiness page,
requires the `MANAGE_PLATFORM` admin permission). Once every row in this
checklist is done, that page should show every `security`/`integrations`
value green, `migrations.upToDate: true`, and — for a production
environment specifically — `security.productionSafe: true`. That page is
the actual source of truth for "is this environment ready," not this
document's checkboxes (which can go stale); use this checklist to get
there, and that page to confirm you did.
