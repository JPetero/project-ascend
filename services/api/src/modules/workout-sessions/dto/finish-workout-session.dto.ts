import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, Max, Min } from 'class-validator';

export class FinishWorkoutSessionDto {
  /**
   * Optional whole-session difficulty rating, same 1-10 scale as per-set
   * RPE — a coarser alternative for a user who doesn't want to rate every
   * set individually.
   */
  @ApiPropertyOptional({ description: 'Optional whole-session difficulty rating, 1-10.' })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(10)
  difficultyRating?: number;
}
