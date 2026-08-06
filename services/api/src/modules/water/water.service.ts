import { Injectable, NotFoundException } from '@nestjs/common';
import { IdempotencyService } from '../../common/idempotency/idempotency.service';
import { PrismaService } from '../../prisma/prisma.service';
import { LogWaterDto } from './dto/log-water.dto';
import { UpdateWaterDto } from './dto/update-water.dto';

function parseDateOnly(date: string): Date {
  return new Date(`${date}T00:00:00.000Z`);
}

@Injectable()
export class WaterService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly idempotencyService: IdempotencyService,
  ) {}

  async getDaily(userId: string, date: string) {
    const entries = await this.prisma.waterEntry.findMany({
      where: { userId, date: parseDateOnly(date) },
      orderBy: { loggedAt: 'asc' },
    });
    return {
      date,
      totalMl: entries.reduce((sum, e) => sum + e.amountMl, 0),
      entries: entries.map((e) => this.serialize(e)),
    };
  }

  async addEntry(userId: string, dto: LogWaterDto) {
    const run = async () => {
      const created = await this.prisma.waterEntry.create({
        data: { userId, date: parseDateOnly(dto.date), amountMl: dto.amountMl },
      });
      return { entityId: created.id, payload: this.serialize(created) };
    };

    if (dto.idempotencyKey) {
      return this.idempotencyService.run(
        {
          userId,
          idempotencyKey: dto.idempotencyKey,
          entityType: 'WATER_ENTRY',
          operationType: 'CREATE',
        },
        run,
      );
    }
    return (await run()).payload;
  }

  async updateEntry(userId: string, id: string, dto: UpdateWaterDto) {
    await this.findOwned(userId, id);
    const updated = await this.prisma.waterEntry.update({
      where: { id },
      data: { amountMl: dto.amountMl },
    });
    return this.serialize(updated);
  }

  async deleteEntry(userId: string, id: string): Promise<void> {
    await this.findOwned(userId, id);
    await this.prisma.waterEntry.delete({ where: { id } });
  }

  private async findOwned(userId: string, id: string) {
    const entry = await this.prisma.waterEntry.findUnique({ where: { id } });
    if (!entry || entry.userId !== userId) {
      throw new NotFoundException('Water entry not found.');
    }
    return entry;
  }

  private serialize(entry: { id: string; date: Date; amountMl: number; loggedAt: Date }) {
    return {
      id: entry.id,
      date: entry.date.toISOString().slice(0, 10),
      amountMl: entry.amountMl,
      loggedAt: entry.loggedAt,
    };
  }
}
