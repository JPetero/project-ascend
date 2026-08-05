import { Injectable, NotFoundException } from '@nestjs/common';
import { Equipment, Prisma, Profile, WorkoutSchedule } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { UpdateOnboardingDto } from './dto/update-onboarding.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class ProfilesService {
  constructor(private readonly prisma: PrismaService) {}

  async getProfile(userId: string) {
    const profile = await this.prisma.profile.findUnique({ where: { userId } });
    if (!profile) {
      throw new NotFoundException('Profile not found.');
    }

    const [equipment, workoutSchedule] = await Promise.all([
      this.prisma.equipment.findMany({ where: { userId } }),
      this.prisma.workoutSchedule.findUnique({ where: { userId } }),
    ]);

    return this.serialize(profile, equipment, workoutSchedule);
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    await this.ensureProfileExists(userId);
    await this.prisma.profile.update({ where: { userId }, data: this.toProfileUpdateData(dto) });
    return this.getProfile(userId);
  }

  async updateOnboarding(userId: string, dto: UpdateOnboardingDto) {
    await this.ensureProfileExists(userId);

    const { onboardingStep, onboardingCompleted, equipment, workoutSchedule, ...profileFields } =
      dto;

    await this.prisma.$transaction(async (tx) => {
      await tx.profile.update({
        where: { userId },
        data: {
          ...this.toProfileUpdateData(profileFields),
          ...(onboardingStep !== undefined ? { onboardingStep } : {}),
          ...(onboardingCompleted !== undefined ? { onboardingCompleted } : {}),
        },
      });

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

  private async ensureProfileExists(userId: string): Promise<void> {
    const exists = await this.prisma.profile.findUnique({
      where: { userId },
      select: { id: true },
    });
    if (!exists) {
      throw new NotFoundException('Profile not found.');
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
