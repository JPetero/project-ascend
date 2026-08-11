import 'reflect-metadata';
import { validateEnv } from './env.validation';

// S14 Part 12 — long enough (32+ chars) and distinct from each other so
// every existing "boots fine in production" test keeps passing once
// validateEnv also enforces JWT secret length/uniqueness in production;
// dedicated tests below cover the rejection paths with intentionally
// short/equal/local values.
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

  it('refuses to boot in production with development JWT secrets', () => {
    expect(() =>
      validateEnv(
        baseConfig({
          NODE_ENV: 'production',
          JWT_ACCESS_SECRET: 'dev_access_secret',
          CORS_ORIGIN: 'https://app.example.com',
        }),
      ),
    ).toThrow(/development JWT secrets/);
  });

  it(
    'refuses to boot in production with an unset/wildcard CORS_ORIGIN ' +
      '(Build Session 10 Parts 27-29)',
    () => {
      expect(() => validateEnv(baseConfig({ NODE_ENV: 'production' }))).toThrow(
        /CORS_ORIGIN unset or "\*"/,
      );
      expect(() => validateEnv(baseConfig({ NODE_ENV: 'production', CORS_ORIGIN: '*' }))).toThrow(
        /CORS_ORIGIN unset or "\*"/,
      );
    },
  );

  it('boots in production with an explicit CORS_ORIGIN allowlist', () => {
    expect(() =>
      validateEnv(
        baseConfig({
          NODE_ENV: 'production',
          CORS_ORIGIN: 'https://app.example.com,https://admin.example.com',
        }),
      ),
    ).not.toThrow();
  });

  it('allows a wildcard CORS_ORIGIN outside production', () => {
    expect(() => validateEnv(baseConfig({ NODE_ENV: 'development' }))).not.toThrow();
    expect(() => validateEnv(baseConfig({ NODE_ENV: 'test' }))).not.toThrow();
  });

  describe('S14 Part 12 — strengthened production checks', () => {
    const prod = (overrides: Record<string, unknown> = {}) =>
      baseConfig({
        NODE_ENV: 'production',
        CORS_ORIGIN: 'https://app.example.com',
        ...overrides,
      });

    it('refuses to boot in production with a JWT secret shorter than 32 characters', () => {
      expect(() => validateEnv(prod({ JWT_ACCESS_SECRET: 'short-secret' }))).toThrow(
        /shorter than 32 characters/,
      );
      expect(() => validateEnv(prod({ JWT_REFRESH_SECRET: 'short-secret' }))).toThrow(
        /shorter than 32 characters/,
      );
    });

    it('refuses to boot in production with identical access/refresh JWT secrets', () => {
      const sameSecret = 'a-sufficiently-long-shared-secret-value-oops';
      expect(() =>
        validateEnv(prod({ JWT_ACCESS_SECRET: sameSecret, JWT_REFRESH_SECRET: sameSecret })),
      ).toThrow(/same value/);
    });

    it('refuses to boot in production with DATABASE_URL pointed at localhost', () => {
      expect(() =>
        validateEnv(prod({ DATABASE_URL: 'postgresql://user:pass@localhost:5432/db' })),
      ).toThrow(/local-development-only address, not a real production database/);
      expect(() =>
        validateEnv(prod({ DATABASE_URL: 'postgresql://user:pass@127.0.0.1:5432/db' })),
      ).toThrow(/local-development-only address/);
    });

    it('refuses to boot in production with APP_PUBLIC_URL unset', () => {
      const config = prod();
      delete (config as Record<string, unknown>).APP_PUBLIC_URL;

      expect(() => validateEnv(config)).toThrow(/APP_PUBLIC_URL unset/);
    });

    it('refuses to boot in production with a non-https APP_PUBLIC_URL', () => {
      expect(() => validateEnv(prod({ APP_PUBLIC_URL: 'http://app.example.com' }))).toThrow(
        /must use https:\/\//,
      );
    });

    it('refuses to boot in production with an unparseable APP_PUBLIC_URL', () => {
      expect(() => validateEnv(prod({ APP_PUBLIC_URL: 'not a url' }))).toThrow(
        /is not a valid URL/,
      );
    });

    it('refuses to boot in production with APP_PUBLIC_URL pointed at localhost', () => {
      expect(() => validateEnv(prod({ APP_PUBLIC_URL: 'https://localhost' }))).toThrow(
        /local-development-only address/,
      );
    });

    it('boots in production once every strengthened check is satisfied', () => {
      expect(() => validateEnv(prod())).not.toThrow();
    });

    it('does not apply any of these production-only checks outside production', () => {
      expect(() =>
        validateEnv({
          DATABASE_URL: 'postgresql://user:pass@localhost:5432/db',
          JWT_ACCESS_SECRET: 'short',
          JWT_REFRESH_SECRET: 'short',
        }),
      ).not.toThrow();
    });
  });
});
