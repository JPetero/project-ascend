import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { CardioActivityType } from '@prisma/client';
import {
  IsBoolean,
  IsDateString,
  IsEnum,
  IsInt,
  IsOptional,
  IsPositive,
  IsString,
  Max,
  MaxLength,
} from 'class-validator';

/**
 * Manual/summary cardio logging — not live GPS tracking (see
 * packages/docs/product/user-scenario-bible.md Scenario 12 and
 * schema.prisma's CardioSession comment for why). `distanceMeters` stays
 * absent unless the user actually entered a distance; a `regionLabel`
 * alone never implies a measured route.
 */
export class CreateCardioSessionDto {
  @ApiProperty({ enum: CardioActivityType })
  @IsEnum(CardioActivityType)
  activityType!: CardioActivityType;

  @ApiProperty({ description: 'ISO 8601 timestamp the session started.' })
  @IsDateString()
  startedAt!: string;

  @ApiProperty()
  @IsInt()
  @IsPositive()
  @Max(86400)
  durationSeconds!: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsPositive()
  @Max(500_000)
  distanceMeters?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsPositive()
  @Max(20_000)
  elevationGainMeters?: number;

  @ApiPropertyOptional({ description: 'A clearly-labeled estimate, never precise.' })
  @IsOptional()
  @IsPositive()
  @Max(10_000)
  estimatedCalories?: number;

  @ApiPropertyOptional({
    description: 'A coarse region tag, e.g. "Quezon City" — never coordinates.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  regionLabel?: string;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  hideRoute?: boolean;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  hideStartLocation?: boolean;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  hideEndLocation?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  idempotencyKey?: string;
}
