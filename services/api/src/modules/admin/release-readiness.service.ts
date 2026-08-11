import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { existsSync, readdirSync, statSync } from 'fs';
import { join } from 'path';
import {
  AiConfig,
  AppConfig,
  EmailConfig,
  IapConfig,
  MediaConfig,
  PushConfig,
  ResearchConfig,
  SocialAuthConfig,
} from '../../config/configuration';
import { PrismaService } from '../../prisma/prisma.service';

// Same depth under src/ and dist/ (modules/admin, two levels below the
// package root), so this resolves correctly whether the service is
// running from ts-node in dev or compiled JS in production — see
// checkMigrations' doc comment for why this can't just shell out to
// `prisma migrate status` instead.
const MIGRATIONS_DIR = join(__dirname, '../../../prisma/migrations');

interface AppliedMigrationRow {
  migration_name: string;
}

/**
 * Build Session 12 Part 15-17 — read-only diagnostic for staff to check
 * "is this environment ready to run in production" without reading raw
 * env vars off a box. Reports only configured/not-configured booleans per
 * integration, never secret or key values — see FeatureFlag's neighbor
 * doc comments in this module for the same never-leak-secrets posture.
 * Mirrors the exact checks env.validation.ts already enforces at boot for
 * production, so staging/dev can see the same signal before promoting.
 *
 * S13 Part 16-27 (V2) added the `migrations` check below — the original
 * checks covered config/secrets/integrations but had no way to catch a
 * deploy that forgot to apply a migration, which would otherwise surface
 * later as an opaque "column does not exist" error on the first request
 * that touches it.
 */
@Injectable()
export class ReleaseReadinessService {
  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  async check() {
    const app = this.configService.get<AppConfig>('app')!;
    const media = this.configService.get<MediaConfig>('media')!;
    const email = this.configService.get<EmailConfig>('email')!;
    const socialAuth = this.configService.get<SocialAuthConfig>('socialAuth')!;
    const ai = this.configService.get<AiConfig>('ai')!;
    const research = this.configService.get<ResearchConfig>('research')!;
    const push = this.configService.get<PushConfig>('push')!;
    const iap = this.configService.get<IapConfig>('iap')!;

    const usingDevJwtSecrets =
      app.jwt.accessSecret.startsWith('dev_') || app.jwt.refreshSecret.startsWith('dev_');
    const corsWildcard = app.corsOrigin === '*';

    const [flagCount, enabledFlagCount, migrations] = await Promise.all([
      this.prisma.featureFlag.count(),
      this.prisma.featureFlag.count({ where: { enabled: true } }),
      this.checkMigrations(),
    ]);

    return {
      environment: app.nodeEnv,
      security: {
        usingDevJwtSecrets,
        corsWildcard,
        // These are hard boot-time failures in production (see
        // validateEnv) — surfaced here too so staging/dev can catch them
        // before a production promotion, not just at production boot.
        productionSafe: app.nodeEnv !== 'production' || (!usingDevJwtSecrets && !corsWildcard),
      },
      integrations: {
        mediaStorage: media.storageProvider === 's3' ? Boolean(media.s3Bucket) : true,
        email: email.provider === 'smtp' ? Boolean(email.smtpHost) : true,
        googleSignIn: Boolean(socialAuth.googleClientId),
        appleSignIn: Boolean(socialAuth.appleClientId),
        aiProvider: this.isAiProviderConfigured(ai),
        research: Boolean(research.braveSearchApiKey),
        remotePush: Boolean(push.fcmServiceAccountJson && push.fcmProjectId),
        appleIap: Boolean(iap.appleSharedSecret),
        googleIap: Boolean(iap.googleServiceAccountJson && iap.googlePackageName),
      },
      featureFlags: {
        total: flagCount,
        enabled: enabledFlagCount,
      },
      migrations,
    };
  }

  /**
   * Compares every migration directory committed under
   * prisma/migrations/ against Prisma's own `_prisma_migrations`
   * bookkeeping table. `finished_at IS NOT NULL AND rolled_back_at IS
   * NULL` is Prisma's own definition of "successfully applied" — the
   * same condition `prisma migrate status` itself checks. Deliberately
   * doesn't shell out to that command: the `prisma` CLI is a
   * devDependency (see package.json), so it isn't installed in the
   * pruned production build this runs in.
   *
   * Returns `upToDate: false` (never a false "yes") if the migrations
   * directory can't even be found — an environment/packaging problem is
   * not evidence the database is actually current.
   */
  private async checkMigrations(): Promise<{
    upToDate: boolean;
    pending: string[];
  }> {
    if (!existsSync(MIGRATIONS_DIR)) {
      return { upToDate: false, pending: [] };
    }
    const onDisk = readdirSync(MIGRATIONS_DIR).filter((entry) =>
      statSync(join(MIGRATIONS_DIR, entry)).isDirectory(),
    );

    const applied = await this.prisma.$queryRaw<AppliedMigrationRow[]>`
      SELECT migration_name FROM "_prisma_migrations"
      WHERE finished_at IS NOT NULL AND rolled_back_at IS NULL
    `;
    const appliedNames = new Set(applied.map((row) => row.migration_name));

    const pending = onDisk.filter((name) => !appliedNames.has(name)).sort();
    return { upToDate: pending.length === 0, pending };
  }

  private isAiProviderConfigured(ai: AiConfig): boolean {
    switch (ai.provider) {
      case 'anthropic':
        return Boolean(ai.anthropicApiKey);
      case 'openai':
        return Boolean(ai.openaiApiKey);
      case 'gemini':
        return Boolean(ai.geminiApiKey);
      default:
        return false;
    }
  }
}
