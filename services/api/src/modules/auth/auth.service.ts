import * as crypto from 'crypto';
import { ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { RefreshToken } from '@prisma/client';
import * as argon2 from 'argon2';
import { AuditService } from '../../common/audit/audit.service';
import { AppConfig } from '../../config/configuration';
import { PrismaService } from '../../prisma/prisma.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { AuthenticatedUser, JwtPayload, TokenPair } from './types/jwt-payload.type';

const REFRESH_SECRET_BYTES = 32;

/**
 * Thrown internally when a rotation transaction loses the race to revoke a
 * refresh token (it was already revoked — either by history, or by a
 * concurrent request that beat this one to it). Never escapes AuthService;
 * it exists only to unwind the `$transaction` callback so Prisma rolls
 * back the (not-yet-committed) replacement token, then triggers reuse
 * handling once outside the transaction.
 */
class RefreshTokenReuseError extends Error {
  constructor(readonly stored: RefreshToken) {
    super('Refresh token reuse detected.');
  }
}

@Injectable()
export class AuthService {
  private readonly jwtConfig: AppConfig['jwt'];

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly auditService: AuditService,
  ) {
    this.jwtConfig = this.configService.get<AppConfig>('app')!.jwt;
  }

  async register(dto: RegisterDto): Promise<{ user: AuthenticatedUser; tokens: TokenPair }> {
    if (dto.password !== dto.confirmPassword) {
      throw new ConflictException('Passwords do not match.');
    }
    if (!dto.acceptedTerms) {
      throw new ConflictException('You must accept the terms to continue.');
    }

    const normalizedEmail = dto.email.trim().toLowerCase();
    const existing = await this.prisma.user.findUnique({ where: { email: normalizedEmail } });
    if (existing) {
      throw new ConflictException('An account with this email already exists.');
    }

    const passwordHash = await argon2.hash(dto.password);

    const user = await this.prisma.user.create({
      data: {
        email: normalizedEmail,
        passwordHash,
        profile: {
          create: {
            firstName: dto.firstName.trim(),
          },
        },
        preference: {
          create: {},
        },
      },
    });

    await this.auditService.record({
      userId: user.id,
      action: 'auth.register',
      entityType: 'User',
      entityId: user.id,
    });

    const tokens = await this.issueTokenPair(user.id, user.email);
    return { user: { id: user.id, email: user.email }, tokens };
  }

  async login(dto: LoginDto): Promise<{ user: AuthenticatedUser; tokens: TokenPair }> {
    const normalizedEmail = dto.email.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({ where: { email: normalizedEmail } });

    if (!user || user.status !== 'ACTIVE') {
      throw new UnauthorizedException('Invalid email or password.');
    }

    const passwordValid = await argon2.verify(user.passwordHash, dto.password);
    if (!passwordValid) {
      throw new UnauthorizedException('Invalid email or password.');
    }

    await this.auditService.record({
      userId: user.id,
      action: 'auth.login',
      entityType: 'User',
      entityId: user.id,
    });

    const tokens = await this.issueTokenPair(user.id, user.email, dto.deviceName);
    return { user: { id: user.id, email: user.email }, tokens };
  }

  async refresh(refreshToken: string): Promise<TokenPair> {
    const { tokenId, secret } = this.parseRefreshToken(refreshToken);

    const stored = await this.prisma.refreshToken.findUnique({ where: { id: tokenId } });
    if (!stored || stored.expiresAt < new Date()) {
      throw new UnauthorizedException('Refresh token is invalid or expired.');
    }

    const secretValid = await argon2.verify(stored.tokenHash, secret);
    if (!secretValid) {
      throw new UnauthorizedException('Refresh token is invalid or expired.');
    }

    if (stored.revokedAt) {
      // The presented token was already rotated out (or revoked). Reusing a
      // dead token like this is exactly the signature of a stolen refresh
      // token being replayed, so treat the whole session lineage as
      // compromised rather than just rejecting this one request.
      await this.handleRefreshTokenReuse(stored);
      throw new UnauthorizedException('Refresh token is invalid or expired.');
    }

    const user = await this.prisma.user.findUnique({ where: { id: stored.userId } });
    if (!user || user.status !== 'ACTIVE') {
      throw new UnauthorizedException('Refresh token is invalid or expired.');
    }

    const newSecret = crypto.randomBytes(REFRESH_SECRET_BYTES).toString('hex');
    const newTokenHash = await argon2.hash(newSecret);
    const expiresAt = new Date(Date.now() + this.parseDurationMs(this.jwtConfig.refreshTtl));

    let newTokenId: string;
    try {
      // Revocation and replacement-creation happen in one transaction so a
      // client can never observe (or make use of) a moment where both the
      // old and new tokens are simultaneously valid. The `revokedAt: null`
      // guard on the update turns this into an atomic compare-and-swap:
      // under Postgres's default READ COMMITTED isolation, a concurrent
      // request racing to rotate this same token will block on the row
      // lock, then re-check the guard and affect zero rows once this
      // transaction commits — which is exactly the reuse case handled below.
      newTokenId = await this.prisma.$transaction(async (tx) => {
        const revoked = await tx.refreshToken.updateMany({
          where: { id: stored.id, revokedAt: null },
          data: { revokedAt: new Date() },
        });

        if (revoked.count === 0) {
          throw new RefreshTokenReuseError(stored);
        }

        const created = await tx.refreshToken.create({
          data: {
            userId: stored.userId,
            familyId: stored.familyId,
            tokenHash: newTokenHash,
            expiresAt,
            deviceName: stored.deviceName,
          },
        });

        return created.id;
      });
    } catch (error) {
      if (error instanceof RefreshTokenReuseError) {
        await this.handleRefreshTokenReuse(error.stored);
        throw new UnauthorizedException('Refresh token is invalid or expired.');
      }
      throw error;
    }

    const accessToken = await this.jwtService.signAsync(
      { sub: user.id, email: user.email } satisfies JwtPayload,
      { secret: this.jwtConfig.accessSecret, expiresIn: this.jwtConfig.accessTtl },
    );

    return {
      accessToken,
      refreshToken: `${newTokenId}.${newSecret}`,
      tokenType: 'Bearer',
      expiresIn: this.jwtConfig.accessTtl,
    };
  }

  async logout(refreshToken: string): Promise<void> {
    const { tokenId } = this.parseRefreshToken(refreshToken);

    await this.prisma.refreshToken.updateMany({
      where: { id: tokenId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  async me(userId: string): Promise<AuthenticatedUser> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new UnauthorizedException('Session is no longer valid.');
    }
    return { id: user.id, email: user.email };
  }

  /**
   * Revokes every still-active token in the reused token's family and
   * records an audit event. Deliberately does not surface *why* to the
   * caller beyond the generic "invalid or expired" message `refresh()`
   * throws — the security reason (possible theft) stays server-side.
   */
  private async handleRefreshTokenReuse(stored: RefreshToken): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { familyId: stored.familyId, revokedAt: null },
      data: { revokedAt: new Date() },
    });

    await this.auditService.record({
      userId: stored.userId,
      action: 'auth.refresh_token_reuse_detected',
      entityType: 'RefreshToken',
      entityId: stored.id,
      metadata: { familyId: stored.familyId },
    });
  }

  private async issueTokenPair(
    userId: string,
    email: string,
    deviceName?: string,
  ): Promise<TokenPair> {
    const payload: JwtPayload = { sub: userId, email };
    const accessToken = await this.jwtService.signAsync(payload, {
      secret: this.jwtConfig.accessSecret,
      expiresIn: this.jwtConfig.accessTtl,
    });

    const secret = crypto.randomBytes(REFRESH_SECRET_BYTES).toString('hex');
    const tokenHash = await argon2.hash(secret);
    const expiresAt = new Date(Date.now() + this.parseDurationMs(this.jwtConfig.refreshTtl));

    const refreshRecord = await this.prisma.refreshToken.create({
      data: {
        userId,
        familyId: crypto.randomUUID(),
        tokenHash,
        expiresAt,
        deviceName,
      },
    });

    return {
      accessToken,
      refreshToken: `${refreshRecord.id}.${secret}`,
      tokenType: 'Bearer',
      expiresIn: this.jwtConfig.accessTtl,
    };
  }

  private parseRefreshToken(raw: string): { tokenId: string; secret: string } {
    const separatorIndex = raw.indexOf('.');
    if (separatorIndex <= 0 || separatorIndex === raw.length - 1) {
      throw new UnauthorizedException('Refresh token is invalid or expired.');
    }

    return {
      tokenId: raw.slice(0, separatorIndex),
      secret: raw.slice(separatorIndex + 1),
    };
  }

  private parseDurationMs(duration: string): number {
    const match = /^(\d+)(ms|s|m|h|d)$/.exec(duration.trim());
    if (!match) {
      throw new Error(`Unsupported duration format: ${duration}`);
    }
    const value = Number(match[1]);
    const unit = match[2];
    const unitMs: Record<string, number> = {
      ms: 1,
      s: 1000,
      m: 60_000,
      h: 3_600_000,
      d: 86_400_000,
    };
    return value * unitMs[unit];
  }
}
