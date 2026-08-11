import { ConfigService } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { readdirSync, statSync } from 'fs';
import { join } from 'path';
import { PrismaService } from '../../prisma/prisma.service';
import { ReleaseReadinessService } from './release-readiness.service';

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
  let configValues: Record<string, unknown>;

  function buildConfigService(): { get: jest.Mock } {
    return { get: jest.fn((key: string) => configValues[key]) };
  }

  beforeEach(async () => {
    prisma = {
      featureFlag: { count: jest.fn().mockResolvedValue(0) },
      $queryRaw: jest
        .fn()
        .mockResolvedValue(realMigrationNames().map((name) => ({ migration_name: name }))),
    };
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
});
