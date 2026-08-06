import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { CardioActivityType, CardioSessionSource } from '@prisma/client';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsDateString,
  IsEnum,
  IsInt,
  IsOptional,
  IsPositive,
  IsString,
  Max,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { RoutePointDto } from './route-point.dto';

/**
 * Manual/summary or live-GPS-tracked cardio logging (see
 * packages/docs/product/user-scenario-bible.md Scenario 12 and
 * schema.prisma's CardioSession comment). `distanceMeters` stays absent
 * unless the user actually entered/recorded one; a `regionLabel` alone
 * never implies a measured route. `routePoints`, when present, is capped
 * well under the default request body size limit — a live-tracked
 * session's point count is bounded by battery-conscious client-side
 * sampling (see the Flutter live-tracking controller), so 2000 points
 * comfortably covers several hours of typical sampling intervals.
 */
export class CreateCardioSessionDto {
  @ApiProperty({ enum: CardioActivityType })
  @IsEnum(CardioActivityType)
  activityType!: CardioActivityType;

  @ApiPropertyOptional({ enum: CardioSessionSource, default: CardioSessionSource.MANUAL })
  @IsOptional()
  @IsEnum(CardioSessionSource)
  source?: CardioSessionSource;

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

  @ApiPropertyOptional({
    type: [RoutePointDto],
    description:
      "A LIVE_GPS session's recorded route. Ignored (never stored) when hideRoute is true.",
  })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(2000)
  @ValidateNested({ each: true })
  @Type(() => RoutePointDto)
  routePoints?: RoutePointDto[];

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
