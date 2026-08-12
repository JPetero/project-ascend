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
import { isDeployedEnvironment } from '../../config/deployment-environment';
import { AscendFeatureKey } from '../feature-flags/feature-flag-registry';
import { FeatureFlagsService } from '../feature-flags/feature-flags.service';

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
 * S14 Part 7 — the explicit status vocabulary every `items[]` entry
 * below uses. Never invent a status outside this set, and never use
 * READY for anything this service cannot actually verify — a physical
 * device pass, a GitHub Actions secret, or manual store-sandbox testing
 * are all outside what a backend process can observe, so those items
 * are capped at CODE_READY/DEVICE_QA_REQUIRED/STORE_SETUP_REQUIRED even
 * when the surrounding code is completely correct.
 */
export enum ReadinessStatus {
  /** Fully verified from this environment's own live state (e.g. a real DB query succeeded). */
  READY = 'READY',
  /** The code/architecture is correct and in place, but this service cannot verify the external config it depends on (a GitHub Actions secret, a store console setup) from here. */
  CODE_READY = 'CODE_READY',
  /** A known config value is missing or unsafe for this environment. */
  CONFIG_REQUIRED = 'CONFIG_REQUIRED',
  /** A specific external credential/key is missing. */
  CREDENTIALS_REQUIRED = 'CREDENTIALS_REQUIRED',
  /** Needs an app-store-side setup step (Play Console, App Store Connect) this service cannot see. */
  STORE_SETUP_REQUIRED = 'STORE_SETUP_REQUIRED',
  /** Can only be confirmed by running on real hardware — never inferred from a unit/e2e test pass. */
  DEVICE_QA_REQUIRED = 'DEVICE_QA_REQUIRED',
  /** A hard blocker independent of config (e.g. pending migrations, no automated backups at all). */
  BLOCKED = 'BLOCKED',
  /** Deliberately off via feature flag — not a gap, a product decision. */
  DISABLED = 'DISABLED',
  /** The check itself failed to run. */
  ERROR = 'ERROR',
}

export interface ReadinessItem {
  key: string;
  label: string;
  category: string;
  status: ReadinessStatus;
  /** Actionable, human-readable next step — never a secret or key value. */
  detail: string;
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
 * S13 Part 16-27 (V2) added the `migrations` check below.
 *
 * S14 Part 7 (V3) adds `items[]`: every entry the directive explicitly
 * asked for (Android package identity/signing, mobile prod/staging API
 * URL, database, migrations, media storage, email, Firebase/FCM, Google/
 * Apple Sign In, live AI, research, Play Billing, StoreKit, Vision/Health
 * Connect/HealthKit physical-device QA, backup automation), each using
 * the explicit `ReadinessStatus` vocabulary with an actionable `detail`.
 * The legacy `security`/`integrations`/`migrations`/`featureFlags` fields
 * are unchanged so the existing admin UI/tests keep working — `items[]`
 * is additive, not a replacement.
 */
@Injectable()
export class ReleaseReadinessService {
  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
    private readonly featureFlags: FeatureFlagsService,
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

    const [flagCount, enabledFlagCount, migrations, flagEntries] = await Promise.all([
      this.prisma.featureFlag.count(),
      this.prisma.featureFlag.count({ where: { enabled: true } }),
      this.checkMigrations(),
      this.featureFlags.listAllWithDefinitions(),
    ]);

    const flagEnabled = new Map(flagEntries.map((entry) => [entry.key, entry.enabled]));
    const isFlagOn = (key: AscendFeatureKey) => flagEnabled.get(key) ?? false;

    return {
      environment: app.nodeEnv,
      // S15 Part 1 — the deployment tier (development | staging |
      // production), distinct from `environment` above (which is only
      // ever NODE_ENV's three values and can no longer tell staging and
      // production apart now that staging correctly runs
      // NODE_ENV=production too). Additive — `environment` is unchanged
      // for whatever already reads it.
      ascendEnv: app.ascendEnv,
      security: {
        usingDevJwtSecrets,
        corsWildcard,
        // These are hard boot-time failures for any deployed
        // environment — staging and production alike (see
        // DeploymentConfigValidation) — surfaced here too so a
        // not-yet-deployed dev/test environment can catch them before
        // ever being promoted to staging or production.
        productionSafe:
          !isDeployedEnvironment(app.ascendEnv) || (!usingDevJwtSecrets && !corsWildcard),
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
      items: this.buildItems({
        app,
        media,
        email,
        socialAuth,
        ai,
        research,
        push,
        iap,
        migrations,
        isFlagOn,
      }),
    };
  }

