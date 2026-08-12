import { DeploymentEnvironment, isDeployedEnvironment } from './deployment-environment';

export interface DeploymentConfigValidationInput {
  ascendEnv: DeploymentEnvironment;
  nodeEnv: string;
  jwtAccessSecret: string;
  jwtRefreshSecret: string;
  corsOrigin: string;
  databaseUrl: string;
  appPublicUrl: string | undefined;
}

export interface DeploymentConfigValidationResult {
  isValid: boolean;
  violations: string[];
}

// Hosts that are only ever correct for a developer's own machine —
// mirrors the mobile app's AppConfigValidation.unsafeHosts (S14 Part 2):
// never acceptable for DATABASE_URL or APP_PUBLIC_URL once this is a
// real deployed (staging or production) environment.
const unsafeHosts = new Set(['localhost', '127.0.0.1', '0.0.0.0']);

// A short secret is crackable regardless of whether it happens to start
// with 'dev_' — the dev-prefix check below only catches the specific
// placeholder values docker-compose.yml/.env.example ship, not every
// weak secret an operator could type in their place.
const MIN_JWT_SECRET_LENGTH = 32;

function hostnameOf(url: string): string | null {
  try {
    return new URL(url).hostname.toLowerCase();
  } catch {
    return null;
  }
}

function parseUrl(url: string): URL | null {
  try {
    return new URL(url);
  } catch {
    return null;
  }
}

/**
 * S15 Part 2 — the deployment-environment-aware safety checks
 * `env.validation.ts`'s `validateEnv` enforces at boot, extracted into
 * a pure, throw-free function (mirroring the mobile app's
 * `AppConfigValidation.validate`, S14 Part 2) so it's directly
 * unit-testable against every `DeploymentEnvironment` without going
 * through `class-validator`/`plainToInstance`.
 *
 * Staging is internet-accessible and must reject the same dangerous
 * configuration production does — a leaked staging JWT secret, an open
 * staging CORS policy, or a staging database sitting on localhost are
 * all real incidents waiting to happen, not merely "not production yet"
 * conditions. Every check below therefore gates on
 * `isDeployedEnvironment` (staging OR production), never on `NODE_ENV`
 * or on `ascendEnv === 'production'` alone. Nothing here weakens what
 * production already required — see build-session-14.md's Part 12 for
 * the checks this consolidates from a production-only gate.
 */
export abstract class DeploymentConfigValidation {
  static validate(input: DeploymentConfigValidationInput): DeploymentConfigValidationResult {
    const violations: string[] = [];
    const deployed = isDeployedEnvironment(input.ascendEnv);

    // Staging/production must run Node's own production-optimized
    // behavior (see this module's neighbor doc comment for why —
    // ecosystem packages like Express key off NODE_ENV, not ASCEND_ENV,
    // for that). A staging box left at NODE_ENV=development would
    // silently run in dev mode despite being a real, internet-reachable
    // deployment.
    if (deployed && input.nodeEnv !== 'production') {
      violations.push(
        `ASCEND_ENV=${input.ascendEnv} requires NODE_ENV=production (Node/Nest's own ` +
          `production-optimized behavior) — got NODE_ENV=${input.nodeEnv}.`,
      );
    }

    if (!deployed) {
      return { isValid: violations.length === 0, violations };
    }

    if (input.jwtAccessSecret.startsWith('dev_') || input.jwtRefreshSecret.startsWith('dev_')) {
      violations.push(`Refusing to run ${input.ascendEnv} with development JWT secrets.`);
    }

    if (
      input.jwtAccessSecret.length < MIN_JWT_SECRET_LENGTH ||
      input.jwtRefreshSecret.length < MIN_JWT_SECRET_LENGTH
    ) {
      violations.push(
        `Refusing to run ${input.ascendEnv} with a JWT secret shorter than ` +
          `${MIN_JWT_SECRET_LENGTH} characters — a short secret is crackable regardless of its ` +
          'content.',
      );
    }

    if (input.jwtAccessSecret === input.jwtRefreshSecret) {
      violations.push(
        `Refusing to run ${input.ascendEnv} with JWT_ACCESS_SECRET and JWT_REFRESH_SECRET set ` +
          'to the same value — a leaked access token secret must never also compromise refresh ' +
          'tokens, and vice versa.',
      );
    }

    if (input.corsOrigin === '*') {
      violations.push(
        `Refusing to run ${input.ascendEnv} with CORS_ORIGIN unset or "*" — set it to an ` +
          'explicit comma-separated allowlist of origins.',
      );
    }

    const databaseHost = hostnameOf(input.databaseUrl);
    if (databaseHost !== null && unsafeHosts.has(databaseHost)) {
      violations.push(
        `Refusing to run ${input.ascendEnv} with DATABASE_URL pointed at "${databaseHost}" — ` +
          'that is a local-development-only address, not a real deployed database.',
      );
    }

    const appPublicUrl = input.appPublicUrl?.trim();
    if (!appPublicUrl) {
      violations.push(
        `Refusing to run ${input.ascendEnv} with APP_PUBLIC_URL unset — password-reset and ` +
          'email-verification links are built from it, and there is no safe placeholder to ' +
          'fall back to.',
      );
    } else {
      const parsed = parseUrl(appPublicUrl);
      if (parsed === null) {
        violations.push(`APP_PUBLIC_URL "${appPublicUrl}" is not a valid URL.`);
      } else {
        if (parsed.protocol !== 'https:') {
          violations.push(
            `Refusing to run ${input.ascendEnv} with APP_PUBLIC_URL using ` +
              `"${parsed.protocol}//" — it must use https://.`,
          );
        }
        if (unsafeHosts.has(parsed.hostname.toLowerCase())) {
          violations.push(
            `Refusing to run ${input.ascendEnv} with APP_PUBLIC_URL pointed at ` +
              `"${parsed.hostname}" — that is a local-development-only address.`,
          );
        }
      }
    }

    return { isValid: violations.length === 0, violations };
  }
}
