import { ServiceUnavailableException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { HealthController } from './health.controller';

describe('HealthController', () => {
  let controller: HealthController;
  let prisma: { $queryRaw: jest.Mock };

  beforeEach(async () => {
    prisma = { $queryRaw: jest.fn().mockResolvedValue([{ '?column?': 1 }]) };

    const moduleRef = await Test.createTestingModule({
      controllers: [HealthController],
      providers: [{ provide: PrismaService, useValue: prisma }],
    }).compile();

    controller = moduleRef.get(HealthController);
  });

  describe('live (/livez)', () => {
    it('never touches the database', () => {
      const result = controller.live();

      expect(prisma.$queryRaw).not.toHaveBeenCalled();
      expect(result).toMatchObject({ status: 'ok' });
    });

    it('reports ok even when the database is unreachable', () => {
      prisma.$queryRaw.mockRejectedValue(new Error('connection refused'));

      const result = controller.live();

      expect(result).toMatchObject({ status: 'ok' });
    });
  });

  describe('ready (/readyz)', () => {
    it('reports ok when the database answers', async () => {
      const result = await controller.ready();

      expect(prisma.$queryRaw).toHaveBeenCalled();
      expect(result).toMatchObject({ status: 'ok' });
    });

    it('reports unavailable when the database is unreachable', async () => {
      prisma.$queryRaw.mockRejectedValue(new Error('connection refused'));

      await expect(controller.ready()).rejects.toBeInstanceOf(ServiceUnavailableException);
    });
  });

  describe('legacyHealth (/health)', () => {
    it('behaves exactly like /readyz — checks the database', async () => {
      const result = await controller.legacyHealth();

      expect(prisma.$queryRaw).toHaveBeenCalled();
      expect(result).toMatchObject({ status: 'ok' });
    });

    it('reports unavailable when the database is unreachable, same as /readyz', async () => {
      prisma.$queryRaw.mockRejectedValue(new Error('connection refused'));

      await expect(controller.legacyHealth()).rejects.toBeInstanceOf(ServiceUnavailableException);
    });
  });
});