  private buildItems(ctx: {
    app: AppConfig;
    media: MediaConfig;
    email: EmailConfig;
    socialAuth: SocialAuthConfig;
    ai: AiConfig;
    research: ResearchConfig;
    push: PushConfig;
    iap: IapConfig;
    migrations: { upToDate: boolean; pending: string[] };
    isFlagOn: (key: AscendFeatureKey) => boolean;
  }): ReadinessItem[] {
    // S15 Part 1-2 — staging is a real deployed environment too now
    // that it correctly runs NODE_ENV=production; "is this environment
    // real enough that local-filesystem media/console email should be
    // flagged" means isDeployedEnvironment, not nodeEnv === 'production'.
    const isProduction = isDeployedEnvironment(ctx.app.ascendEnv);

    return [
      // --- Mobile / CI (not directly observable from this backend process) ---
      {
        key: 'androidPackageIdentity',
        label: 'Android package identity',
        category: 'mobile',
        status: ReadinessStatus.CODE_READY,
        detail:
          'com.projectascend.mobile is fixed in code (PROVISIONAL_RELEASE_ID) — create the matching Google Play Console app before publishing. See founder-setup-checklist.md.',
      },
      {
        key: 'androidSigning',
        label: 'Android release signing',
        category: 'mobile',
        status: ReadinessStatus.CODE_READY,
        detail:
          'Gradle hard-fails a prod release/bundle build without real signing configured (build.gradle.kts). This service cannot see GitHub Actions secrets — confirm the Mobile CI production-build job runs unguarded.',
      },
      {
        key: 'mobileProductionApiUrl',
        label: 'Mobile production API URL',
        category: 'mobile',
        status: ReadinessStatus.CODE_READY,
        detail:
          'AppConfigValidation blocks app startup on an unsafe/missing production API URL. Set the PROD_API_BASE_URL GitHub Actions secret to a real HTTPS host before the production-build job can produce a real artifact.',
      },
      {
        key: 'mobileStagingApiUrl',
        label: 'Mobile staging API URL',
        category: 'mobile',
        status: ReadinessStatus.CODE_READY,
        detail:
          'Set the STAGING_API_BASE_URL GitHub Actions repository variable so Mobile CI builds a real staging APK instead of the development-sideload fallback. See android-sideload-beta.md.',
      },

      // --- Core infra (directly observable) ---
      {
        key: 'database',
        label: 'Database',
        category: 'infrastructure',
        status: ReadinessStatus.READY,
        detail: 'This check ran, which itself required a live database connection.',
      },
      {
        key: 'migrations',
        label: 'Migration state',
        category: 'infrastructure',
        status: ctx.migrations.upToDate ? ReadinessStatus.READY : ReadinessStatus.BLOCKED,
        detail: ctx.migrations.upToDate
          ? 'Every migration on disk is recorded as applied.'
          : `${ctx.migrations.pending.length} migration(s) on disk have not been applied — run prisma migrate deploy before serving traffic.`,
      },
      {
        key: 'mediaStorage',
        label: 'Media storage',
        category: 'infrastructure',
        status: this.mediaStorageStatus(ctx.media, isProduction),
        detail:
          ctx.media.storageProvider === 's3'
            ? ctx.media.s3Bucket
              ? 'S3-compatible bucket configured.'
              : 'MEDIA_STORAGE_PROVIDER=s3 but no bucket is set — configure MEDIA_S3_BUCKET and related vars.'
            : isProduction
              ? 'Local filesystem storage is configured but not durable/shared across instances — configure an S3-compatible provider before production.'
              : 'Local filesystem storage — fine for this non-production environment.',
      },
      {
        key: 'email',
        label: 'Email delivery',
        category: 'infrastructure',
        status: this.emailStatus(ctx.email, isProduction),
        detail:
          ctx.email.provider === 'smtp'
            ? ctx.email.smtpHost
              ? 'SMTP host configured.'
              : 'EMAIL_PROVIDER=smtp but no SMTP host is set.'
            : isProduction
              ? 'Console email provider only logs — configure a real SMTP provider before production.'
              : 'Console email provider — fine for this non-production environment (emails are logged, not sent).',
      },

      // --- Feature-flagged integrations ---
      this.flagGatedItem({
        key: 'firebaseFcm',
        label: 'Firebase / FCM (remote push)',
        flag: AscendFeatureKey.REMOTE_PUSH,
        isFlagOn: ctx.isFlagOn,
        configured: Boolean(ctx.push.fcmServiceAccountJson && ctx.push.fcmProjectId),
        credentialsDetail: 'Set FCM_SERVICE_ACCOUNT_JSON and FCM_PROJECT_ID.',
        readyDetail: 'Firebase service account and project id configured.',
      }),
      this.flagGatedItem({
        key: 'googleSignIn',
        label: 'Google Sign In',
        flag: AscendFeatureKey.GOOGLE_SIGN_IN,
        isFlagOn: ctx.isFlagOn,
        configured: Boolean(ctx.socialAuth.googleClientId),
        credentialsDetail: 'Set GOOGLE_CLIENT_ID from the Google Cloud Console OAuth client.',
        readyDetail: 'Google OAuth client id configured.',
      }),
      this.flagGatedItem({
        key: 'appleSignIn',
        label: 'Apple Sign In',
        flag: AscendFeatureKey.APPLE_SIGN_IN,
        isFlagOn: ctx.isFlagOn,
        configured: Boolean(ctx.socialAuth.appleClientId),
        credentialsDetail: 'Set APPLE_CLIENT_ID from the registered Services ID / bundle id.',
        readyDetail: 'Apple Services ID configured.',
      }),
      this.flagGatedItem({
        key: 'liveAi',
        label: 'Live Ascend AI',
        flag: AscendFeatureKey.LIVE_AI,
        isFlagOn: ctx.isFlagOn,
        configured: this.isAiProviderConfigured(ctx.ai),
        credentialsDetail: `AI_PROVIDER=${ctx.ai.provider} but its API key is not set.`,
        readyDetail: `${ctx.ai.provider} API key configured.`,
      }),
      this.flagGatedItem({
        key: 'research',
        label: 'Research Mode',
        flag: AscendFeatureKey.RESEARCH_MODE,
        isFlagOn: ctx.isFlagOn,
        configured: Boolean(ctx.research.braveSearchApiKey),
        credentialsDetail: 'Set BRAVE_SEARCH_API_KEY to enable live research retrieval.',
        readyDetail: 'Brave Search API key configured.',
      }),

      // --- Store billing (deliberately gated behind manual sandbox QA — S14 Part 40) ---
      this.storeItem({
        key: 'playBilling',
        label: 'Google Play Billing',
        flag: AscendFeatureKey.STORE_PURCHASES,
        isFlagOn: ctx.isFlagOn,
        configured: Boolean(ctx.iap.googleServiceAccountJson && ctx.iap.googlePackageName),
        credentialsDetail: 'Set GOOGLE_PLAY_SERVICE_ACCOUNT_JSON and GOOGLE_PLAY_PACKAGE_NAME.',
        storeSetupDetail:
          'Credentials configured, but Play sandbox receipt verification, restore, cancellation, and grace-period behavior still need manual testing before enabling — see beta-blockers.md Part 40.',
      }),
      this.storeItem({
        key: 'storeKit',
        label: 'Apple StoreKit',
        flag: AscendFeatureKey.STORE_PURCHASES,
        isFlagOn: ctx.isFlagOn,
        configured: Boolean(ctx.iap.appleSharedSecret),
        credentialsDetail: 'Set APPLE_IAP_SHARED_SECRET.',
        storeSetupDetail:
          'Shared secret configured, but StoreKit sandbox receipt verification, restore, and cancellation behavior still need manual testing before enabling — see beta-blockers.md Part 40.',
      }),

      // --- Physical-device QA — never inferable from a unit/e2e test pass ---
      {
        key: 'visionPhysicalDeviceQa',
        label: 'Vision physical-device QA',
        category: 'device-qa',
        status: ReadinessStatus.DEVICE_QA_REQUIRED,
        detail:
          'Camera-based pose analysis has no automated substitute for real hardware — run qa/vision-physical-device-checklist.md on real devices.',
      },
      {
        key: 'healthConnectQa',
        label: 'Health Connect QA (Android)',
        category: 'device-qa',
        status: ReadinessStatus.DEVICE_QA_REQUIRED,
        detail:
          'Requires a real Android device with Health Connect and a data-source app installed — run qa/xiaomi-health-connect-checklist.md (or the equivalent for the test device) before relying on this integration.',
      },
      {
        key: 'healthKitQa',
        label: 'HealthKit QA (iOS)',
        category: 'device-qa',
        status: ReadinessStatus.DEVICE_QA_REQUIRED,
        detail:
          'Requires a real iOS device with the Health app populated with real data — see qa/release-device-matrix.md for the iOS device rows.',
      },

      // --- Operations ---
      {
        key: 'backupAutomation',
        label: 'Database backup automation',
        category: 'operations',
        status: ReadinessStatus.BLOCKED,
        detail:
          'No scheduled backup job exists yet — backup-and-restore-runbook.md documents the manual procedure and what a real deployment should automate before production.',
      },
    ];
  }

