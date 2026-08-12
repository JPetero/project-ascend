import { DeploymentEnvironment, resolveAscendEnv } from './deployment-environment';

/**
 * S15 Part 3 — `prisma/seed-beta-feature-flags.ts`'s environment guard,
 * extracted into a pure function so it's unit-testable without a database
 * connection (the prisma/ directory sits outside `src/`'s Jest `rootDir`
 * and the script itself talks to a real `PrismaClient`). Computes
 * `ASCEND_ENV` via `resolveAscendEnv` and throws only when it resolves to
 * `'production'` — staging and development are both allowed, matching the
 * S15 Part 1 model where staging correctly runs `NODE_ENV=production` but
 * must still be able to seed this beta-only profile.
 */
export function assertBetaLaunchProfileAllowed(
  rawAscendEnv: string | undefined,
  nodeEnv: string,
): DeploymentEnvironment {
  const ascendEnv = resolveAscendEnv(rawAscendEnv, nodeEnv);
  if (ascendEnv === 'production') {
    throw new Error(
      'Refusing to run the beta feature-flag launch profile against a production environment (ASCEND_ENV=production). ' +
        'This profile intentionally disables integrations a real production deployment may already have configured and enabled.',
    );
  }
  return ascendEnv;
}
