import { randomBytes } from 'crypto';
import { AdminPermission, PrismaClient, UserRole } from '@prisma/client';
import * as argon2 from 'argon2';
import { resolveAscendEnv } from '../src/config/deployment-environment';

/**
 * S15 Part 9 — creates the very first admin account on a freshly
 * bootstrapped deployment.
 *
 * The chicken-and-egg problem this solves: every admin surface requires
 * an existing `ADMIN` user with the right `AdminPermissionGrant`, and
 * granting a permission itself requires `MANAGE_ADMINS` — so a brand new
 * database has no way in. Historically the answer was "do it by hand in
 * psql", which is error-prone and easy to do insecurely.
 *
 * Security posture, all of which is deliberate:
 *
 *   - NO credentials are hardcoded anywhere in this file or the
 *     repository. The email comes from ADMIN_BOOTSTRAP_EMAIL; the
 *     password is either supplied via ADMIN_BOOTSTRAP_PASSWORD or
 *     generated here with crypto.randomBytes and printed exactly once.
 *   - The password is never written to a file, never committed, and
 *     never stored anywhere but as an argon2 hash in the database —
 *     the same hashing AuthService.register uses, so the resulting
 *     account is indistinguishable from a normally-registered one.
 *   - Refuses to run if ANY admin already exists. This is what makes the
 *     script safe to leave in the image: it is a one-time bootstrap, not
 *     a standing privilege-escalation tool. Promoting a second admin is
 *     an existing admin's job, through the Admin app.
 *   - Writes an AuditEvent recording that the account was created by
 *     bootstrap, so the very first admin's origin is as traceable as
 *     every subsequent one.
 *   - Refuses a password under 16 characters. An admin account on an
 *     internet-reachable host is the highest-value credential in the
 *     system.
 *
 * Usage (staging):
 *   ADMIN_BOOTSTRAP_EMAIL=you@example.com pnpm bootstrap:admin
 */

const prisma = new PrismaClient();

const MIN_PASSWORD_LENGTH = 16;

// Every permission, so the first admin can actually administer — including
// MANAGE_ADMINS, which is what lets them grant narrower permissions to
// everyone after them without ever needing this script again.
const ALL_PERMISSIONS: AdminPermission[] = [
  AdminPermission.MODERATE_COMMUNITY,
  AdminPermission.REVIEW_ELIGIBILITY,
  AdminPermission.MANAGE_SUPPORT,
  AdminPermission.REVIEW_PROMOTIONS,
  AdminPermission.MANAGE_ADMINS,
  AdminPermission.MANAGE_PLATFORM,
  AdminPermission.REVIEW_TRAINER_VERIFICATION,
];

/** URL-safe, 32 bytes of real entropy — well beyond MIN_PASSWORD_LENGTH. */
function generatePassword(): string {
  return randomBytes(32).toString('base64url');
}

function normalizeEmail(raw: string): string {
  return raw.trim().toLowerCase();
}

function isPlausibleEmail(email: string): boolean {
  // Deliberately minimal: this is a typo guard for an operator typing
  // their own address, not an attempt to validate deliverability.
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

async function main(): Promise<void> {
  const ascendEnv = resolveAscendEnv(process.env.ASCEND_ENV, process.env.NODE_ENV ?? 'development');

  const rawEmail = process.env.ADMIN_BOOTSTRAP_EMAIL;
  if (!rawEmail) {
    throw new Error(
      'ADMIN_BOOTSTRAP_EMAIL is not set. This script never invents or defaults an admin ' +
        'address — pass the real one explicitly:\n' +
        '  ADMIN_BOOTSTRAP_EMAIL=you@example.com pnpm bootstrap:admin',
    );
  }

  const email = normalizeEmail(rawEmail);
  if (!isPlausibleEmail(email)) {
    throw new Error(`ADMIN_BOOTSTRAP_EMAIL="${rawEmail}" does not look like an email address.`);
  }

  // Every input check runs before the first database call, so a bad
  // argument fails the same way whether or not the database happens to
  // be reachable — a validation error should never be masked by a
  // connection error.
  const suppliedPassword = process.env.ADMIN_BOOTSTRAP_PASSWORD;
  if (suppliedPassword !== undefined && suppliedPassword.length < MIN_PASSWORD_LENGTH) {
    throw new Error(
      `ADMIN_BOOTSTRAP_PASSWORD is shorter than ${MIN_PASSWORD_LENGTH} characters. An admin ` +
        'account on an internet-reachable host is the highest-value credential in the system — ' +
        'use a longer one, or omit the variable entirely to have a strong password generated.',
    );
  }

  const password = suppliedPassword ?? generatePassword();
  const generated = suppliedPassword === undefined;

  // The core safety property: this is a one-time bootstrap, never a way
  // to mint an extra admin on a running system.
  const existingAdminCount = await prisma.user.count({ where: { role: UserRole.ADMIN } });
  if (existingAdminCount > 0) {
    throw new Error(
      `Refusing to run: ${existingAdminCount} admin account(s) already exist. This script only ` +
        'ever creates the FIRST admin. Promote additional admins from the Admin app with an ' +
        'account that holds MANAGE_ADMINS.',
    );
  }

  const existingUser = await prisma.user.findUnique({ where: { email } });
  if (existingUser) {
    throw new Error(
      `A user already exists with email ${email}, and it is not an admin. Refusing to silently ` +
        'take over an existing account or overwrite its password — promote it from the database ' +
        'deliberately, or bootstrap with a different address.',
    );
  }

  const passwordHash = await argon2.hash(password);

  const user = await prisma.$transaction(async (tx) => {
    const created = await tx.user.create({
      data: {
        email,
        passwordHash,
        role: UserRole.ADMIN,
        // Deliberately NOT setting emailVerifiedAt: this script proves
        // database access, not control of the mailbox. The account can
        // verify through the normal flow like any other.
      },
    });

    await tx.adminPermissionGrant.createMany({
      data: ALL_PERMISSIONS.map((permission) => ({ userId: created.id, permission })),
    });

    await tx.auditEvent.create({
      data: {
        userId: created.id,
        action: 'ADMIN_BOOTSTRAPPED',
        entityType: 'User',
        entityId: created.id,
        // Never record the password or its hash here — an audit trail is
        // read by more people than the database itself.
        metadata: {
          ascendEnv,
          grantedPermissions: ALL_PERMISSIONS,
          passwordSource: generated ? 'generated' : 'supplied',
        },
      },
    });

    return created;
  });

  console.log(`\nFirst admin created for ASCEND_ENV=${ascendEnv}.`);
  console.log(`  Email:       ${user.email}`);
  console.log(`  Permissions: ${ALL_PERMISSIONS.join(', ')}`);

  if (generated) {
    console.log('\n  Generated password (shown once, never stored anywhere in plaintext):\n');
    console.log(`      ${password}\n`);
    console.log('  Save it in a password manager now. There is no way to recover it —');
    console.log('  if it is lost, use the normal password-reset flow (which needs email');
    console.log('  delivery configured) or delete this account and re-run this script.');
  } else {
    console.log('\n  Password: the value supplied via ADMIN_BOOTSTRAP_PASSWORD.');
  }

  console.log('\n  Sign in at the Admin app. This script will now refuse to run again.\n');
}

main()
  .catch((error: unknown) => {
    console.error(`\n${error instanceof Error ? error.message : String(error)}\n`);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
