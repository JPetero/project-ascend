import { Injectable, NotFoundException } from '@nestjs/common';
import { Equipment, Prisma, Profile, WorkoutSchedule } from '@prisma/client';
import { isPrismaNotFoundError } from '../../common/prisma/prisma-errors.util';
import { PrismaService } from '../../prisma/prisma.service';
import { UpdateOnboardingDto } from './dto/update-onboarding.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class ProfilesService {
  constructor(private readonly prisma: PrismaService) {}

  async getProfile(userId: string) {
    // A single query via the User relation, rather than three separate
    // round trips for profile/equipment/schedule.
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { profile: true, equipment: true, workoutSchedule: true },
    });

    if (!user?.profile) {
      throw new NotFoundException('Profile not found.');
    }

    return this.serialize(user.profile, user.equipment, user.workoutSchedule);
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    await this.updateProfileRow(userId, this.toProfileUpdateData(dto));
    return this.getProfile(userId);
  }

  async updateOnboarding(userId: string, dto: UpdateOnboardingDto) {
    const { onboardingStep, onboardingCompleted, equipment, workoutSchedule, ...profileFields } =
      dto;

    await this.prisma.$transaction(async (tx) => {
      await this.updateProfileRow(
        userId,
        {
          ...this.toProfileUpdateData(profileFields),
          ...(onboardingStep !== undefined ? { onboardingStep } : {}),
          ...(onboardingCompleted !== undefined ? { onboardingCompleted } : {}),
        },
        tx,
      );

      if (equipment) {
        await tx.equipment.deleteMany({ where: { userId } });
        if (equipment.length > 0) {
          await tx.equipment.createMany({
            data: equipment.map((item) => ({
              userId,
              type: item.type,
              customName: item.customName,
            })),
          });
        }
      }

      if (workoutSchedule) {
        await tx.workoutSchedule.upsert({
          where: { userId },
          create: {
            userId,
            durationMinutes: workoutSchedule.durationMinutes,
            preferredTime: workoutSchedule.preferredTime,
            daysOfWeek: workoutSchedule.daysOfWeek ?? [],
          },
          update: {
            durationMinutes: workoutSchedule.durationMinutes,
            preferredTime: workoutSchedule.preferredTime,
            daysOfWeek: workoutSchedule.daysOfWeek ?? [],
          },
        });
      }
    });

    return this.getProfile(userId);
  }

  /**
   * Updates the profile row directly and turns Prisma's "row didn't exist"
   * error into a 404, instead of a separate existence check before every
   * write.
   */
  private async updateProfileRow(
    userId: string,
    data: Prisma.ProfileUpdateInput,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ): Promise<void> {
    try {
      await tx.profile.update({ where: { userId }, data });
    } catch (error) {
      if (isPrismaNotFoundError(error)) {
        throw new NotFoundException('Profile not found.');
      }
      throw error;
    }
  }

  private toProfileUpdateData(dto: UpdateProfileDto): Prisma.ProfileUpdateInput {
    return {
      ...(dto.firstName !== undefined ? { firstName: dto.firstName } : {}),
      ...(dto.dateOfBirth !== undefined ? { dateOfBirth: new Date(dto.dateOfBirth) } : {}),
      ...(dto.countryCode !== undefined ? { countryCode: dto.countryCode } : {}),
      ...(dto.languageCode !== undefined ? { languageCode: dto.languageCode } : {}),
      ...(dto.timezone !== undefined ? { timezone: dto.timezone } : {}),
      ...(dto.unitSystem !== undefined ? { unitSystem: dto.unitSystem } : {}),
      ...(dto.sexForCalculations !== undefined
        ? { sexForCalculations: dto.sexForCalculations }
        : {}),
      ...(dto.heightCm !== undefined ? { heightCm: dto.heightCm } : {}),
      ...(dto.weightKg !== undefined ? { weightKg: dto.weightKg } : {}),
      ...(dto.primaryGoal !== undefined ? { primaryGoal: dto.primaryGoal } : {}),
      ...(dto.experienceLevel !== undefined ? { experienceLevel: dto.experienceLevel } : {}),
    };
  }

  private serialize(
    profile: Profile,
    equipment: Equipment[],
    workoutSchedule: WorkoutSchedule | null,
  ) {
    return {
      ...profile,
      equipment,
      workoutSchedule,
    };
  }
}
