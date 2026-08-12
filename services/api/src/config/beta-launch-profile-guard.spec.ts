import { assertBetaLaunchProfileAllowed } from './beta-launch-profile-guard';

describe('assertBetaLaunchProfileAllowed', () => {
  it('allows an explicit ASCEND_ENV=staging', () => {
    expect(() => assertBetaLaunchProfileAllowed('staging', 'production')).not.toThrow();
  });

  it('allows an explicit ASCEND_ENV=development', () => {
    expect(() => assertBetaLaunchProfileAllowed('development', 'development')).not.toThrow();
  });

  it('allows local development with ASCEND_ENV unset (defaults to development)', () => {
    expect(() => assertBetaLaunchProfileAllowed(undefined, 'development')).not.toThrow();
  });

  it('allows automated tests (NODE_ENV=test, ASCEND_ENV unset)', () => {
    expect(() => assertBetaLaunchProfileAllowed(undefined, 'test')).not.toThrow();
  });

  it('rejects an explicit ASCEND_ENV=production', () => {
    expect(() => assertBetaLaunchProfileAllowed('production', 'production')).toThrow(
      /ASCEND_ENV=production/,
    );
  });

  it(
    'rejects NODE_ENV=production with ASCEND_ENV unset — the resolveAscendEnv safety net ' +
      'treats an un-updated production deployment as still production, not a silent downgrade',
    () => {
      expect(() => assertBetaLaunchProfileAllowed(undefined, 'production')).toThrow(
        /ASCEND_ENV=production/,
      );
    },
  );

  it('allows a deliberate ASCEND_ENV=development override even with NODE_ENV=production', () => {
    expect(() => assertBetaLaunchProfileAllowed('development', 'production')).not.toThrow();
  });

  it('returns the resolved environment when allowed', () => {
    expect(assertBetaLaunchProfileAllowed('staging', 'production')).toBe('staging');
    expect(assertBetaLaunchProfileAllowed(undefined, 'development')).toBe('development');
  });
});
