import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class StartWorkoutSessionDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  workoutPlanId?: string;

  @ApiPropertyOptional({
    description:
      'Client-generated key identifying this exact start attempt, so a network retry never creates a second session.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  idempotencyKey?: string;
}
