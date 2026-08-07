import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { HealthMetricsService } from '../health-metrics/health-metrics.service';
import { CreateDeviceDto } from './dto/create-device.dto';
import { UpdateDeviceDto } from './dto/update-device.dto';

@Injectable()
export class DevicesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly healthMetricsService: HealthMetricsService,
  ) {}

  list(userId: string) {
    return this.prisma.deviceConnection.findMany({
      where: { userId },
      orderBy: { createdAt: 'asc' },
    });
  }

  /**
   * A user can only have one connection per (provider, connectionKey) pair
   * (see the `@@unique([userId, provider, connectionKey])` constraint on
   * DeviceConnection) — reconnecting the same provider+key (e.g. a
   * double-tapped toggle, or a retried request) updates that row instead
   * of creating a duplicate. Omitting `connectionKey` defaults it to
   * `"default"`, so single-device providers keep the original
   * one-connection-per-provider behavior; a client that knows it's
   * managing multiple physical devices for the same provider passes a
   * distinct key per device to register them side by side.
   */
  create(userId: string, dto: CreateDeviceDto) {
    const metadata = (dto.metadata ?? {}) as Prisma.InputJsonValue;
    const connectionKey = dto.connectionKey ?? 'default';

    return this.prisma.deviceConnection.upsert({
      where: {
        userId_provider_connectionKey: { userId, provider: dto.provider, connectionKey },
      },
      create: {
        userId,
        provider: dto.provider,
        connectionKey,
        displayName: dto.displayName,
        status: dto.status ?? 'PENDING',
        externalAccountId: dto.externalAccountId,
        metadata,
      },
      update: {
        displayName: dto.displayName,
        status: dto.status ?? 'PENDING',
        externalAccountId: dto.externalAccountId,
        metadata,
        ...(dto.status === 'CONNECTED' ? { lastSyncedAt: new Date() } : {}),
      },
    });
  }

  async update(userId: string, deviceId: string, dto: UpdateDeviceDto) {
    await this.ensureOwnedByUser(userId, deviceId);

    return this.prisma.deviceConnection.update({
      where: { id: deviceId },
      data: {
        ...(dto.provider !== undefined ? { provider: dto.provider } : {}),
        ...(dto.displayName !== undefined ? { displayName: dto.displayName } : {}),
        ...(dto.status !== undefined ? { status: dto.status } : {}),
        ...(dto.externalAccountId !== undefined
          ? { externalAccountId: dto.externalAccountId }
          : {}),
        ...(dto.metadata !== undefined ? { metadata: dto.metadata as Prisma.InputJsonValue } : {}),
        ...(dto.status === 'CONNECTED' ? { lastSyncedAt: new Date() } : {}),
      },
    });
  }

  /**
   * Revocation must also invalidate any Health Connect/HealthKit
   * incremental-sync bookmark for this provider — disconnecting a device
   * and having it silently resume syncing (because a stale cursor is
   * still sitting there) would defeat the point of disconnecting it. See
   * packages/docs/wearables.md's revocation requirement.
   */
  async remove(userId: string, deviceId: string): Promise<void> {
    const device = await this.prisma.deviceConnection.findUnique({
      where: { id: deviceId },
    });
    if (!device || device.userId !== userId) {
      throw new NotFoundException('Device connection not found.');
    }

    await this.prisma.deviceConnection.delete({ where: { id: deviceId } });
    await this.healthMetricsService.clearCursorsForProvider(userId, device.provider);
  }

  private async ensureOwnedByUser(userId: string, deviceId: string): Promise<void> {
    const device = await this.prisma.deviceConnection.findUnique({
      where: { id: deviceId },
      select: { userId: true },
    });

    if (!device || device.userId !== userId) {
      throw new NotFoundException('Device connection not found.');
    }
  }
}
