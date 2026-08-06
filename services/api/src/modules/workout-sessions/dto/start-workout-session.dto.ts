import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class StartWorkoutSessionDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  workoutPlanId?: string;
}
