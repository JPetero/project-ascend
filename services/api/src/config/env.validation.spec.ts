import 'reflect-metadata';
import { validateEnv } from './env.validation';

function baseConfig(overrides: Record<string, unknown> = {}) {
  return {
    DATABASE_URL: 'postgresql://user:pass@localhost:5432/db',
    JWT_ACCESS_SECRET: 'a-real-secret-value',
    JWT_REFRESH_SECRET: 'another-real-secret-value',
    ...overrides,
  };
}

describe('validateEnv', () => {
  it('accepts a minimal valid development config', () => {
    expect(() => validateEnv(baseConfig())).not.toThrow();
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
});
