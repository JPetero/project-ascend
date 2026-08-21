import { execFileSync } from 'child_process';
import { resolveAscendEnv } from '../src/config/deployment-environment';

/**
 * S15 Part 8 — one command that takes an empty staging database to a
 * ready-to-serve state, in the correct order, with the right guard on
 * each step.
 *
 * The three steps below already existed as separate commands, and doing
 * them by hand in the wrong order is a real failure mode: seeding before
 * migrating fails against a schema-less database, and seeding the beta
 * feature profile before the reference data leaves the flag rows
 * pointing at a database that has no exercises or achievements to gate.
 *
 * Deliberately NOT destructive. This never drops, resets, or truncates
 * anything — every step is idempotent (`migrate deploy` skips applied
 * migrations, both seeds upsert), so running it twice against the same
 * database is safe and running it against a populated staging database
 * does not destroy test data. Resetting staging data is a separate,
 * explicitly-confirmed operation — see
 * packages/docs/release/staging-data-policy.md.
 *
 * Refuses to run against production: the beta feature profile it seeds
 * intentionally disables integrations a production deployment may have
 * legitimately enabled.
 */

const steps: Array<{ name: string; args: string[] }> = [
  {
    // Applies every committed migration. Never `migrate dev`, which can
    // prompt to author a new migration — not what a deploy should do.
    name: 'Apply migrations (prisma migrate deploy)',
    args: ['prisma', 'migrate', 'deploy'],
  },
  {
    // Reference/catalog data only — exercises, foods, achievements,
    // legal document versions. Creates zero user-generated rows (see
    // beta/beta-feature-profile.md's demo-data audit), so it is safe in
    // every environment.
    name: 'Seed reference data (prisma db seed)',
    args: ['prisma', 'db', 'seed'],
  },
  {
    // The Stage B feature profile — see beta/release-stages.md.
    name: 'Seed beta feature-flag profile',
    args: ['ts-node', 'prisma/seed-beta-feature-flags.ts'],
  },
];

function main(): void {
  const ascendEnv = resolveAscendEnv(process.env.ASCEND_ENV, process.env.NODE_ENV ?? 'development');

  if (ascendEnv === 'production') {
    throw new Error(
      'Refusing to run the staging bootstrap against a production environment ' +
        '(ASCEND_ENV=production). Step 3 seeds the beta feature profile, which ' +
        'intentionally disables integrations a production deployment may already have ' +
        'configured and enabled. Run `prisma migrate deploy` and `prisma db seed` ' +
        'individually against production instead.',
    );
  }

  if (!process.env.DATABASE_URL) {
    throw new Error(
      'DATABASE_URL is not set — refusing to guess which database to bootstrap. ' +
        'Set it to the staging database connection string explicitly.',
    );
  }

  console.log(`Bootstrapping database for ASCEND_ENV=${ascendEnv}.`);
  // Never log DATABASE_URL itself — it carries the database password.
  console.log(`Steps: ${steps.length}. This is idempotent and non-destructive.\n`);

  steps.forEach((step, index) => {
    console.log(`[${index + 1}/${steps.length}] ${step.name}`);
    // execFileSync (not execSync) so no argument is ever passed through
    // a shell — nothing here is interpolated from user input today, and
    // this keeps that true if a step ever grows an argument.
    execFileSync('npx', step.args, { stdio: 'inherit' });
    console.log('');
  });

  console.log('Staging bootstrap complete.');
  console.log(
    'Next: create the first admin (pnpm bootstrap:admin), then verify with ' +
      'pnpm staging:smoke.',
  );
}

try {
  main();
} catch (error: unknown) {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
}
