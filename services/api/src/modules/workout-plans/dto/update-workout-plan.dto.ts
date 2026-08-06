import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsOptional,
  IsString,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { WorkoutPlanExerciseDto } from './workout-plan-exercise.dto';

export class UpdateWorkoutPlanDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(120)
  name?: string;

  /** When provided, replaces the plan's entire exercise list. */
  @ApiPropertyOptional({ type: [WorkoutPlanExerciseDto] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => WorkoutPlanExerciseDto)
  exercises?: WorkoutPlanExerciseDto[];
}
