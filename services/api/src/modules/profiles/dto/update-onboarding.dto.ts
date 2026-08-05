import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsArray, IsBoolean, IsInt, IsOptional, Max, Min, ValidateNested } from 'class-validator';
import { UpdateProfileDto } from './update-profile.dto';
import { EquipmentItemDto } from './equipment-item.dto';
import { WorkoutScheduleDto } from './workout-schedule.dto';

/**
 * A single endpoint that lets the mobile onboarding flow save its
 * current step/progress and (optionally) the profile, equipment, and
 * schedule fields collected on that step.
 */
export class UpdateOnboardingDto extends UpdateProfileDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(9)
  onboardingStep?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  onboardingCompleted?: boolean;

  @ApiPropertyOptional({ type: [EquipmentItemDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => EquipmentItemDto)
  equipment?: EquipmentItemDto[];

  @ApiPropertyOptional({ type: WorkoutScheduleDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => WorkoutScheduleDto)
  workoutSchedule?: WorkoutScheduleDto;
}
