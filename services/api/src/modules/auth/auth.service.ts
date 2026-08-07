import * as crypto from 'crypto';
import { ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { RefreshToken } from '@prisma/client';
import * as argon2 from 'argon2';
import { AuditService } from '../../common/audit/audit.service';
import { AppConfig } from '../../config/configuration';
import { PrismaService } from '../../prisma/prisma.service';
import { EmailService } from '../email/email.service';
import { UsersService } from '../users/users.service';
import { ChangePasswordDto } from './dto/change-password.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { VerifyEmailDto } from './dto/verify-email.dto';
import { AuthenticatedUser, JwtPayload, TokenPair } from './types/jwt-payload.type';

const REFRESH_SECRET_BYTES = 32;
const RESET_SECRET_BYTES = 32;
const PASSWORD_RESET_TTL_MS = 60 * 60 * 1000; // 1 hour
const EMAIL_VERIFICATION_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours

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
    private readonly usersService: UsersService,
    private readonly emailService: EmailService,
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
    const existing = await this.usersService.findByEmail(normalizedEmail);
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

    // Best-effort — a failed/unconfigured email provider must never block
    // account creation. The user can always request a fresh verification
    // email later via resendVerification().
    await this.issueAndSendVerificationEmail(user.id, user.email).catch(() => undefined);

    const tokens = await this.issueTokenPair(user.id, user.email);
    return {
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        emailVerifiedAt: user.emailVerifiedAt,
      },
      tokens,
    };
  }

  async login(dto: LoginDto): Promise<{ user: AuthenticatedUser; tokens: TokenPair }> {
    const normalizedEmail = dto.email.trim().toLowerCase();
    const user = await this.usersService.findByEmail(normalizedEmail);

    if (!this.usersService.isActive(user)) {
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
    return {
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        emailVerifiedAt: user.emailVerifiedAt,
      },
      tokens,
    };
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

    const user = await this.usersService.findById(stored.userId);
    if (!this.usersService.isActive(user)) {
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

  /**
   * Revokes every active refresh token across every family for this user —
   * "sign out everywhere". Unlike reuse handling, this is a deliberate
   * user action, not theft detection, so it doesn't record a
   * `reusedAt`/reuse audit event, just an ordinary revoke plus its own
   * audit trail entry.
   */
  async logoutAll(userId: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });

    await this.auditService.record({
      userId,
      action: 'auth.logout_all',
      entityType: 'User',
      entityId: userId,
    });
  }

  async me(userId: string): Promise<AuthenticatedUser> {
    const user = await this.usersService.findById(userId);
    if (!this.usersService.isActive(user)) {
      throw new UnauthorizedException('Session is no longer valid.');
    }
    return {
      id: user.id,
      email: user.email,
      role: user.role,
      emailVerifiedAt: user.emailVerifiedAt,
    };
  }

  /**
   * Always resolves the same way regardless of whether the email belongs
   * to an account — the same no-enumeration philosophy as login()'s
   * collapsed "invalid email or password" message. Only internally
   * branches on whether to actually generate and send a token.
   */
  async forgotPassword(dto: ForgotPasswordDto): Promise<void> {
    const normalizedEmail = dto.email.trim().toLowerCase();
    const user = await this.usersService.findByEmail(normalizedEmail);
    if (!user || !this.usersService.isActive(user)) {
      return;
    }

    // Invalidate any prior outstanding reset token for this user before
    // issuing a new one — the same compare-and-swap-flavored "only one
    // live token at a time" spirit as refresh-token rotation.
    await this.prisma.passwordResetToken.updateMany({
      where: { userId: user.id, usedAt: null },
      data: { usedAt: new Date() },
    });

    const secret = crypto.randomBytes(RESET_SECRET_BYTES).toString('hex');
    const tokenHash = await argon2.hash(secret);
    const record = await this.prisma.passwordResetToken.create({
      data: {
        userId: user.id,
        tokenHash,
        expiresAt: new Date(Date.now() + PASSWORD_RESET_TTL_MS),
      },
    });

    await this.auditService.record({
      userId: user.id,
      action: 'auth.password_reset_requested',
      entityType: 'User',
      entityId: user.id,
    });

    await this.emailService.sendPasswordResetEmail(user.email, `${record.id}.${secret}`);
  }

  async resetPassword(dto: ResetPasswordDto): Promise<void> {
    if (dto.newPassword !== dto.confirmNewPassword) {
      throw new ConflictException('Passwords do not match.');
    }

    const parsed = this.splitCompositeToken(dto.token);
    if (!parsed) {
      throw new UnauthorizedException('This reset link is invalid or has expired.');
    }

    const stored = await this.prisma.passwordResetToken.findUnique({ where: { id: parsed.id } });
    if (!stored || stored.usedAt || stored.expiresAt < new Date()) {
      throw new UnauthorizedException('This reset link is invalid or has expired.');
    }

    const secretValid = await argon2.verify(stored.tokenHash, parsed.secret);
    if (!secretValid) {
      throw new UnauthorizedException('This reset link is invalid or has expired.');
    }

    const passwordHash = await argon2.hash(dto.newPassword);

    await this.prisma.$transaction([
      this.prisma.passwordResetToken.update({
        where: { id: stored.id },
        data: { usedAt: new Date() },
      }),
      this.prisma.user.update({
        where: { id: stored.userId },
        data: { passwordHash },
      }),
    ]);

    await this.auditService.record({
      userId: stored.userId,
      action: 'auth.password_reset_completed',
      entityType: 'User',
      entityId: stored.userId,
    });

    // A password reset should end every other session — the same
    // "sign out everywhere" logoutAll() used for the explicit user action.
    await this.logoutAll(stored.userId);
  }

  async changePassword(userId: string, dto: ChangePasswordDto): Promise<void> {
    if (dto.newPassword !== dto.confirmNewPassword) {
      throw new ConflictException('Passwords do not match.');
    }

    const user = await this.usersService.findById(userId);
    if (!this.usersService.isActive(user)) {
      throw new UnauthorizedException('Session is no longer valid.');
    }

    const currentValid = await argon2.verify(user.passwordHash, dto.currentPassword);
    if (!currentValid) {
      throw new UnauthorizedException('Current password is incorrect.');
    }

    const passwordHash = await argon2.hash(dto.newPassword);
    await this.prisma.user.update({ where: { id: userId }, data: { passwordHash } });

    await this.auditService.record({
      userId,
      action: 'auth.password_changed',
      entityType: 'User',
      entityId: userId,
    });
  }

  /**
   * Closes the account: requires the current password (the same
   * confirmation bar as changePassword), revokes every session, and
   * anonymizes the unique email so it can be reused by a future
   * registration. This is a soft delete — status flips to DELETED,
   * which every existing isActive() check already treats as
   * unauthenticated (login/refresh/me all reject it) — not an immediate
   * cascading purge of the user's other data. A scheduled hard-delete
   * job is out of scope for this pass; see build-session-9.md.
   */
  async deleteAccount(userId: string, password: string): Promise<void> {
    const user = await this.usersService.findById(userId);
    if (!this.usersService.isActive(user)) {
      throw new UnauthorizedException('Session is no longer valid.');
    }

    const passwordValid = await argon2.verify(user.passwordHash, password);
    if (!passwordValid) {
      throw new UnauthorizedException('Current password is incorrect.');
    }

    const anonymizedEmail = `deleted-${crypto.randomUUID()}@deleted.projectascend.invalid`;

    await this.prisma.$transaction([
      this.prisma.refreshToken.updateMany({
        where: { userId, revokedAt: null },
        data: { revokedAt: new Date() },
      }),
      this.prisma.user.update({
        where: { id: userId },
        data: { status: 'DELETED', email: anonymizedEmail },
      }),
    ]);

    await this.auditService.record({
      userId,
      action: 'auth.account_deleted',
      entityType: 'User',
      entityId: userId,
    });
  }

  async verifyEmail(dto: VerifyEmailDto): Promise<void> {
    const parsed = this.splitCompositeToken(dto.token);
    if (!parsed) {
      throw new UnauthorizedException('This verification link is invalid or has expired.');
    }

    const stored = await this.prisma.emailVerificationToken.findUnique({
      where: { id: parsed.id },
    });
    if (!stored || stored.usedAt || stored.expiresAt < new Date()) {
      throw new UnauthorizedException('This verification link is invalid or has expired.');
    }

    const secretValid = await argon2.verify(stored.tokenHash, parsed.secret);
    if (!secretValid) {
      throw new UnauthorizedException('This verification link is invalid or has expired.');
    }

    await this.prisma.$transaction([
      this.prisma.emailVerificationToken.update({
        where: { id: stored.id },
        data: { usedAt: new Date() },
      }),
      this.prisma.user.update({
        where: { id: stored.userId },
        data: { emailVerifiedAt: new Date() },
      }),
    ]);

    await this.auditService.record({
      userId: stored.userId,
      action: 'auth.email_verified',
      entityType: 'User',
      entityId: stored.userId,
    });
  }

  async resendVerification(userId: string): Promise<void> {
    const user = await this.usersService.findById(userId);
    if (!this.usersService.isActive(user) || user.emailVerifiedAt) {
      return;
    }

    await this.issueAndSendVerificationEmail(user.id, user.email);

    await this.auditService.record({
      userId,
      action: 'auth.verification_email_resent',
      entityType: 'User',
      entityId: userId,
    });
  }

  private async issueAndSendVerificationEmail(userId: string, email: string): Promise<void> {
    await this.prisma.emailVerificationToken.updateMany({
      where: { userId, usedAt: null },
      data: { usedAt: new Date() },
    });

    const secret = crypto.randomBytes(RESET_SECRET_BYTES).toString('hex');
    const tokenHash = await argon2.hash(secret);
    const record = await this.prisma.emailVerificationToken.create({
      data: {
        userId,
        tokenHash,
        expiresAt: new Date(Date.now() + EMAIL_VERIFICATION_TTL_MS),
      },
    });

    await this.emailService.sendVerificationEmail(email, `${record.id}.${secret}`);
  }

  /** Same composite `id.secret` shape as refresh tokens, but returns null
   * on malformed input instead of throwing — callers of reset/verification
   * flows all collapse this into their own generic "invalid or expired"
   * message rather than a parsing-specific one. */
  private splitCompositeToken(raw: string): { id: string; secret: string } | null {
    const separatorIndex = raw.indexOf('.');
    if (separatorIndex <= 0 || separatorIndex === raw.length - 1) {
      return null;
    }
    return { id: raw.slice(0, separatorIndex), secret: raw.slice(separatorIndex + 1) };
  }

  /**
   * Revokes every still-active token in the reused token's family and
   * records an audit event. Deliberately does not surface *why* to the
   * caller beyond the generic "invalid or expired" message `refresh()`
   * throws — the security reason (possible theft) stays server-side.
   */
  private async handleRefreshTokenReuse(stored: RefreshToken): Promise<void> {
    const now = new Date();
    await this.prisma.refreshToken.updateMany({
      where: { familyId: stored.familyId, revokedAt: null },
      data: { revokedAt: now, reusedAt: now },
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
