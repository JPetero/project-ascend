import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsDateString,
  IsEnum,
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

  @ApiProperty()
  @IsString()
  @MinLength(1)
  @MaxLength(40)
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
