import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { AppCapability } from '../../common/entitlements/capability.util';
import { CapabilityService } from '../../common/entitlements/capability.service';
import {
  PaginationQueryDto,
  paginationArgs,
  paginationMeta,
} from '../../common/pagination/pagination-query.dto';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateVisionAnalysisSessionDto } from './dto/create-vision-analysis-session.dto';

/**
 * Private, per-user history for live Vision pose-analysis sessions
 * (Build Session 10 Part 6) — Form Coach/Rep Counter results the app
 * saves on the user's behalf once a session ends. Gated on
 * `AppCapability.VISION_ACCESS` (the same Premium gate the rest of the
 * Vision shell uses) since these rows only ever exist because a Premium
 * live session produced them.
 */
@Injectable()
export class VisionService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly capabilityService: CapabilityService,
  ) {}

  private async assertVisionAccess(userId: string) {
    const hasAccess = await this.capabilityService.hasCapabilityForUser(
      userId,
      AppCapability.VISION_ACCESS,
    );
    if (!hasAccess) {
      throw new ForbiddenException('Vision requires Premium.');
    }
  }

  async createSession(userId: string, dto: CreateVisionAnalysisSessionDto) {
    await this.assertVisionAccess(userId);

    const session = await this.prisma.visionAnalysisSession.create({
      data: {
        userId,
        exercise: dto.exercise,
        startedAt: new Date(dto.startedAt),
        completedAt: new Date(dto.completedAt),
        autoRepCount: dto.autoRepCount,
        correctedRepCount: dto.correctedRepCount,
        analysisVersion: dto.analysisVersion,
        mediaAssetId: dto.mediaAssetId,
        workoutSessionId: dto.workoutSessionId,
        observations: {
          create: dto.observations.map((observation) => ({
            type: observation.type,
            message: observation.message,
            severity: observation.severity,
            confidence: observation.confidence,
            occurredAt: new Date(observation.occurredAt),
          })),
        },
      },
      include: { observations: true },
    });

    return session;
  }

  async listSessions(userId: string, query: PaginationQueryDto) {
    await this.assertVisionAccess(userId);

    const [sessions, total] = await Promise.all([
      this.prisma.visionAnalysisSession.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        include: { observations: true },
        ...paginationArgs(query),
      }),
      this.prisma.visionAnalysisSession.count({ where: { userId } }),
    ]);

    return { data: sessions, meta: paginationMeta(query, total) };
  }

  async getSession(userId: string, id: string) {
    await this.assertVisionAccess(userId);
    const session = await this.findOwnedOrThrow(userId, id);
    return session;
  }

  async deleteSession(userId: string, id: string): Promise<void> {
    await this.assertVisionAccess(userId);
    await this.findOwnedOrThrow(userId, id);
    await this.prisma.visionAnalysisSession.delete({ where: { id } });
  }

  private async findOwnedOrThrow(userId: string, id: string) {
    const session = await this.prisma.visionAnalysisSession.findUnique({
      where: { id },
      include: { observations: true },
    });
    if (!session || session.userId !== userId) {
      throw new NotFoundException('Vision analysis session not found.');
    }
    return session;
  }
}
