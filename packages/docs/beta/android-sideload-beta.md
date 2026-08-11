# Getting Ascend onto an Android Phone Before the Play Store (S14 Part 5)

This is the first way to actually hold a build of Ascend on a real
Android phone — before a Play Console listing, before Firebase, before
any of that. It does not require understanding Gradle, Flutter, or
anything in this repository beyond following the steps below.

**This is not the Play Store release.** It's an "Internal Android
Beta" — a real, installable build with a distinct app identity
(`com.projectascend.mobile.staging` or `.dev`, never the bare
`com.projectascend.mobile` production identity) so it can sit on a
phone side by side with a future Play Store install without conflicting
with or overwriting it.

## What you'll get

Every time code changes on the `main` branch, GitHub automatically
builds an installable `.apk` file — this is what `.github/workflows/mobile.yml`'s
`staging-or-dev-build` job produces. One of two things happens,
depending on whether a staging backend has been configured yet (see
`packages/docs/staging-deployment.md`):

- **`ascend-staging-internal`** — if a real staging backend URL is
  configured (`STAGING_API_BASE_URL`, see
  `founder-setup-checklist.md`). This build talks to that real backend
  and is the one to use for actual testing.
- **`ascend-development-sideload`** — if no staging backend exists
  yet. This build only works pointed at a backend on the same machine
  it was built for (it uses the same safe default as local
  development), so on a real phone it will open, but most features that
  need the network (login, syncing, everything server-backed) won't
  work yet. It's still useful for confirming the app installs and the
  UI renders correctly on a real device before a staging backend is
  ready.

Both builds show an on-screen **STAGING** or **DEV** banner in the
corner, so there's never any doubt which build you're looking at — a
real production build never shows this banner at all.

## Step by step

1. Open this repository on **github.com** (not the GitHub mobile app —
   downloading files works better in a desktop/laptop browser, or a
   phone browser with "desktop site" enabled).
2. Click the **Actions** tab near the top.
3. Click **Mobile CI** in the left-hand list of workflows.
4. Click the most recent run with a green checkmark (a run still
   showing a yellow dot is still building — wait for it to finish).
5. Scroll down to the **Artifacts** section at the bottom of that run's
   page. You'll see `ascend-staging-internal` or
   `ascend-development-sideload` listed — click it to download a
   `.zip` file.
6. Unzip it — inside is a single `.apk` file (e.g.
   `app-staging-release.apk`).
7. Get that `.apk` file onto your Android phone. Easiest options:
   - Email it to yourself and open the attachment on the phone, or
   - Upload it to a personal cloud drive (Google Drive, Dropbox) and
     download it on the phone, or
   - Plug the phone into a computer via USB and copy the file directly.
8. On the phone, open the `.apk` file (e.g. from the Downloads app or
   your file manager). Android will likely say it blocked the install
   because the file is from an "unknown source."
9. Follow the prompt to **allow installation from this source** (exact
   wording varies by Android version/manufacturer — it's usually a
   one-time toggle for whichever app you opened the file with, like
   Files or Gmail). This is normal and expected for any app installed
   outside the Play Store — it does not mean anything is wrong.
10. Tap **Install**. Once it finishes, open the app.
11. Confirm you see the **STAGING** or **DEV** ribbon in the corner —
    if you see no ribbon at all, something is wrong; stop and report it
    rather than continuing to test.
12. Work through `packages/docs/qa/release-device-matrix.md`'s checklist
    for whatever you're testing, and note anything that doesn't work as
    expected.

## If your phone is Xiaomi/MIUI

MIUI's aggressive battery/permission management can behave differently
from stock Android — see
`packages/docs/qa/xiaomi-health-connect-checklist.md` once that's
relevant to what you're testing (Health Connect / wearable sync
specifically). For basic install/login/workout testing, the steps above
are unchanged.

## What this is not

- **Not a Play Store release.** No Play Console listing exists yet;
  this is a direct-install file, sometimes called "sideloading."
- **Not production.** Production builds (`ascend-prod-signed-aab`/
  `ascend-prod-signed-apk`) only exist once a real signing keystore and
  production backend are configured — see `founder-setup-checklist.md`.
  Nothing here should be confused with that.
- **Not automatically updating.** Each new build is a fresh `.apk` to
  download and reinstall over the old one — there's no auto-update
  mechanism for a sideloaded build.
