import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

/**
 * `setNumber` is deliberately not client-supplied — the server assigns the
 * next number for (session, exercise) so an offline client never has to
 * track or reconcile numbering itself; it only has to say "log a set for
 * this exercise."
 */
export class LogSetDto {
  @ApiProperty()
  @IsString()
  exerciseId!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(200)
  reps?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(500)
  weightKg?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(21600)
  durationSeconds?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(200000)
  distanceMeters?: number;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isWarmup?: boolean;

  /**
   * Rate of Perceived Exertion — a subjective 1-10 self-rating of how hard
   * the set felt, half-point increments allowed (e.g. 7.5). Optional and
   * never treated as a medical measurement; see ProgressionService for how
   * it's used (to temper, never block, a load increase).
   */
  @ApiPropertyOptional({
    description: 'Optional Rate of Perceived Exertion, 1-10 (half-point increments allowed).',
  })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(10)
  rpe?: number;

  @ApiPropertyOptional({
    description:
      'Client-generated key identifying this exact set-logging attempt, so a network retry never creates a duplicate set.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  idempotencyKey?: string;
}
