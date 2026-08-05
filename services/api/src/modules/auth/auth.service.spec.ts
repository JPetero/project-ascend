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
  let prisma: {
    user: { findUnique: jest.Mock; create: jest.Mock };
    refreshToken: { findUnique: jest.Mock; create: jest.Mock; update: jest.Mock };
  };

  beforeEach(async () => {
    prisma = {
      user: { findUnique: jest.fn(), create: jest.fn() },
      refreshToken: { findUnique: jest.fn(), create: jest.fn(), update: jest.fn() },
    };

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
        { provide: AuditService, useValue: { record: jest.fn() } },
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

    it('rejects a refresh token that has been revoked', async () => {
      prisma.refreshToken.findUnique.mockResolvedValue({
        id: 'token-id',
        tokenHash: await argon2.hash('secret'),
        revokedAt: new Date(),
        expiresAt: new Date(Date.now() + 100_000),
      });

      await expect(authService.refresh('token-id.secret')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    });

    it('rejects a refresh token whose secret does not match the stored hash', async () => {
      prisma.refreshToken.findUnique.mockResolvedValue({
        id: 'token-id',
        tokenHash: await argon2.hash('correct-secret'),
        revokedAt: null,
        expiresAt: new Date(Date.now() + 100_000),
      });

      await expect(authService.refresh('token-id.wrong-secret')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    });
  });
});
