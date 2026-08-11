import { ConfigService } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { readdirSync, statSync } from 'fs';
import { join } from 'path';
import { PrismaService } from '../../prisma/prisma.service';
import { FeatureFlagsService } from '../feature-flags/feature-flags.service';
import {
  ReadinessItem,
  ReadinessStatus,
  ReleaseReadinessService,
} from './release-readiness.service';

// Enumerates the same real prisma/migrations/ directory the service
// itself reads — used to build a "everything is applied" $queryRaw mock
// by default, without hardcoding actual migration names here (which
// would go stale every time a migration is added).
function realMigrationNames(): string[] {
  const dir = join(__dirname, '../../../prisma/migrations');
  return readdirSync(dir).filter((entry) => statSync(join(dir, entry)).isDirectory());
}

describe('ReleaseReadinessService', () => {
  let service: ReleaseReadinessService;
  let prisma: { featureFlag: { count: jest.Mock }; $queryRaw: jest.Mock };
  let featureFlags: { listAllWithDefinitions: jest.Mock };
  let configValues: Record<string, unknown>;

  function buildConfigService(): { get: jest.Mock } {
    return { get: jest.fn((key: string) => configValues[key]) };
  }

  function findItem(items: ReadinessItem[], key: string): ReadinessItem {
    const item = items.find((entry) => entry.key === key);
    if (!item) throw new Error(`No readiness item with key "${key}"`);
    return item;
  }

  beforeEach(async () => {
    prisma = {
      featureFlag: { count: jest.fn().mockResolvedValue(0) },
      $queryRaw: jest
        .fn()
        .mockResolvedValue(realMigrationNames().map((name) => ({ migration_name: name }))),
    };
    // Every flag off by default — matches the registry defaults for the
    // RISKY_EXTERNAL flags this service reports on (LIVE_AI,
    // RESEARCH_MODE, STORE_PURCHASES) and lets individual tests turn a
    // specific one on.
    featureFlags = { listAllWithDefinitions: jest.fn().mockResolvedValue([]) };
    configValues = {
      app: {
        nodeEnv: 'development',
        corsOrigin: '*',
        jwt: { accessSecret: 'dev_access', refreshSecret: 'dev_refresh' },
      },
      media: { storageProvider: 'local' },
      email: { provider: 'console' },
      socialAuth: {},
      ai: { provider: 'anthropic' },
      research: {},
      push: {},
      iap: {},
    };

    const moduleRef = await Test.createTestingModule({
      providers: [
        ReleaseReadinessService,
        { provide: PrismaService, useValue: prisma },
        { provide: ConfigService, useValue: buildConfigService() },
        { provide: FeatureFlagsService, useValue: featureFlags },
      ],
    }).compile();

    service = moduleRef.get(ReleaseReadinessService);
  });

  it('flags dev JWT secrets and wildcard CORS as not production-safe', async () => {
    const result = await service.check();

    expect(result.security.usingDevJwtSecrets).toBe(true);
    expect(result.security.corsWildcard).toBe(true);
  });

  it('treats a non-production environment as production-safe regardless of dev secrets', async () => {
    const result = await service.check();

    expect(result.environment).toBe('development');
    expect(result.security.productionSafe).toBe(true);
  });

  it('reports productionSafe=false in production with dev secrets or wildcard CORS', async () => {
    configValues.app = {
      nodeEnv: 'production',
      corsOrigin: '*',
      jwt: { accessSecret: 'dev_access', refreshSecret: 'dev_refresh' },
    };

    const result = await service.check();

    expect(result.security.productionSafe).toBe(false);
  });

  it('reports each integration as not configured when its env vars are unset', async () => {
    const result = await service.check();

    expect(result.integrations).toEqual({
      mediaStorage: true,
      email: true,
      googleSignIn: false,
      appleSignIn: false,
      aiProvider: false,
      research: false,
      remotePush: false,
      appleIap: false,
      googleIap: false,
    });
  });

  it('reports an integration as configured once its required secret is present', async () => {
    configValues.ai = { provider: 'anthropic', anthropicApiKey: 'sk-test' };

    const result = await service.check();

    expect(result.integrations.aiProvider).toBe(true);
  });

  it('never includes raw secret values in the response', async () => {
    configValues.ai = { provider: 'anthropic', anthropicApiKey: 'sk-super-secret' };

    const result = await service.check();

    expect(JSON.stringify(result)).not.toContain('sk-super-secret');
  });

  it('summarizes feature flag counts', async () => {
    prisma.featureFlag.count.mockResolvedValueOnce(5).mockResolvedValueOnce(3);

    const result = await service.check();

    expect(result.featureFlags).toEqual({ total: 5, enabled: 3 });
  });

  describe('migrations', () => {
    it('reports upToDate=true when every on-disk migration is recorded as applied', async () => {
      const result = await service.check();

      expect(result.migrations).toEqual({ upToDate: true, pending: [] });
    });

    it('reports a pending migration when a directory exists on disk but was never applied', async () => {
      const allNames = realMigrationNames();
      const [missing, ...stillApplied] = allNames;
      prisma.$queryRaw.mockResolvedValue(stillApplied.map((name) => ({ migration_name: name })));

      const result = await service.check();

      expect(result.migrations.upToDate).toBe(false);
      expect(result.migrations.pending).toEqual([missing]);
    });

    it('never reports upToDate=true when the applied set is empty but migrations exist on disk', async () => {
      prisma.$queryRaw.mockResolvedValue([]);

      const result = await service.check();

      expect(result.migrations.upToDate).toBe(false);
      expect(result.migrations.pending.length).toBe(realMigrationNames().length);
    });
  });

  describe('items[] (S14 Part 7)', () => {
    it('covers every entry the directive explicitly asked for', async () => {
      const result = await service.check();

      const keys = result.items.map((item) => item.key);
      expect(keys).toEqual(
        expect.arrayContaining([
          'androidPackageIdentity',
          'androidSigning',
          'mobileProductionApiUrl',
          'mobileStagingApiUrl',
          'database',
          'migrations',
          'mediaStorage',
          'email',
          'firebaseFcm',
          'googleSignIn',
          'appleSignIn',
          'liveAi',
          'research',
          'playBilling',
          'storeKit',
          'visionPhysicalDeviceQa',
          'healthConnectQa',
          'healthKitQa',
          'backupAutomation',
        ]),
      );
    });

    it('never uses a status outside the explicit ReadinessStatus vocabulary', async () => {
      const result = await service.check();

      const validStatuses = new Set(Object.values(ReadinessStatus));
      for (const item of result.items) {
        expect(validStatuses.has(item.status)).toBe(true);
      }
    });

    it('marks physical-device QA items as DEVICE_QA_REQUIRED, never READY, regardless of any test run', async () => {
      const result = await service.check();

      expect(findItem(result.items, 'visionPhysicalDeviceQa').status).toBe(
        ReadinessStatus.DEVICE_QA_REQUIRED,
      );
      expect(findItem(result.items, 'healthConnectQa').status).toBe(
        ReadinessStatus.DEVICE_QA_REQUIRED,
      );
      expect(findItem(result.items, 'healthKitQa').status).toBe(ReadinessStatus.DEVICE_QA_REQUIRED);
    });

    it('reports database as READY (this check itself required a live connection)', async () => {
      const result = await service.check();

      expect(findItem(result.items, 'database').status).toBe(ReadinessStatus.READY);
    });

    it('reports a flag-gated integration as DISABLED when its feature flag is off', async () => {
      const result = await service.check();

      expect(findItem(result.items, 'liveAi').status).toBe(ReadinessStatus.DISABLED);
      expect(findItem(result.items, 'research').status).toBe(ReadinessStatus.DISABLED);
    });

    it('reports CREDENTIALS_REQUIRED once a flag is on but its key is missing', async () => {
      featureFlags.listAllWithDefinitions.mockResolvedValue([{ key: 'LIVE_AI', enabled: true }]);

      const result = await service.check();

      expect(findItem(result.items, 'liveAi').status).toBe(ReadinessStatus.CREDENTIALS_REQUIRED);
    });

    it('reports READY once a flag is on and its key is configured', async () => {
      featureFlags.listAllWithDefinitions.mockResolvedValue([{ key: 'LIVE_AI', enabled: true }]);
      configValues.ai = { provider: 'anthropic', anthropicApiKey: 'sk-test' };

      const result = await service.check();

      expect(findItem(result.items, 'liveAi').status).toBe(ReadinessStatus.READY);
    });

    it('never reports Play Billing/StoreKit as READY even with real credentials — sandbox QA is still required', async () => {
      featureFlags.listAllWithDefinitions.mockResolvedValue([
        { key: 'STORE_PURCHASES', enabled: true },
      ]);
      configValues.iap = {
        appleSharedSecret: 'shh',
        googleServiceAccountJson: '{}',
        googlePackageName: 'com.projectascend.mobile',
      };

      const result = await service.check();

      expect(findItem(result.items, 'playBilling').status).toBe(
        ReadinessStatus.STORE_SETUP_REQUIRED,
      );
      expect(findItem(result.items, 'storeKit').status).toBe(ReadinessStatus.STORE_SETUP_REQUIRED);
    });

    it('reports Play Billing/StoreKit as DISABLED while the STORE_PURCHASES flag is off, per the beta feature profile', async () => {
      const result = await service.check();

      expect(findItem(result.items, 'playBilling').status).toBe(ReadinessStatus.DISABLED);
      expect(findItem(result.items, 'storeKit').status).toBe(ReadinessStatus.DISABLED);
    });

    it('never includes a raw secret value in any item detail', async () => {
      featureFlags.listAllWithDefinitions.mockResolvedValue([{ key: 'LIVE_AI', enabled: true }]);
      configValues.ai = { provider: 'anthropic', anthropicApiKey: 'sk-super-secret' };

      const result = await service.check();

      expect(JSON.stringify(result.items)).not.toContain('sk-super-secret');
    });

    it('requires production media storage config even though local storage is READY outside production', async () => {
      const devResult = await service.check();
      expect(findItem(devResult.items, 'mediaStorage').status).toBe(ReadinessStatus.READY);

      configValues.app = {
        nodeEnv: 'production',
        corsOrigin: 'https://app.example.com',
        jwt: { accessSecret: 'real', refreshSecret: 'real' },
      };
      const prodResult = await service.check();
      expect(findItem(prodResult.items, 'mediaStorage').status).toBe(
        ReadinessStatus.CONFIG_REQUIRED,
      );
    });
  });
});
