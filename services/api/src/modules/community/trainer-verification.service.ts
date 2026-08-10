import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ApplyTrainerVerificationDto } from './dto/apply-trainer-verification.dto';

/**
 * Real trainer verification — Build Session 12 Part 25-26. Distinct
 * from CommunityProfile.isTrainer (a self-declared, unreviewed badge —
 * see its own schema comment): this is an application-and-admin-review
 * flow, same one-row-per-user, re-appliable-after-rejection shape as
 * SubscriptionsService's affordability eligibility. The member-facing
 * half lives here; the admin review half lives directly on AdminService
 * (see listTrainerVerificationApplications/decideTrainerVerification),
 * matching how affordability eligibility review already splits between
 * SubscriptionsService and AdminService rather than a shared service.
 */
@Injectable()
export class TrainerVerificationService {
  constructor(private readonly prisma: PrismaService) {}

  async apply(userId: string, dto: ApplyTrainerVerificationDto) {
    const application = await this.prisma.trainerVerificationApplication.upsert({
      where: { userId },
      update: { credentials: dto.credentials, status: 'PENDING', reviewedAt: null },
      create: { userId, credentials: dto.credentials },
    });
    return { status: application.status, submittedAt: application.submittedAt };
  }

  async getMine(userId: string) {
    const application = await this.prisma.trainerVerificationApplication.findUnique({
      where: { userId },
    });
    return application
      ? { status: application.status, submittedAt: application.submittedAt }
      : null;
  }
}
