import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import * as argon2 from 'argon2';
import { AuditService } from '../../common/audit/audit.service';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthService } from './auth.service';

describe('AuthService', () => {
  let authService: AuthService;
  let auditService: { record: jest.Mock };
  let tx: { refreshToken: { updateMany: jest.Mock; create: jest.Mock } };
  let prisma: {
    user: { findUnique: jest.Mock; create: jest.Mock };
    refreshToken: { findUnique: jest.Mock; create: jest.Mock; updateMany: jest.Mock };
    $transaction: jest.Mock;
  };

  beforeEach(async () => {
    tx = {
      refreshToken: { updateMany: jest.fn(), create: jest.fn() },
    };
    prisma = {
      user: { findUnique: jest.fn(), create: jest.fn() },
      refreshToken: { findUnique: jest.fn(), create: jest.fn(), updateMany: jest.fn() },
      $transaction: jest.fn(async (callback: (tx: unknown) => Promise<unknown>) => callback(tx)),
    };
    auditService = { record: jest.fn() };

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
      prisma.user.findUnique.mockResolvedValue({ id: 'existing-user' });

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
      prisma.user.findUnique.mockResolvedValue(null);
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
      prisma.user.findUnique.mockResolvedValue({
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
        data: { revokedAt: expect.any(Date) },
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
      prisma.user.findUnique.mockResolvedValue({
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
        data: { revokedAt: expect.any(Date) },
      });
      expect(auditService.record).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'auth.refresh_token_reuse_detected' }),
      );
    });
  });
});
