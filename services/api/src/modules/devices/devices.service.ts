import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateDeviceDto } from './dto/create-device.dto';
import { UpdateDeviceDto } from './dto/update-device.dto';

@Injectable()
export class DevicesService {
  constructor(private readonly prisma: PrismaService) {}

  list(userId: string) {
    return this.prisma.deviceConnection.findMany({
      where: { userId },
      orderBy: { createdAt: 'asc' },
    });
  }

  create(userId: string, dto: CreateDeviceDto) {
    return this.prisma.deviceConnection.create({
      data: {
        userId,
        provider: dto.provider,
        displayName: dto.displayName,
        status: dto.status ?? 'PENDING',
        externalAccountId: dto.externalAccountId,
        metadata: (dto.metadata ?? {}) as Prisma.InputJsonValue,
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

  async remove(userId: string, deviceId: string): Promise<void> {
    await this.ensureOwnedByUser(userId, deviceId);
    await this.prisma.deviceConnection.delete({ where: { id: deviceId } });
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
