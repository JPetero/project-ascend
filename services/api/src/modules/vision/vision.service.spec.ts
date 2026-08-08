import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { CapabilityService } from '../../common/entitlements/capability.service';
import { PrismaService } from '../../prisma/prisma.service';
import {
  CreateVisionAnalysisSessionDto,
  FormObservationSeverityDto,
  VisionExerciseDto,
} from './dto/create-vision-analysis-session.dto';
import { VisionService } from './vision.service';

function createDto(
  overrides: Partial<CreateVisionAnalysisSessionDto> = {},
): CreateVisionAnalysisSessionDto {
  return {
    exercise: VisionExerciseDto.BODYWEIGHT_SQUAT,
    startedAt: '2026-01-01T00:00:00.000Z',
    completedAt: '2026-01-01T00:05:00.000Z',
    autoRepCount: 10,
    correctedRepCount: 10,
    analysisVersion: 'pose-v1',
    observations: [],
    ...overrides,
  };
}

describe('VisionService', () => {
  let service: VisionService;
  let prisma: {
    visionAnalysisSession: {
      create: jest.Mock;
      findMany: jest.Mock;
      count: jest.Mock;
      findUnique: jest.Mock;
      delete: jest.Mock;
    };
  };
  let capabilityService: { hasCapabilityForUser: jest.Mock };

  beforeEach(async () => {
    prisma = {
      visionAnalysisSession: {
        create: jest.fn(),
        findMany: jest.fn().mockResolvedValue([]),
        count: jest.fn().mockResolvedValue(0),
        findUnique: jest.fn(),
        delete: jest.fn(),
      },
    };
    capabilityService = { hasCapabilityForUser: jest.fn().mockResolvedValue(true) };

    const moduleRef = await Test.createTestingModule({
      providers: [
        VisionService,
        { provide: PrismaService, useValue: prisma },
        { provide: CapabilityService, useValue: capabilityService },
      ],
    }).compile();

    service = moduleRef.get(VisionService);
  });

  describe('createSession', () => {
    it('rejects a non-Premium user', async () => {
      capabilityService.hasCapabilityForUser.mockResolvedValue(false);
      await expect(service.createSession('user-1', createDto())).rejects.toBeInstanceOf(
        ForbiddenException,
      );
      expect(prisma.visionAnalysisSession.create).not.toHaveBeenCalled();
    });

    it('persists the session with its observations for a Premium user', async () => {
      prisma.visionAnalysisSession.create.mockResolvedValue({ id: 'session-1' });
      const dto = createDto({
        observations: [
          {
            type: 'squat_depth',
            message: 'Depth appears limited.',
            severity: FormObservationSeverityDto.COACHING_CUE,
            confidence: 0.6,
            occurredAt: '2026-01-01T00:02:00.000Z',
          },
        ],
      });

      await service.createSession('user-1', dto);

      expect(prisma.visionAnalysisSession.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            userId: 'user-1',
            exercise: 'BODYWEIGHT_SQUAT',
            autoRepCount: 10,
            correctedRepCount: 10,
            observations: {
              create: [
                expect.objectContaining({
                  type: 'squat_depth',
                  severity: 'COACHING_CUE',
                }),
              ],
            },
          }),
        }),
      );
    });
  });

  describe('listSessions', () => {
    it('rejects a non-Premium user', async () => {
      capabilityService.hasCapabilityForUser.mockResolvedValue(false);
      await expect(
        service.listSessions('user-1', { page: 1, limit: 20, sortOrder: 'asc' as never }),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('scopes the query to the requesting user', async () => {
      await service.listSessions('user-1', { page: 1, limit: 20, sortOrder: 'asc' as never });
      expect(prisma.visionAnalysisSession.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { userId: 'user-1' } }),
      );
      expect(prisma.visionAnalysisSession.count).toHaveBeenCalledWith({
        where: { userId: 'user-1' },
      });
    });
  });

  describe('getSession', () => {
    it('throws not found for a session owned by a different user', async () => {
      prisma.visionAnalysisSession.findUnique.mockResolvedValue({
        id: 'session-1',
        userId: 'someone-else',
      });
      await expect(service.getSession('user-1', 'session-1')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('throws not found for a missing session', async () => {
      prisma.visionAnalysisSession.findUnique.mockResolvedValue(null);
      await expect(service.getSession('user-1', 'missing')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('returns the session when owned by the requesting user', async () => {
      const session = { id: 'session-1', userId: 'user-1', observations: [] };
      prisma.visionAnalysisSession.findUnique.mockResolvedValue(session);
      await expect(service.getSession('user-1', 'session-1')).resolves.toEqual(session);
    });
  });

  describe('deleteSession', () => {
    it("rejects deleting another user's session", async () => {
      prisma.visionAnalysisSession.findUnique.mockResolvedValue({
        id: 'session-1',
        userId: 'someone-else',
      });
      await expect(service.deleteSession('user-1', 'session-1')).rejects.toBeInstanceOf(
        NotFoundException,
      );
      expect(prisma.visionAnalysisSession.delete).not.toHaveBeenCalled();
    });

    it('deletes an owned session', async () => {
      prisma.visionAnalysisSession.findUnique.mockResolvedValue({
        id: 'session-1',
        userId: 'user-1',
      });
      await service.deleteSession('user-1', 'session-1');
      expect(prisma.visionAnalysisSession.delete).toHaveBeenCalledWith({
        where: { id: 'session-1' },
      });
    });
  });
});
