import {
  DeploymentConfigValidation,
  DeploymentConfigValidationInput,
} from './deployment-config-validation';

function baseInput(
  overrides: Partial<DeploymentConfigValidationInput> = {},
): DeploymentConfigValidationInput {
  return {
    ascendEnv: 'development',
    nodeEnv: 'development',
    jwtAccessSecret: 'a-sufficiently-long-access-token-secret-value',
    jwtRefreshSecret: 'a-sufficiently-long-refresh-token-secret-value',
    corsOrigin: 'https://app.example.com',
    databaseUrl: 'postgresql://user:pass@db.internal:5432/db',
    appPublicUrl: 'https://app.example.com',
    ...overrides,
  };
}

describe('DeploymentConfigValidation', () => {
  describe('development', () => {
    it('is always valid regardless of everything else', () => {
      const result = DeploymentConfigValidation.validate(
        baseInput({
          ascendEnv: 'development',
          nodeEnv: 'development',
          jwtAccessSecret: 'short',
          jwtRefreshSecret: 'short',
          corsOrigin: '*',
          databaseUrl: 'postgresql://user:pass@localhost:5432/db',
          appPublicUrl: undefined,
        }),
      );
      expect(result).toEqual({ isValid: true, violations: [] });
    });

    it('is valid under NODE_ENV=test too', () => {
      const result = DeploymentConfigValidation.validate(
        baseInput({ ascendEnv: 'development', nodeEnv: 'test' }),
      );
      expect(result.isValid).toBe(true);
    });
  });

  describe.each<DeploymentEnvironmentCase>([{ ascendEnv: 'staging' }, { ascendEnv: 'production' }])(
    '$ascendEnv (deployed environment)',
    ({ ascendEnv }) => {
      it('is valid when every check is satisfied and NODE_ENV=production', () => {
        const result = DeploymentConfigValidation.validate(
          baseInput({ ascendEnv, nodeEnv: 'production' }),
        );
        expect(result).toEqual({ isValid: true, violations: [] });
      });

      it('rejects NODE_ENV anything other than production', () => {
        const result = DeploymentConfigValidation.validate(
          baseInput({ ascendEnv, nodeEnv: 'development' }),
        );
        expect(result.isValid).toBe(false);
        expect(result.violations.some((v) => v.includes('requires NODE_ENV=production'))).toBe(
          true,
        );
      });

      it('rejects development JWT secrets', () => {
        const result = DeploymentConfigValidation.validate(
          baseInput({
            ascendEnv,
            nodeEnv: 'production',
            jwtAccessSecret: 'dev_access_secret_but_long_enough_to_pass_length_check',
          }),
        );
        expect(result.isValid).toBe(false);
        expect(result.violations.some((v) => v.includes('development JWT secrets'))).toBe(true);
      });

      it('rejects a JWT secret shorter than 32 characters', () => {
        const result = DeploymentConfigValidation.validate(
          baseInput({ ascendEnv, nodeEnv: 'production', jwtAccessSecret: 'short-secret' }),
        );
        expect(result.isValid).toBe(false);
        expect(result.violations.some((v) => v.includes('shorter than 32 characters'))).toBe(true);
      });

      it('rejects identical access/refresh JWT secrets', () => {
        const sameSecret = 'a-sufficiently-long-shared-secret-value-oops';
        const result = DeploymentConfigValidation.validate(
          baseInput({
            ascendEnv,
            nodeEnv: 'production',
            jwtAccessSecret: sameSecret,
            jwtRefreshSecret: sameSecret,
          }),
        );
        expect(result.isValid).toBe(false);
        expect(result.violations.some((v) => v.includes('same value'))).toBe(true);
      });

      it('rejects a wildcard CORS_ORIGIN', () => {
        const result = DeploymentConfigValidation.validate(
          baseInput({ ascendEnv, nodeEnv: 'production', corsOrigin: '*' }),
        );
        expect(result.isValid).toBe(false);
        expect(result.violations.some((v) => v.includes('CORS_ORIGIN'))).toBe(true);
      });

      it('rejects a localhost DATABASE_URL', () => {
        const result = DeploymentConfigValidation.validate(
          baseInput({
            ascendEnv,
            nodeEnv: 'production',
            databaseUrl: 'postgresql://user:pass@localhost:5432/db',
          }),
        );
        expect(result.isValid).toBe(false);
        expect(result.violations.some((v) => v.includes('DATABASE_URL'))).toBe(true);
      });

      it('rejects a 127.0.0.1 DATABASE_URL', () => {
        const result = DeploymentConfigValidation.validate(
          baseInput({
            ascendEnv,
            nodeEnv: 'production',
            databaseUrl: 'postgresql://user:pass@127.0.0.1:5432/db',
          }),
        );
        expect(result.isValid).toBe(false);
      });

      it('rejects a missing APP_PUBLIC_URL', () => {
        const result = DeploymentConfigValidation.validate(
          baseInput({ ascendEnv, nodeEnv: 'production', appPublicUrl: undefined }),
        );
        expect(result.isValid).toBe(false);
        expect(result.violations.some((v) => v.includes('APP_PUBLIC_URL unset'))).toBe(true);
      });

      it('rejects a non-https APP_PUBLIC_URL', () => {
        const result = DeploymentConfigValidation.validate(
          baseInput({ ascendEnv, nodeEnv: 'production', appPublicUrl: 'http://app.example.com' }),
        );
        expect(result.isValid).toBe(false);
        expect(result.violations.some((v) => v.includes('https://'))).toBe(true);
      });

      it('rejects an unparseable APP_PUBLIC_URL', () => {
        const result = DeploymentConfigValidation.validate(
          baseInput({ ascendEnv, nodeEnv: 'production', appPublicUrl: 'not a url' }),
        );
        expect(result.isValid).toBe(false);
        expect(result.violations.some((v) => v.includes('is not a valid URL'))).toBe(true);
      });

      it('rejects a localhost APP_PUBLIC_URL', () => {
        const result = DeploymentConfigValidation.validate(
          baseInput({ ascendEnv, nodeEnv: 'production', appPublicUrl: 'https://localhost' }),
        );
        expect(result.isValid).toBe(false);
        expect(result.violations.some((v) => v.includes('local-development-only address'))).toBe(
          true,
        );
      });

      it('reports every violation at once, not just the first', () => {
        const sameSecret = 'short';
        const result = DeploymentConfigValidation.validate(
          baseInput({
            ascendEnv,
            nodeEnv: 'development',
            jwtAccessSecret: sameSecret,
            jwtRefreshSecret: sameSecret,
            corsOrigin: '*',
            databaseUrl: 'postgresql://user:pass@localhost:5432/db',
            appPublicUrl: undefined,
          }),
        );
        expect(result.isValid).toBe(false);
        // NODE_ENV, short secret (both), same secret, CORS, DATABASE_URL,
        // APP_PUBLIC_URL — at least 6 distinct violations reported together.
        expect(result.violations.length).toBeGreaterThanOrEqual(6);
      });
    },
  );
});

interface DeploymentEnvironmentCase {
  ascendEnv: 'staging' | 'production';
}
