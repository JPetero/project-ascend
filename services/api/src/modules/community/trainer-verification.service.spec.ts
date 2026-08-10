import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { TrainerVerificationService } from './trainer-verification.service';

describe('TrainerVerificationService', () => {
  let service: TrainerVerificationService;
  let prisma: {
    trainerVerificationApplication: { upsert: jest.Mock; findUnique: jest.Mock };
  };

  beforeEach(async () => {
    prisma = {
      trainerVerificationApplication: { upsert: jest.fn(), findUnique: jest.fn() },
    };

    const moduleRef = await Test.createTestingModule({
      providers: [TrainerVerificationService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = moduleRef.get(TrainerVerificationService);
  });

  describe('apply', () => {
    it('upserts keyed on userId so re-applying resets to PENDING', async () => {
      prisma.trainerVerificationApplication.upsert.mockResolvedValue({
        status: 'PENDING',
        submittedAt: new Date('2026-08-10T00:00:00.000Z'),
      });

      const result = await service.apply('user-1', { credentials: 'NASM certified, 5 years' });

      expect(prisma.trainerVerificationApplication.upsert).toHaveBeenCalledWith({
        where: { userId: 'user-1' },
        update: { credentials: 'NASM certified, 5 years', status: 'PENDING', reviewedAt: null },
        create: { userId: 'user-1', credentials: 'NASM certified, 5 years' },
      });
      expect(result).toEqual({ status: 'PENDING', submittedAt: expect.any(Date) });
    });
  });

  describe('getMine', () => {
    it('returns null when the user never applied', async () => {
      prisma.trainerVerificationApplication.findUnique.mockResolvedValue(null);

      const result = await service.getMine('user-1');

      expect(result).toBeNull();
    });

    it('returns the status and submittedAt when an application exists', async () => {
      const submittedAt = new Date('2026-08-10T00:00:00.000Z');
      prisma.trainerVerificationApplication.findUnique.mockResolvedValue({
        userId: 'user-1',
        credentials: 'NASM certified',
        status: 'APPROVED',
        submittedAt,
        reviewedAt: submittedAt,
      });

      const result = await service.getMine('user-1');

      expect(result).toEqual({ status: 'APPROVED', submittedAt });
    });
  });
});
