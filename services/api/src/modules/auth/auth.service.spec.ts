import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import * as argon2 from 'argon2';
import { AuditService } from '../../common/audit/audit.service';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthIdentitiesService } from '../auth-identities/auth-identities.service';
import { AppleTokenVerifier } from '../auth-identities/providers/apple-token-verifier';
import { GoogleTokenVerifier } from '../auth-identities/providers/google-token-verifier';
import { EmailService } from '../email/email.service';
import { UsersService } from '../users/users.service';
import { AuthService } from './auth.service';

describe('AuthService', () => {
  let authService: AuthService;
  let auditService: { record: jest.Mock };
  let usersService: { findByEmail: jest.Mock; findById: jest.Mock; isActive: jest.Mock };
  let emailService: { sendPasswordResetEmail: jest.Mock; sendVerificationEmail: jest.Mock };
  let authIdentitiesService: { findByProviderSubject: jest.Mock; linkIdentity: jest.Mock };
  let googleTokenVerifier: { verify: jest.Mock };
  let appleTokenVerifier: { verify: jest.Mock };
  let tx: { refreshToken: { updateMany: jest.Mock; create: jest.Mock } };
  let prisma: {
    user: { create: jest.Mock; update: jest.Mock };
    refreshToken: {
      findUnique: jest.Mock;
      create: jest.Mock;
      updateMany: jest.Mock;
      findMany: jest.Mock;
    };
    passwordResetToken: {
      findUnique: jest.Mock;
      create: jest.Mock;
      update: jest.Mock;
      updateMany: jest.Mock;
    };
    emailVerificationToken: {
      findUnique: jest.Mock;
      create: jest.Mock;
      update: jest.Mock;
      updateMany: jest.Mock;
    };
    $transaction: jest.Mock;
  };

  beforeEach(async () => {
    tx = {
      refreshToken: { updateMany: jest.fn(), create: jest.fn() },
    };
    prisma = {
      user: { create: jest.fn(), update: jest.fn() },
      refreshToken: {
        findUnique: jest.fn(),
        create: jest.fn(),
        updateMany: jest.fn(),
        findMany: jest.fn(),
      },
      passwordResetToken: {
        findUnique: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
      },
      emailVerificationToken: {
        findUnique: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
      },
      $transaction: jest.fn(async (arg: unknown) =>
        Array.isArray(arg) ? Promise.all(arg) : (arg as (tx: unknown) => Promise<unknown>)(tx),
      ),
    };
    auditService = { record: jest.fn() };
    usersService = {
      findByEmail: jest.fn(),
      findById: jest.fn(),
      isActive: jest.fn((user: { status?: string } | null) => !!user && user.status === 'ACTIVE'),
    };
    emailService = {
      sendPasswordResetEmail: jest.fn().mockResolvedValue({ delivered: false }),
      sendVerificationEmail: jest.fn().mockResolvedValue({ delivered: false }),
    };
    authIdentitiesService = {
      findByProviderSubject: jest.fn().mockResolvedValue(null),
      linkIdentity: jest.fn().mockResolvedValue({ id: 'identity-1' }),
    };
    googleTokenVerifier = { verify: jest.fn() };
    appleTokenVerifier = { verify: jest.fn() };
    prisma.refreshToken.create.mockResolvedValue({ id: 'refresh-id' });
    prisma.passwordResetToken.create.mockResolvedValue({ id: 'reset-token-id' });
    prisma.passwordResetToken.updateMany.mockResolvedValue({ count: 0 });
    prisma.emailVerificationToken.create.mockResolvedValue({ id: 'verify-token-id' });
    prisma.emailVerificationToken.updateMany.mockResolvedValue({ count: 0 });

    const moduleRef = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: prisma },
        { provide: JwtService, useValue: { signAsync: jest.fn().mockResolvedValue('signed.jwt') } },
        {
          provide: ConfigService,
          useValue: {
            get: () => ({
              jwt: {
                accessSecret: 'test-access',
                refreshSecret: 'test-refresh',
                accessTtl: '15m',
                refreshTtl: '30d',
              },
            }),
          },
        },
        { provide: AuditService, useValue: auditService },
        { provide: UsersService, useValue: usersService },
        { provide: EmailService, useValue: emailService },
        { provide: AuthIdentitiesService, useValue: authIdentitiesService },
        { provide: GoogleTokenVerifier, useValue: googleTokenVerifier },
        { provide: AppleTokenVerifier, useValue: appleTokenVerifier },
      ],
    }).compile();

    authService = moduleRef.get(AuthService);
  });

  describe('register', () => {
    it('rejects mismatched passwords before touching the database', async () => {
      await expect(
        authService.register({
          firstName: 'Ada',
          email: 'ada@example.com',
          password: 'Str0ngPass!',
          confirmPassword: 'Different1!',
          acceptedTerms: true,
        }),
      ).rejects.toBeInstanceOf(ConflictException);
      expect(prisma.user.create).not.toHaveBeenCalled();
    });

    it('rejects registration when the email is already taken', async () => {
      usersService.findByEmail.mockResolvedValue({ id: 'existing-user' });

      await expect(
        authService.register({
          firstName: 'Ada',
          email: 'ada@example.com',
          password: 'Str0ngPass!',
          confirmPassword: 'Str0ngPass!',
          acceptedTerms: true,
        }),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('creates a user with a hashed password and issues tokens', async () => {
      usersService.findByEmail.mockResolvedValue(null);
      prisma.user.create.mockResolvedValue({ id: 'new-user', email: 'ada@example.com' });
      prisma.refreshToken.create.mockResolvedValue({ id: 'token-id' });

      const result = await authService.register({
        firstName: 'Ada',
        email: 'Ada@Example.com',
        password: 'Str0ngPass!',
        confirmPassword: 'Str0ngPass!',
        acceptedTerms: true,
      });

      expect(prisma.user.create).toHaveBeenCalledTimes(1);
      const createArgs = prisma.user.create.mock.calls[0][0];
      expect(createArgs.data.email).toBe('ada@example.com');
      expect(createArgs.data.passwordHash).not.toBe('Str0ngPass!');
      expect(result.tokens.accessToken).toBe('signed.jwt');
      expect(result.tokens.refreshToken).toContain('token-id.');
    });
  });

  describe('refresh', () => {
    it('rejects a malformed refresh token', async () => {
      await expect(authService.refresh('garbage')).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('rejects a refresh token whose secret does not match the stored hash', async () => {
      prisma.refreshToken.findUnique.mockResolvedValue({
        id: 'token-id',
        familyId: 'family-1',
        tokenHash: await argon2.hash('correct-secret'),
        revokedAt: null,
        expiresAt: new Date(Date.now() + 100_000),
      });

      await expect(authService.refresh('token-id.wrong-secret')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
      expect(prisma.$transaction).not.toHaveBeenCalled();
    });

    it('rotates a valid token inside one transaction, keeping the same family', async () => {
      prisma.refreshToken.findUnique.mockResolvedValue({
        id: 'token-id',
        userId: 'user-1',
        familyId: 'family-1',
        tokenHash: await argon2.hash('secret'),
        revokedAt: null,
        deviceName: 'iPhone',
        expiresAt: new Date(Date.now() + 100_000),
      });
      usersService.findById.mockResolvedValue({
        id: 'user-1',
        email: 'ada@example.com',
        status: 'ACTIVE',
      });
      tx.refreshToken.updateMany.mockResolvedValue({ count: 1 });
      tx.refreshToken.create.mockResolvedValue({ id: 'new-token-id' });

      const result = await authService.refresh('token-id.secret');

      expect(prisma.$transaction).toHaveBeenCalledTimes(1);
      expect(tx.refreshToken.updateMany).toHaveBeenCalledWith({
        where: { id: 'token-id', revokedAt: null },
        data: { revokedAt: expect.any(Date) },
      });
      const createArgs = tx.refreshToken.create.mock.calls[0][0];
      expect(createArgs.data.familyId).toBe('family-1');
      expect(createArgs.data.deviceName).toBe('iPhone');
      expect(result.refreshToken).toContain('new-token-id.');
      // The old token is only ever revoked, never reused for a second
      // replacement — the family-wide reuse-revoke path must not fire.
      expect(prisma.refreshToken.updateMany).not.toHaveBeenCalled();
      expect(auditService.record).not.toHaveBeenCalled();
    });

    it('treats reuse of an already-revoked token as possible theft and revokes the family', async () => {
      prisma.refreshToken.findUnique.mockResolvedValue({
        id: 'token-id',
        userId: 'user-1',
        familyId: 'family-1',
        tokenHash: await argon2.hash('secret'),
        revokedAt: new Date(),
        expiresAt: new Date(Date.now() + 100_000),
      });

      await expect(authService.refresh('token-id.secret')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );

      // No transaction/rotation should ever be attempted for a token
      // that's already dead.
      expect(prisma.$transaction).not.toHaveBeenCalled();
      expect(prisma.refreshToken.updateMany).toHaveBeenCalledWith({
        where: { familyId: 'family-1', revokedAt: null },
        data: { revokedAt: expect.any(Date), reusedAt: expect.any(Date) },
      });
      expect(auditService.record).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 'user-1',
          action: 'auth.refresh_token_reuse_detected',
        }),
      );
    });

    it('treats losing the rotation race (concurrent reuse) the same as reuse, issuing no new token', async () => {
      prisma.refreshToken.findUnique.mockResolvedValue({
        id: 'token-id',
        userId: 'user-1',
        familyId: 'family-1',
        tokenHash: await argon2.hash('secret'),
        revokedAt: null, // still looked valid at read time...
        expiresAt: new Date(Date.now() + 100_000),
      });
      usersService.findById.mockResolvedValue({
        id: 'user-1',
        email: 'ada@example.com',
        status: 'ACTIVE',
      });
      // ...but a concurrent request already committed the rotation by the
      // time this transaction's guarded update runs.
      tx.refreshToken.updateMany.mockResolvedValue({ count: 0 });

      await expect(authService.refresh('token-id.secret')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );

      // The transaction must never create a replacement token for the loser.
      expect(tx.refreshToken.create).not.toHaveBeenCalled();
      // And the loss is treated exactly like reuse: whole family revoked.
      expect(prisma.refreshToken.updateMany).toHaveBeenCalledWith({
        where: { familyId: 'family-1', revokedAt: null },
        data: { revokedAt: expect.any(Date), reusedAt: expect.any(Date) },
      });
      expect(auditService.record).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'auth.refresh_token_reuse_detected' }),
      );
    });
  });

  describe('forgotPassword', () => {
    it('resolves silently and sends no email when the address has no account', async () => {
      usersService.findByEmail.mockResolvedValue(null);

      await authService.forgotPassword({ email: 'nobody@example.com' });

      expect(emailService.sendPasswordResetEmail).not.toHaveBeenCalled();
      expect(prisma.passwordResetToken.create).not.toHaveBeenCalled();
    });

    it('invalidates any prior outstanding token and sends a new one for a real account', async () => {
      usersService.findByEmail.mockResolvedValue({
        id: 'user-1',
        email: 'ada@example.com',
        status: 'ACTIVE',
      });

      await authService.forgotPassword({ email: 'Ada@Example.com' });

      expect(prisma.passwordResetToken.updateMany).toHaveBeenCalledWith({
        where: { userId: 'user-1', usedAt: null },
        data: { usedAt: expect.any(Date) },
      });
      expect(prisma.passwordResetToken.create).toHaveBeenCalledTimes(1);
      expect(emailService.sendPasswordResetEmail).toHaveBeenCalledWith(
        'ada@example.com',
        expect.stringContaining('reset-token-id.'),
      );
      expect(auditService.record).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'auth.password_reset_requested' }),
      );
    });
  });

  describe('resetPassword', () => {
    it('rejects mismatched new passwords before touching the database', async () => {
      await expect(
        authService.resetPassword({
          token: 'id.secret',
          newPassword: 'NewPass1!',
          confirmNewPassword: 'Different1!',
        }),
      ).rejects.toBeInstanceOf(ConflictException);
      expect(prisma.passwordResetToken.findUnique).not.toHaveBeenCalled();
    });

    it('rejects an unknown, expired, or already-used token', async () => {
      prisma.passwordResetToken.findUnique.mockResolvedValue(null);

      await expect(
        authService.resetPassword({
          token: 'missing-id.secret',
          newPassword: 'NewPass1!',
          confirmNewPassword: 'NewPass1!',
        }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('rejects a token whose secret does not match the stored hash', async () => {
      prisma.passwordResetToken.findUnique.mockResolvedValue({
        id: 'reset-token-id',
        userId: 'user-1',
        tokenHash: await argon2.hash('correct-secret'),
        usedAt: null,
        expiresAt: new Date(Date.now() + 100_000),
      });

      await expect(
        authService.resetPassword({
          token: 'reset-token-id.wrong-secret',
          newPassword: 'NewPass1!',
          confirmNewPassword: 'NewPass1!',
        }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('marks the token used, updates the password hash, and signs out every session', async () => {
      prisma.passwordResetToken.findUnique.mockResolvedValue({
        id: 'reset-token-id',
        userId: 'user-1',
        tokenHash: await argon2.hash('secret'),
        usedAt: null,
        expiresAt: new Date(Date.now() + 100_000),
      });
      prisma.refreshToken.updateMany.mockResolvedValue({ count: 2 });

      await authService.resetPassword({
        token: 'reset-token-id.secret',
        newPassword: 'NewPass1!',
        confirmNewPassword: 'NewPass1!',
      });

      expect(prisma.$transaction).toHaveBeenCalledTimes(1);
      const updateArgs = prisma.user.update.mock.calls[0][0];
      expect(updateArgs.where).toEqual({ id: 'user-1' });
      expect(updateArgs.data.passwordHash).not.toBe('NewPass1!');
      expect(auditService.record).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'auth.password_reset_completed' }),
      );
      // Resetting a password ends every other session.
      expect(prisma.refreshToken.updateMany).toHaveBeenCalledWith({
        where: { userId: 'user-1', revokedAt: null },
        data: { revokedAt: expect.any(Date) },
      });
    });
  });

  describe('changePassword', () => {
    it('rejects mismatched new passwords', async () => {
      await expect(
        authService.changePassword('user-1', {
          currentPassword: 'Current1!',
          newPassword: 'NewPass1!',
          confirmNewPassword: 'Different1!',
        }),
      ).rejects.toBeInstanceOf(ConflictException);
    });

    it('rejects an incorrect current password', async () => {
      usersService.findById.mockResolvedValue({
        id: 'user-1',
        status: 'ACTIVE',
        passwordHash: await argon2.hash('actual-current'),
      });

      await expect(
        authService.changePassword('user-1', {
          currentPassword: 'wrong-current',
          newPassword: 'NewPass1!',
          confirmNewPassword: 'NewPass1!',
        }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
      expect(prisma.user.update).not.toHaveBeenCalled();
    });

    it('updates the password hash when the current password is correct', async () => {
      usersService.findById.mockResolvedValue({
        id: 'user-1',
        status: 'ACTIVE',
        passwordHash: await argon2.hash('actual-current'),
      });

      await authService.changePassword('user-1', {
        currentPassword: 'actual-current',
        newPassword: 'NewPass1!',
        confirmNewPassword: 'NewPass1!',
      });

      expect(prisma.user.update).toHaveBeenCalledTimes(1);
      expect(auditService.record).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'auth.password_changed' }),
      );
    });
  });

  describe('verifyEmail', () => {
    it('rejects an unknown, expired, or already-used token', async () => {
      prisma.emailVerificationToken.findUnique.mockResolvedValue(null);

      await expect(authService.verifyEmail({ token: 'missing-id.secret' })).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    });

    it('marks emailVerifiedAt on a valid token', async () => {
      prisma.emailVerificationToken.findUnique.mockResolvedValue({
        id: 'verify-token-id',
        userId: 'user-1',
        tokenHash: await argon2.hash('secret'),
        usedAt: null,
        expiresAt: new Date(Date.now() + 100_000),
      });

      await authService.verifyEmail({ token: 'verify-token-id.secret' });

      const updateArgs = prisma.user.update.mock.calls[0][0];
      expect(updateArgs.where).toEqual({ id: 'user-1' });
      expect(updateArgs.data.emailVerifiedAt).toBeInstanceOf(Date);
      expect(auditService.record).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'auth.email_verified' }),
      );
    });
  });

  describe('resendVerification', () => {
    it('does nothing for an already-verified account', async () => {
      usersService.findById.mockResolvedValue({
        id: 'user-1',
        status: 'ACTIVE',
        email: 'ada@example.com',
        emailVerifiedAt: new Date(),
      });

      await authService.resendVerification('user-1');

      expect(emailService.sendVerificationEmail).not.toHaveBeenCalled();
    });

    it('issues and sends a fresh verification token for an unverified account', async () => {
      usersService.findById.mockResolvedValue({
        id: 'user-1',
        status: 'ACTIVE',
        email: 'ada@example.com',
        emailVerifiedAt: null,
      });

      await authService.resendVerification('user-1');

      expect(emailService.sendVerificationEmail).toHaveBeenCalledWith(
        'ada@example.com',
        expect.stringContaining('verify-token-id.'),
      );
      expect(auditService.record).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'auth.verification_email_resent' }),
      );
    });
  });

  describe('deleteAccount', () => {
    it('rejects an incorrect password without touching the database', async () => {
      usersService.findById.mockResolvedValue({
        id: 'user-1',
        status: 'ACTIVE',
        email: 'ada@example.com',
        passwordHash: await argon2.hash('actual-current'),
      });

      await expect(authService.deleteAccount('user-1', 'wrong-password')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
      expect(prisma.$transaction).not.toHaveBeenCalled();
    });

    it('revokes every session and anonymizes the email on success', async () => {
      usersService.findById.mockResolvedValue({
        id: 'user-1',
        status: 'ACTIVE',
        email: 'ada@example.com',
        passwordHash: await argon2.hash('actual-current'),
      });

      await authService.deleteAccount('user-1', 'actual-current');

      expect(prisma.$transaction).toHaveBeenCalledTimes(1);
      expect(prisma.refreshToken.updateMany).toHaveBeenCalledWith({
        where: { userId: 'user-1', revokedAt: null },
        data: { revokedAt: expect.any(Date) },
      });
      const updateArgs = prisma.user.update.mock.calls[0][0];
      expect(updateArgs.where).toEqual({ id: 'user-1' });
      expect(updateArgs.data.status).toBe('DELETED');
      expect(updateArgs.data.email).toContain('@deleted.projectascend.invalid');
      expect(updateArgs.data.email).not.toBe('ada@example.com');
      expect(auditService.record).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'auth.account_deleted' }),
      );
    });
  });

  describe('signInWithGoogle', () => {
    it('signs in the existing user when the identity is already linked', async () => {
      googleTokenVerifier.verify.mockResolvedValue({
        subject: 'google-sub-1',
        email: 'ada@example.com',
        emailVerified: true,
      });
      authIdentitiesService.findByProviderSubject.mockResolvedValue({
        id: 'identity-1',
        userId: 'user-1',
      });
      usersService.findById.mockResolvedValue({
        id: 'user-1',
        email: 'ada@example.com',
        role: 'MEMBER',
        status: 'ACTIVE',
        emailVerifiedAt: new Date(),
      });

      const result = await authService.signInWithGoogle({ idToken: 'raw-token' });

      expect(prisma.user.create).not.toHaveBeenCalled();
      expect(authIdentitiesService.linkIdentity).toHaveBeenCalledWith(
        'user-1',
        'GOOGLE',
        'google-sub-1',
        'ada@example.com',
      );
      expect(result.user.id).toBe('user-1');
      expect(result.tokens.accessToken).toBe('signed.jwt');
    });

    it('rejects when the linked identity belongs to a no-longer-active user', async () => {
      googleTokenVerifier.verify.mockResolvedValue({
        subject: 'google-sub-1',
        email: 'ada@example.com',
        emailVerified: true,
      });
      authIdentitiesService.findByProviderSubject.mockResolvedValue({
        id: 'identity-1',
        userId: 'user-1',
      });
      usersService.findById.mockResolvedValue({ id: 'user-1', status: 'SUSPENDED' });

      await expect(authService.signInWithGoogle({ idToken: 'raw-token' })).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    });

    it('creates a brand-new account when no identity or email match exists', async () => {
      googleTokenVerifier.verify.mockResolvedValue({
        subject: 'google-sub-2',
        email: 'new-google-user@example.com',
        emailVerified: true,
        firstName: 'Nova',
      });
      usersService.findByEmail.mockResolvedValue(null);
      prisma.user.create.mockResolvedValue({
        id: 'new-user',
        email: 'new-google-user@example.com',
        role: 'MEMBER',
        emailVerifiedAt: new Date(),
      });

      const result = await authService.signInWithGoogle({ idToken: 'raw-token' });

      const createArgs = prisma.user.create.mock.calls[0][0];
      expect(createArgs.data.email).toBe('new-google-user@example.com');
      expect(createArgs.data.profile.create.firstName).toBe('Nova');
      expect(authIdentitiesService.linkIdentity).toHaveBeenCalledWith(
        'new-user',
        'GOOGLE',
        'google-sub-2',
        'new-google-user@example.com',
      );
      expect(result.user.id).toBe('new-user');
    });

    it('auto-links to an existing account when the provider vouches the email is verified', async () => {
      googleTokenVerifier.verify.mockResolvedValue({
        subject: 'google-sub-3',
        email: 'existing@example.com',
        emailVerified: true,
      });
      usersService.findByEmail.mockResolvedValue({
        id: 'existing-user',
        email: 'existing@example.com',
        role: 'MEMBER',
        status: 'ACTIVE',
        emailVerifiedAt: null,
      });

      const result = await authService.signInWithGoogle({ idToken: 'raw-token' });

      expect(prisma.user.create).not.toHaveBeenCalled();
      expect(authIdentitiesService.linkIdentity).toHaveBeenCalledWith(
        'existing-user',
        'GOOGLE',
        'google-sub-3',
        'existing@example.com',
      );
      expect(result.user.id).toBe('existing-user');
    });

    it('refuses to auto-link when the provider does not vouch the email is verified', async () => {
      googleTokenVerifier.verify.mockResolvedValue({
        subject: 'google-sub-4',
        email: 'existing@example.com',
        emailVerified: false,
      });
      usersService.findByEmail.mockResolvedValue({
        id: 'existing-user',
        email: 'existing@example.com',
        role: 'MEMBER',
        status: 'ACTIVE',
      });

      await expect(authService.signInWithGoogle({ idToken: 'raw-token' })).rejects.toBeInstanceOf(
        ConflictException,
      );
      expect(authIdentitiesService.linkIdentity).not.toHaveBeenCalled();
    });
  });

  describe('signInWithApple', () => {
    it('forwards the client-supplied firstName since Apple never puts it in the ID token', async () => {
      appleTokenVerifier.verify.mockResolvedValue({
        subject: 'apple-sub-1',
        email: 'new-apple-user@example.com',
        emailVerified: true,
      });
      usersService.findByEmail.mockResolvedValue(null);
      prisma.user.create.mockResolvedValue({
        id: 'new-apple-account',
        email: 'new-apple-user@example.com',
        role: 'MEMBER',
        emailVerifiedAt: new Date(),
      });

      await authService.signInWithApple({ idToken: 'raw-token', firstName: 'Atlas' });

      const createArgs = prisma.user.create.mock.calls[0][0];
      expect(createArgs.data.profile.create.firstName).toBe('Atlas');
    });
  });

  describe('logoutAll', () => {
    it('revokes every active token for the user and records an audit event distinct from reuse handling', async () => {
      prisma.refreshToken.updateMany.mockResolvedValue({ count: 3 });

      await authService.logoutAll('user-1');

      expect(prisma.refreshToken.updateMany).toHaveBeenCalledWith({
        where: { userId: 'user-1', revokedAt: null },
        data: { revokedAt: expect.any(Date) },
      });
      expect(auditService.record).toHaveBeenCalledWith(
        expect.objectContaining({ userId: 'user-1', action: 'auth.logout_all' }),
      );
    });
  });

  describe('listSessions', () => {
    it('maps active tokens to session summaries and marks the caller current by familyId', async () => {
      const sessionCreatedAt = new Date('2026-08-01T00:00:00Z');
      const lastRotatedAt = new Date('2026-08-05T00:00:00Z');
      prisma.refreshToken.findMany.mockResolvedValue([
        {
          familyId: 'family-current',
          deviceName: 'iPhone',
          platform: 'ios',
          sessionCreatedAt,
          createdAt: lastRotatedAt,
        },
        {
          familyId: 'family-other',
          deviceName: 'Pixel',
          platform: 'android',
          sessionCreatedAt,
          createdAt: lastRotatedAt,
        },
      ]);

      const sessions = await authService.listSessions('user-1', 'family-current');

      expect(prisma.refreshToken.findMany).toHaveBeenCalledWith({
        where: { userId: 'user-1', revokedAt: null, expiresAt: { gt: expect.any(Date) } },
        orderBy: { sessionCreatedAt: 'desc' },
      });
      expect(sessions).toEqual([
        {
          id: 'family-current',
          deviceName: 'iPhone',
          platform: 'ios',
          createdAt: sessionCreatedAt,
          lastUsedAt: lastRotatedAt,
          current: true,
        },
        {
          id: 'family-other',
          deviceName: 'Pixel',
          platform: 'android',
          createdAt: sessionCreatedAt,
          lastUsedAt: lastRotatedAt,
          current: false,
        },
      ]);
    });

    it('marks nothing current when the caller has no familyId (pre-Part-11 access token)', async () => {
      prisma.refreshToken.findMany.mockResolvedValue([
        {
          familyId: 'family-a',
          deviceName: null,
          platform: null,
          sessionCreatedAt: new Date(),
          createdAt: new Date(),
        },
      ]);

      const sessions = await authService.listSessions('user-1', undefined);

      expect(sessions[0].current).toBe(false);
    });
  });

  describe('revokeSession', () => {
    it('revokes the matching family and records an audit event', async () => {
      prisma.refreshToken.updateMany.mockResolvedValue({ count: 1 });

      await authService.revokeSession('user-1', 'family-other');

      expect(prisma.refreshToken.updateMany).toHaveBeenCalledWith({
        where: {
          userId: 'user-1',
          familyId: 'family-other',
          revokedAt: null,
          expiresAt: { gt: expect.any(Date) },
        },
        data: { revokedAt: expect.any(Date) },
      });
      expect(auditService.record).toHaveBeenCalledWith(
        expect.objectContaining({ userId: 'user-1', action: 'auth.session_revoked' }),
      );
    });

    it('throws NotFoundException when no active session matches', async () => {
      prisma.refreshToken.updateMany.mockResolvedValue({ count: 0 });

      await expect(authService.revokeSession('user-1', 'no-such-family')).rejects.toThrow(
        'Session not found.',
      );
    });
  });

  describe('revokeOtherSessions', () => {
    it('revokes every session except the caller current family and returns the count', async () => {
      prisma.refreshToken.updateMany.mockResolvedValue({ count: 2 });

      const revokedCount = await authService.revokeOtherSessions('user-1', 'family-current');

      expect(revokedCount).toBe(2);
      expect(prisma.refreshToken.updateMany).toHaveBeenCalledWith({
        where: {
          userId: 'user-1',
          revokedAt: null,
          expiresAt: { gt: expect.any(Date) },
          familyId: { not: 'family-current' },
        },
        data: { revokedAt: expect.any(Date) },
      });
      expect(auditService.record).toHaveBeenCalledWith(
        expect.objectContaining({ userId: 'user-1', action: 'auth.other_sessions_revoked' }),
      );
    });

    it('rejects when the caller familyId is unknown, without touching the database', async () => {
      await expect(authService.revokeOtherSessions('user-1', undefined)).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
      expect(prisma.refreshToken.updateMany).not.toHaveBeenCalled();
    });
  });
});
