import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsPositive,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';

// Deliberately narrow — sets/duration/exercises/PRs/distance only. Never
// add a field here for weight, BMI, a health condition, nutrition, heart
// rate, or a wearable metric; see JointWorkoutSharedResult's schema
// comment for why.
export class SubmitJointWorkoutProgressDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(120)
  exerciseName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  setsCompleted?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @IsPositive()
  durationSeconds?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsPositive()
  distanceMeters?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isPersonalRecord?: boolean;
}
