import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * S14 Part 34 — the feature profile for the very first internal Android
 * beta, distinct from `feature-flag-registry.ts`'s general-purpose
 * defaults (tuned for a fully-configured production environment).
 * Running this script only ever creates/updates `FeatureFlag` rows in
 * whichever database `DATABASE_URL` points at — it never edits the
 * registry file, so production's defaults are untouched unless someone
 * points this script at a production database (which the guard below
 * refuses).
 *
 * Founder scenario list this maps to (see beta-blockers.md and
 * founder-setup-checklist.md for the underlying setup each depends on):
 *   ON, no flag exists at all: Train, Fuel, Community, Friends/DM,
 *     Rankings, Basic Ascend AI (the non-paid companion path), Achievements,
 *     GPS cardio, Gallery, Nutrition Library, Support.
 *   Conditional — off until the dependency below is actually configured
 *     for this environment, then an admin flips it on via the Admin
 *     Feature Flags page:
 *     - GOOGLE_SIGN_IN: needs Google OAuth client configured.
 *     - REMOTE_PUSH: needs Firebase configured.
 *     - VISION_FORM_COACH: needs Vision physical-device QA to pass
 *       (qa/vision-physical-device-checklist.md) — never flip this on
 *       from a unit/e2e test result.
 *     - LIVE_AI: needs an AI provider API key configured.
 *     - RESEARCH_MODE: needs Brave Search (+ an AI provider for the
 *       generative synthesis path) configured.
 *   Off for the entire initial beta, regardless of config readiness —
 *     see beta-blockers.md Part 40 (Store Purchases needs sandbox
 *     receipt verification, restore, cancellation, and grace-period
 *     testing before it can ever be enabled, none of which is done yet):
 *     - STORE_PURCHASES
 *     - ASCEND_PROMOTE (depends on Store Purchases)
 */
const BETA_LAUNCH_PROFILE: Array<{ key: string; enabled: boolean; description: string }> = [
  {
    key: 'GOOGLE_SIGN_IN',
    enabled: false,
    description: 'Beta launch profile: off until Google OAuth is configured for this environment.',
  },
  {
    key: 'REMOTE_PUSH',
    enabled: false,
    description: 'Beta launch profile: off until Firebase is configured for this environment.',
  },
  {
    key: 'VISION_FORM_COACH',
    enabled: false,
    description:
      'Beta launch profile: off until Vision physical-device QA passes on real hardware.',
  },
  {
    key: 'LIVE_AI',
    enabled: false,
    description: 'Beta launch profile: off until an AI provider API key is configured.',
  },
  {
    key: 'RESEARCH_MODE',
    enabled: false,
    description:
      'Beta launch profile: off until Brave Search (and an AI provider) is configured.',
  },
  {
    key: 'STORE_PURCHASES',
    enabled: false,
    description:
      'Beta launch profile: off for the entire initial beta — sandbox purchase QA not done yet (see beta-blockers.md Part 40).',
  },
  {
    key: 'ASCEND_PROMOTE',
    enabled: false,
    description: 'Beta launch profile: off for the entire initial beta — depends on Store Purchases.',
  },
];

async function main() {
  if (process.env.NODE_ENV === 'production') {
    throw new Error(
      'Refusing to run the beta feature-flag launch profile against a production environment (NODE_ENV=production). ' +
        'This profile intentionally disables integrations a real production deployment may already have configured and enabled.',
    );
  }

  for (const flag of BETA_LAUNCH_PROFILE) {
    await prisma.featureFlag.upsert({
      where: { key: flag.key },
      update: { enabled: flag.enabled, description: flag.description },
      create: {
        key: flag.key,
        enabled: flag.enabled,
        description: flag.description,
        rolloutPercentage: 100,
      },
    });
    console.log(`Beta launch profile: ${flag.key} -> enabled=${flag.enabled}`);
  }
}

main()
  .catch((error: unknown) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
