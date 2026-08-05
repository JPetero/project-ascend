import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class WorkoutScheduleDto {
  @ApiPropertyOptional()
  @IsInt()
  @Min(5)
  @Max(240)
  durationMinutes!: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(40)
  preferredTime?: string;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  daysOfWeek?: string[];
}
