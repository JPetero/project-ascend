import { NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { HealthMetricsService } from '../health-metrics/health-metrics.service';
import { DevicesService } from './devices.service';

function deviceConnection(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'device-1',
    userId: 'user-1',
    provider: 'HEALTH_CONNECT',
    connectionKey: 'default',
    displayName: 'My Phone',
    status: 'CONNECTED',
    externalAccountId: null,
    lastSyncedAt: null,
    metadata: {},
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}

describe('DevicesService', () => {
  let service: DevicesService;
  let prisma: {
    deviceConnection: { findUnique: jest.Mock; delete: jest.Mock; upsert: jest.Mock };
  };
  let healthMetricsService: { clearCursorsForProvider: jest.Mock };

  beforeEach(async () => {
    prisma = {
      deviceConnection: { findUnique: jest.fn(), delete: jest.fn(), upsert: jest.fn() },
    };
    healthMetricsService = { clearCursorsForProvider: jest.fn() };

    const moduleRef = await Test.createTestingModule({
      providers: [
        DevicesService,
        { provide: PrismaService, useValue: prisma },
        { provide: HealthMetricsService, useValue: healthMetricsService },
      ],
    }).compile();

    service = moduleRef.get(DevicesService);
  });

  it('rejects removing a device owned by another user', async () => {
    prisma.deviceConnection.findUnique.mockResolvedValue(
      deviceConnection({ userId: 'someone-else' }),
    );

    await expect(service.remove('user-1', 'device-1')).rejects.toBeInstanceOf(NotFoundException);
    expect(prisma.deviceConnection.delete).not.toHaveBeenCalled();
    expect(healthMetricsService.clearCursorsForProvider).not.toHaveBeenCalled();
  });

  it('rejects removing a device that does not exist', async () => {
    prisma.deviceConnection.findUnique.mockResolvedValue(null);

    await expect(service.remove('user-1', 'missing')).rejects.toBeInstanceOf(NotFoundException);
  });

  it('deletes the connection and clears its provider’s Health Connect/HealthKit sync cursors', async () => {
    prisma.deviceConnection.findUnique.mockResolvedValue(
      deviceConnection({ provider: 'HEALTH_CONNECT' }),
    );

    await service.remove('user-1', 'device-1');

    expect(prisma.deviceConnection.delete).toHaveBeenCalledWith({ where: { id: 'device-1' } });
    expect(healthMetricsService.clearCursorsForProvider).toHaveBeenCalledWith(
      'user-1',
      'HEALTH_CONNECT',
    );
  });

  it('only clears cursors for the removed device’s own provider, not every provider', async () => {
    prisma.deviceConnection.findUnique.mockResolvedValue(
      deviceConnection({ provider: 'APPLE_HEALTH' }),
    );

    await service.remove('user-1', 'device-1');

    expect(healthMetricsService.clearCursorsForProvider).toHaveBeenCalledWith(
      'user-1',
      'APPLE_HEALTH',
    );
    expect(healthMetricsService.clearCursorsForProvider).not.toHaveBeenCalledWith(
      'user-1',
      'HEALTH_CONNECT',
    );
  });
});