  private mediaStorageStatus(media: MediaConfig, isProduction: boolean): ReadinessStatus {
    if (media.storageProvider === 's3') {
      return media.s3Bucket ? ReadinessStatus.READY : ReadinessStatus.CONFIG_REQUIRED;
    }
    return isProduction ? ReadinessStatus.CONFIG_REQUIRED : ReadinessStatus.READY;
  }

  private emailStatus(email: EmailConfig, isProduction: boolean): ReadinessStatus {
    if (email.provider === 'smtp') {
      return email.smtpHost ? ReadinessStatus.READY : ReadinessStatus.CONFIG_REQUIRED;
    }
    return isProduction ? ReadinessStatus.CONFIG_REQUIRED : ReadinessStatus.READY;
  }

  private flagGatedItem(params: {
    key: string;
    label: string;
    flag: AscendFeatureKey;
    isFlagOn: (key: AscendFeatureKey) => boolean;
    configured: boolean;
    credentialsDetail: string;
    readyDetail: string;
  }): ReadinessItem {
    const enabled = params.isFlagOn(params.flag);
    let status: ReadinessStatus;
    let detail: string;
    if (!enabled) {
      status = ReadinessStatus.DISABLED;
      detail = `${params.flag} feature flag is off — no credentials required until it's enabled.`;
    } else if (!params.configured) {
      status = ReadinessStatus.CREDENTIALS_REQUIRED;
      detail = params.credentialsDetail;
    } else {
      status = ReadinessStatus.READY;
      detail = params.readyDetail;
    }
    return { key: params.key, label: params.label, category: 'integrations', status, detail };
  }

  private storeItem(params: {
    key: string;
    label: string;
    flag: AscendFeatureKey;
    isFlagOn: (key: AscendFeatureKey) => boolean;
    configured: boolean;
    credentialsDetail: string;
    storeSetupDetail: string;
  }): ReadinessItem {
    const enabled = params.isFlagOn(params.flag);
    let status: ReadinessStatus;
    let detail: string;
    if (!enabled) {
      status = ReadinessStatus.DISABLED;
      detail = `${params.flag} feature flag is off by design for the initial beta — see beta-blockers.md Part 40.`;
    } else if (!params.configured) {
      status = ReadinessStatus.CREDENTIALS_REQUIRED;
      detail = params.credentialsDetail;
    } else {
      status = ReadinessStatus.STORE_SETUP_REQUIRED;
      detail = params.storeSetupDetail;
    }
    return { key: params.key, label: params.label, category: 'billing', status, detail };
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
