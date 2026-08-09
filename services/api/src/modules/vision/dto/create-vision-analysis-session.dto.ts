import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsDateString,
  IsEnum,
  IsIn,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';

/**
 * Known pose-analysis algorithm versions (Build Session 11 Part 8) — a
 * client claiming an unrecognized version is rejected rather than stored,
 * so a result set can never silently mix data from an algorithm revision
 * the backend doesn't know how to interpret. Add a new entry here (never
 * remove an old one — historical sessions still reference it) whenever
 * `MlKitPoseDetectorAdapter`/the exercise analyzers change in a way that
 * would make results not directly comparable to prior versions.
 */
export const KNOWN_VISION_ANALYSIS_VERSIONS = ['pose-v1'] as const;

export enum VisionExerciseDto {
  BODYWEIGHT_SQUAT = 'BODYWEIGHT_SQUAT',
  BICEPS_CURL = 'BICEPS_CURL',
  SHOULDER_PRESS = 'SHOULDER_PRESS',
}

export enum FormObservationSeverityDto {
  INFO = 'INFO',
  COACHING_CUE = 'COACHING_CUE',
  CHECK_FORM = 'CHECK_FORM',
}

export class CreateVisionFormObservationDto {
  @ApiProperty()
  @IsString()
  @MinLength(1)
  @MaxLength(80)
  type!: string;

  @ApiProperty()
  @IsString()
  @MinLength(1)
  @MaxLength(500)
  message!: string;

  @ApiProperty({ enum: FormObservationSeverityDto })
  @IsEnum(FormObservationSeverityDto)
  severity!: FormObservationSeverityDto;

  @ApiProperty()
  @IsNumber()
  @Min(0)
  @Max(1)
  confidence!: number;

  @ApiProperty()
  @IsDateString()
  occurredAt!: string;
}

export class CreateVisionAnalysisSessionDto {
  @ApiProperty({ enum: VisionExerciseDto })
  @IsEnum(VisionExerciseDto)
  exercise!: VisionExerciseDto;

  @ApiProperty()
  @IsDateString()
  startedAt!: string;

  @ApiProperty()
  @IsDateString()
  completedAt!: string;

  @ApiProperty()
  @IsInt()
  @Min(0)
  autoRepCount!: number;

  @ApiProperty()
  @IsInt()
  @Min(0)
  correctedRepCount!: number;

  @ApiProperty({ enum: KNOWN_VISION_ANALYSIS_VERSIONS })
  @IsString()
  @IsIn(KNOWN_VISION_ANALYSIS_VERSIONS)
  analysisVersion!: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  mediaAssetId?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  workoutSessionId?: string;

  @ApiProperty({ type: [CreateVisionFormObservationDto] })
  @IsArray()
  @ArrayMaxSize(200)
  @ValidateNested({ each: true })
  @Type(() => CreateVisionFormObservationDto)
  observations!: CreateVisionFormObservationDto[];
}
