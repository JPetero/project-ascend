import 'reflect-metadata';
import { validateEnv } from './env.validation';

// S15 Part 1-2 — long enough (32+ chars) and distinct from each other so
// every "boots fine as a deployed environment" test keeps passing once
// validateEnv enforces JWT secret length/uniqueness there; dedicated
// tests below cover the rejection paths with intentionally short/equal/
// local values. deployment-config-validation.spec.ts covers every
// individual check exhaustively — this file focuses on how validateEnv
// wires ASCEND_ENV/NODE_ENV into that shared validator, plus the
// class-validator-level required-field checks.
function baseConfig(overrides: Record<string, unknown> = {}) {
  return {
    DATABASE_URL: 'postgresql://user:pass@prod-db.internal:5432/db',
    JWT_ACCESS_SECRET: 'a-sufficiently-long-access-token-secret-value',
    JWT_REFRESH_SECRET: 'a-sufficiently-long-refresh-token-secret-value',
    APP_PUBLIC_URL: 'https://app.example.com',
    ...overrides,
  };
}

describe('validateEnv', () => {
  it('accepts a minimal valid development config', () => {
    expect(() =>
      validateEnv({
        DATABASE_URL: 'postgresql://user:pass@localhost:5432/db',
        JWT_ACCESS_SECRET: 'a-real-secret-value',
        JWT_REFRESH_SECRET: 'another-real-secret-value',
      }),
    ).not.toThrow();
  });

  it('rejects a config missing a required secret', () => {
    const config = baseConfig();
    delete (config as Record<string, unknown>).DATABASE_URL;

    expect(() => validateEnv(config)).toThrow(/Invalid environment configuration/);
  });

  it('rejects an invalid ASCEND_ENV value', () => {
    expect(() => validateEnv(baseConfig({ ASCEND_ENV: 'preprod' }))).toThrow(
      /Invalid environment configuration/,
    );
  });

  it('rejects an invalid NODE_ENV value', () => {
    expect(() => validateEnv(baseConfig({ NODE_ENV: 'staging' }))).toThrow(
      /Invalid environment configuration/,
    );
  });

  describe('ASCEND_ENV / NODE_ENV pairing (S15 Part 1)', () => {
    it('defaults ASCEND_ENV to development when unset and NODE_ENV is not production', () => {
      // A wildcard CORS_ORIGIN would be rejected for any deployed
      // environment — this only passes because ASCEND_ENV correctly
      // defaults to 'development' here, not because CORS is exempted.
      expect(() =>
        validateEnv(baseConfig({ NODE_ENV: 'development', CORS_ORIGIN: '*' })),
      ).not.toThrow();
    });

    it(
      'safety net: NODE_ENV=production with ASCEND_ENV omitted still gets full ' +
        'deployment hardening, not silently downgraded to development',
      () => {
        expect(() => validateEnv(baseConfig({ NODE_ENV: 'production', CORS_ORIGIN: '*' }))).toThrow(
          /CORS_ORIGIN/,
        );
      },
    );

    it('an explicit ASCEND_ENV=development is a deliberate, allowed override even with NODE_ENV=production', () => {
      expect(() =>
        validateEnv(
          baseConfig({ NODE_ENV: 'production', ASCEND_ENV: 'development', CORS_ORIGIN: '*' }),
        ),
      ).not.toThrow();
    });

    it('rejects ASCEND_ENV=staging paired with NODE_ENV=development', () => {
      expect(() =>
        validateEnv(baseConfig({ NODE_ENV: 'development', ASCEND_ENV: 'staging' })),
      ).toThrow(/requires NODE_ENV=production/);
    });

    it('accepts ASCEND_ENV=staging paired with NODE_ENV=production and safe config', () => {
      expect(() =>
        validateEnv(
          baseConfig({
            NODE_ENV: 'production',
            ASCEND_ENV: 'staging',
            CORS_ORIGIN: 'https://staging.example.com',
          }),
        ),
      ).not.toThrow();
    });
  });

  describe('deployed-environment checks apply identically to staging and production (S15 Part 2)', () => {
    it.each(['staging', 'production'] as const)(
      'refuses to boot %s with development JWT secrets',
      (ascendEnv) => {
        expect(() =>
          validateEnv(
            baseConfig({
              NODE_ENV: 'production',
              ASCEND_ENV: ascendEnv,
              JWT_ACCESS_SECRET: 'dev_access_secret_but_long_enough_to_pass_length_check',
              CORS_ORIGIN: 'https://app.example.com',
            }),
          ),
        ).toThrow(/development JWT secrets/);
      },
    );

    it.each(['staging', 'production'] as const)(
      'refuses to boot %s with an unset/wildcard CORS_ORIGIN',
      (ascendEnv) => {
        expect(() =>
          validateEnv(baseConfig({ NODE_ENV: 'production', ASCEND_ENV: ascendEnv })),
        ).toThrow(/CORS_ORIGIN unset or "\*"/);
        expect(() =>
          validateEnv(
            baseConfig({ NODE_ENV: 'production', ASCEND_ENV: ascendEnv, CORS_ORIGIN: '*' }),
          ),
        ).toThrow(/CORS_ORIGIN unset or "\*"/);
      },
    );

    it.each(['staging', 'production'] as const)(
      'boots %s with an explicit CORS_ORIGIN allowlist',
      (ascendEnv) => {
        expect(() =>
          validateEnv(
            baseConfig({
              NODE_ENV: 'production',
              ASCEND_ENV: ascendEnv,
              CORS_ORIGIN: 'https://app.example.com,https://admin.example.com',
            }),
          ),
        ).not.toThrow();
      },
    );
  });

  it('allows a wildcard CORS_ORIGIN outside a deployed environment', () => {
    expect(() => validateEnv(baseConfig({ NODE_ENV: 'development' }))).not.toThrow();
    expect(() => validateEnv(baseConfig({ NODE_ENV: 'test' }))).not.toThrow();
  });

  describe('S14 Part 12 / S15 Part 2 — strengthened deployed-environment checks', () => {
    const deployed = (
      ascendEnv: 'staging' | 'production',
      overrides: Record<string, unknown> = {},
    ) =>
      baseConfig({
        NODE_ENV: 'production',
        ASCEND_ENV: ascendEnv,
        CORS_ORIGIN: 'https://app.example.com',
        ...overrides,
      });

    it.each(['staging', 'production'] as const)(
      'refuses to boot %s with a JWT secret shorter than 32 characters',
      (ascendEnv) => {
        expect(() =>
          validateEnv(deployed(ascendEnv, { JWT_ACCESS_SECRET: 'short-secret' })),
        ).toThrow(/shorter than 32 characters/);
        expect(() =>
          validateEnv(deployed(ascendEnv, { JWT_REFRESH_SECRET: 'short-secret' })),
        ).toThrow(/shorter than 32 characters/);
      },
    );

    it.each(['staging', 'production'] as const)(
      'refuses to boot %s with identical access/refresh JWT secrets',
      (ascendEnv) => {
        const sameSecret = 'a-sufficiently-long-shared-secret-value-oops';
        expect(() =>
          validateEnv(
            deployed(ascendEnv, {
              JWT_ACCESS_SECRET: sameSecret,
              JWT_REFRESH_SECRET: sameSecret,
            }),
          ),
        ).toThrow(/same value/);
      },
    );

    it.each(['staging', 'production'] as const)(
      'refuses to boot %s with DATABASE_URL pointed at localhost',
      (ascendEnv) => {
        expect(() =>
          validateEnv(
            deployed(ascendEnv, { DATABASE_URL: 'postgresql://user:pass@localhost:5432/db' }),
          ),
        ).toThrow(/local-development-only address, not a real deployed database/);
      },
    );

    it.each(['staging', 'production'] as const)(
      'refuses to boot %s with APP_PUBLIC_URL unset',
      (ascendEnv) => {
        const config = deployed(ascendEnv);
        delete (config as Record<string, unknown>).APP_PUBLIC_URL;

        expect(() => validateEnv(config)).toThrow(/APP_PUBLIC_URL unset/);
      },
    );

    it.each(['staging', 'production'] as const)(
      'refuses to boot %s with a non-https APP_PUBLIC_URL',
      (ascendEnv) => {
        expect(() =>
          validateEnv(deployed(ascendEnv, { APP_PUBLIC_URL: 'http://app.example.com' })),
        ).toThrow(/must use https:\/\//);
      },
    );

    it.each(['staging', 'production'] as const)(
      'boots %s once every strengthened check is satisfied',
      (ascendEnv) => {
        expect(() => validateEnv(deployed(ascendEnv))).not.toThrow();
      },
    );
  });
});
