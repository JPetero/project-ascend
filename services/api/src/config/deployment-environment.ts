/**
 * The deployment tier this backend process is actually running as —
 * distinct from `NODE_ENV` (`development | test | production`), which
 * this repo deliberately never overloads with a third `'staging'` value
 * (S15 Part 1). The prior session's `staging-deployment.md` told
 * operators to set `NODE_ENV=staging`, but `env.validation.ts` only ever
 * accepted `development | test | production` — the documented staging
 * procedure could never actually boot. `NODE_ENV` stays exactly the
 * three values the wider Node ecosystem (Express, etc.) expects when it
 * branches on it for production-optimized behavior (view caching, error
 * page verbosity, ...); `ASCEND_ENV` is the separate, semantically
 * correct "which real-world environment is this" signal every
 * Ascend-specific safety check in this file's neighbor,
 * `deployment-config-validation.ts`, actually cares about.
 *
 * The intended pairing (enforced by `DeploymentConfigValidation`, not
 * this file):
 *
 *   local development  → NODE_ENV=development, ASCEND_ENV=development
 *   automated tests     → NODE_ENV=test,        ASCEND_ENV=development
 *   staging              → NODE_ENV=production,  ASCEND_ENV=staging
 *   production            → NODE_ENV=production,  ASCEND_ENV=production
 *
 * Staging runs `NODE_ENV=production` deliberately — it's a real,
 * internet-reachable deployment and should get Node/Nest's own
 * production-optimized behavior, not the development mode meant for a
 * developer's own machine.
 */
export type DeploymentEnvironment = 'development' | 'staging' | 'production';

export const DEPLOYMENT_ENVIRONMENTS: readonly DeploymentEnvironment[] = [
  'development',
  'staging',
  'production',
];

/**
 * True for any environment that is a real, deployed, internet-reachable
 * process — staging and production alike — as opposed to a developer's
 * own machine. Every "don't ship this misconfigured" check in
 * `DeploymentConfigValidation` gates on this, not on `NODE_ENV`, since
 * `NODE_ENV=production` is also correctly set for staging (see the
 * module doc comment above) — checking `NODE_ENV` there would either
 * miss staging entirely or require inventing `NODE_ENV=staging`, which
 * is exactly the mistake this file exists to undo.
 */
export function isDeployedEnvironment(env: DeploymentEnvironment): boolean {
  return env !== 'development';
}

/**
 * The one place both `env.validation.ts` (boot-time hard-fail) and
 * `configuration.ts` (the `AppConfig.ascendEnv` value every other
 * service, e.g. `ReleaseReadinessService`, actually reads at runtime)
 * resolve `ASCEND_ENV` from raw env vars — so they can never disagree.
 *
 * Safety net, not a default to rely on going forward: an existing
 * deployment that already sets `NODE_ENV=production` (every production
 * deployment before S15) but hasn't been updated to also set the new
 * `ASCEND_ENV` must keep being treated as a real deployed environment,
 * not silently downgraded to `'development'` just because that's
 * `ASCEND_ENV`'s own class-validator default. Only applies when
 * `ASCEND_ENV` is truly absent from the raw environment — an explicit
 * `ASCEND_ENV=development` alongside `NODE_ENV=production` (e.g. testing
 * production-mode Node locally) is a deliberate, allowed choice this
 * never overrides.
 */
export function resolveAscendEnv(
  rawAscendEnv: string | undefined,
  nodeEnv: string,
): DeploymentEnvironment {
  if (rawAscendEnv === undefined) {
    return nodeEnv === 'production' ? 'production' : 'development';
  }
  return DEPLOYMENT_ENVIRONMENTS.includes(rawAscendEnv as DeploymentEnvironment)
    ? (rawAscendEnv as DeploymentEnvironment)
    : 'development';
}
