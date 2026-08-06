import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsInt, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

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
}
