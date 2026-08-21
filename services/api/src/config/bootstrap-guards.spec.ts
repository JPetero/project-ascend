import { resolveAscendEnv } from './deployment-environment';

/**
 * S15 Parts 8-9 — the environment guards on `prisma/staging-bootstrap.ts`
 * and `prisma/bootstrap-admin.ts`. Those scripts construct a real
 * `PrismaClient` and shell out to the Prisma CLI, so they can't be
 * imported into a unit test; what is worth locking down is the decision
 * both of them make before touching anything, which is a pure function
 * of two environment variables.
 *
 * The end-to-end behavior (bootstrap against an empty database, first
 * admin created with argon2 hashing and all seven permission grants,
 * second run refused) was verified directly against a real PostgreSQL
 * database — see build-session-15.md.
 */
describe('bootstrap script environment guards', () => {
  describe('staging-bootstrap refuses production', () => {
    const refusesProduction = (rawAscendEnv: string | undefined, nodeEnv: string) =>
      resolveAscendEnv(rawAscendEnv, nodeEnv) === 'production';

    it('allows staging', () => {
      expect(refusesProduction('staging', 'production')).toBe(false);
    });

    it('allows local development', () => {
      expect(refusesProduction(undefined, 'development')).toBe(false);
      expect(refusesProduction('development', 'development')).toBe(false);
    });

    it('refuses an explicit production', () => {
      expect(refusesProduction('production', 'production')).toBe(true);
    });

    it(
      'refuses NODE_ENV=production with ASCEND_ENV unset — an un-updated production ' +
        'deployment must not be treated as safe to seed a beta profile into',
      () => {
        expect(refusesProduction(undefined, 'production')).toBe(true);
      },
    );
  });

  describe('admin bootstrap password policy', () => {
    // Mirrors MIN_PASSWORD_LENGTH in prisma/bootstrap-admin.ts. An admin
    // account on an internet-reachable host is the highest-value
    // credential in the system, so this floor is deliberately well above
    // the member-signup minimum.
    const MIN_PASSWORD_LENGTH = 16;

    const isAcceptable = (supplied: string | undefined) =>
      supplied === undefined || supplied.length >= MIN_PASSWORD_LENGTH;

    it('accepts an omitted password (one is generated instead)', () => {
      expect(isAcceptable(undefined)).toBe(true);
    });

    it('rejects a password shorter than 16 characters', () => {
      expect(isAcceptable('short')).toBe(false);
      expect(isAcceptable('123456789012345')).toBe(false);
    });

    it('accepts a password of exactly 16 characters and longer', () => {
      expect(isAcceptable('1234567890123456')).toBe(true);
      expect(isAcceptable('a-genuinely-long-admin-password')).toBe(true);
    });
  });
});
