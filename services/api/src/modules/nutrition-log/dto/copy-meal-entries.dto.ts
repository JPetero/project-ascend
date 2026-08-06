import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { MealType } from '@prisma/client';
import { IsDateString, IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

/**
 * Copies either every entry logged on `sourceDate` (when `mealType` is
 * omitted) or just one meal slot's entries, onto `targetDate`. Snapshot
 * values are copied verbatim from the source entries rather than
 * recomputed — nothing about the underlying food changed.
 */
export class CopyMealEntriesDto {
  @ApiProperty()
  @IsDateString()
  sourceDate!: string;

  @ApiProperty()
  @IsDateString()
  targetDate!: string;

  @ApiPropertyOptional({ enum: MealType })
  @IsOptional()
  @IsEnum(MealType)
  mealType?: MealType;

  @ApiPropertyOptional({
    description:
      'Client-generated key identifying this exact copy attempt, so a network retry never duplicates the copied entries.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  idempotencyKey?: string;
}
