import { ApiPropertyOptional, ApiProperty } from '@nestjs/swagger';
import { IsDateString, IsInt, IsOptional, IsString, IsUUID, Max, Min } from 'class-validator';

export class CreateTrainerGroupScheduledSessionDto {
  @ApiProperty()
  @IsDateString()
  scheduledAt!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  title?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(5)
  @Max(600)
  durationMinutes?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  location?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  videoLink?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({
    description:
      'A Workout Plan the host owns, shown as a preview to attendees. Purely a reference — ' +
      'starting the real-time session at meeting time reuses the existing Joint Workout Session ' +
      'flow (POST /joint-workout-sessions with trainerGroupId), not a new implementation here.',
  })
  @IsOptional()
  @IsUUID('4')
  workoutPlanId?: string;
}
