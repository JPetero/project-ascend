import { Injectable } from '@nestjs/common';
import { SexForCalculations } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { UpsertMacroTargetDto } from './dto/upsert-macro-target.dto';

/** Conservative fallbacks used only when a profile is missing the input —
 * always documented to the user as part of an estimate, never presented
 * as measured. */
const DEFAULT_WEIGHT_KG = 65;
const DEFAULT_HEIGHT_CM = 165;
const DEFAULT_AGE_YEARS = 30;

/** Fixed "lightly active" multiplier — deliberately conservative so the
 * default never overestimates a sedentary user's needs. */
const ACTIVITY_MULTIPLIER = 1.375;

/** Safety floor: this app will never suggest a default under this, no
 * matter how aggressive the computed deficit would otherwise be. */
const MIN_SAFE_CALORIES = 1200;

const GOAL_ADJUSTMENT: Record<string, number> = {
  LOSE_WEIGHT: -0.15,
  BUILD_STRENGTH: 0.1,
};

function round(value: number): number {
  return Math.round(value);
}

@Injectable()
export class MacroTargetsService {
  constructor(private readonly prisma: PrismaService) {}

  async get(userId: string) {
    const existing = await this.prisma.macroTarget.findUnique({ where: { userId } });
    if (existing) {
      return this.serialize(existing);
    }

    const estimate = await this.computeSafeDefault(userId);
    const created = await this.prisma.macroTarget.upsert({
      where: { userId },
      create: { userId, ...estimate, isEstimatedDefault: true },
      update: {},
    });
    return this.serialize(created);
  }

  async upsert(userId: string, dto: UpsertMacroTargetDto) {
    const updated = await this.prisma.macroTarget.upsert({
      where: { userId },
      create: {
        userId,
        calorieTarget: dto.calorieTarget,
        proteinGramsTarget: dto.proteinGramsTarget,
        carbGramsTarget: dto.carbGramsTarget,
        fatGramsTarget: dto.fatGramsTarget,
        fiberGramsTarget: dto.fiberGramsTarget,
        isEstimatedDefault: false,
      },
      update: {
        calorieTarget: dto.calorieTarget,
        proteinGramsTarget: dto.proteinGramsTarget,
        carbGramsTarget: dto.carbGramsTarget,
        fatGramsTarget: dto.fatGramsTarget,
        fiberGramsTarget: dto.fiberGramsTarget,
        isEstimatedDefault: false,
      },
    });
    return this.serialize(updated);
  }

  /**
   * A deliberately simple, bounded estimate (Mifflin-St Jeor BMR × a fixed
   * conservative activity factor × a small, capped goal adjustment). It is
   * NOT sex-only-based — sex is one input alongside weight, height, and
   * age — and it never proposes an extreme deficit/surplus or a calorie
   * floor below `MIN_SAFE_CALORIES`. This is a rough starting estimate,
   * always labelled as such via `isEstimatedDefault`, and is not a medical
   * or clinical recommendation. Users who are pregnant, managing an eating
   * disorder, kidney disease, diabetes, or any other condition where
   * nutrition needs are not typical should set their own targets with
   * guidance from a qualified professional rather than relying on this
   * default.
   */
  private async computeSafeDefault(userId: string) {
    const profile = await this.prisma.profile.findUnique({ where: { userId } });

    const weightKg = profile?.weightKg ?? DEFAULT_WEIGHT_KG;
    const heightCm = profile?.heightCm ?? DEFAULT_HEIGHT_CM;
    const age = profile?.dateOfBirth ? this.ageInYears(profile.dateOfBirth) : DEFAULT_AGE_YEARS;
    const sex = profile?.sexForCalculations ?? SexForCalculations.UNSPECIFIED;

    const sexOffset =
      sex === SexForCalculations.MALE ? 5 : sex === SexForCalculations.FEMALE ? -161 : -78;
    const bmr = 10 * weightKg + 6.25 * heightCm - 5 * age + sexOffset;
    const tdee = bmr * ACTIVITY_MULTIPLIER;

    const goalAdjustment = profile?.primaryGoal ? (GOAL_ADJUSTMENT[profile.primaryGoal] ?? 0) : 0;
    const calorieTarget = Math.max(MIN_SAFE_CALORIES, round(tdee * (1 + goalAdjustment)));

    const proteinGramsTarget = round(weightKg * 1.6);
    const fatGramsTarget = round((calorieTarget * 0.25) / 9);
    const proteinAndFatCalories = proteinGramsTarget * 4 + fatGramsTarget * 9;
    const carbGramsTarget = Math.max(0, round((calorieTarget - proteinAndFatCalories) / 4));
    const fiberGramsTarget = round((calorieTarget / 1000) * 14);

    return {
      calorieTarget,
      proteinGramsTarget,
      carbGramsTarget,
      fatGramsTarget,
      fiberGramsTarget,
    };
  }

  private ageInYears(dateOfBirth: Date): number {
    const now = new Date();
    let age = now.getUTCFullYear() - dateOfBirth.getUTCFullYear();
    const hasHadBirthdayThisYear =
      now.getUTCMonth() > dateOfBirth.getUTCMonth() ||
      (now.getUTCMonth() === dateOfBirth.getUTCMonth() &&
        now.getUTCDate() >= dateOfBirth.getUTCDate());
    if (!hasHadBirthdayThisYear) {
      age -= 1;
    }
    return Math.max(13, age);
  }

  private serialize(target: {
    calorieTarget: number;
    proteinGramsTarget: number;
    carbGramsTarget: number;
    fatGramsTarget: number;
    fiberGramsTarget: number | null;
    isEstimatedDefault: boolean;
    updatedAt: Date;
  }) {
    return {
      calorieTarget: target.calorieTarget,
      proteinGramsTarget: target.proteinGramsTarget,
      carbGramsTarget: target.carbGramsTarget,
      fatGramsTarget: target.fatGramsTarget,
      fiberGramsTarget: target.fiberGramsTarget,
      isEstimatedDefault: target.isEstimatedDefault,
      disclaimer:
        'This is a general estimate, not medical advice. If you are pregnant, managing an eating disorder, kidney disease, diabetes, or another condition affecting your nutrition needs, please set targets with guidance from a qualified professional.',
      updatedAt: target.updatedAt,
    };
  }
}
