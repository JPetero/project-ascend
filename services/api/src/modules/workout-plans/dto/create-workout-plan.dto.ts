import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsOptional,
  IsString,
  MaxLength,
  ValidateIf,
  ValidateNested,
} from 'class-validator';
import { WorkoutPlanExerciseDto } from './workout-plan-exercise.dto';

/**
 * Either `workoutId` (start a plan from a catalog Workout, copying its
 * exercises in) or `exercises` (a custom, from-scratch plan) should be
 * provided. Both are optional at the type level so a plan can also be
 * created empty and built up via PATCH.
 */
export class CreateWorkoutPlanDto {
  @ApiProperty()
  @IsString()
  @MaxLength(120)
  name!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  workoutId?: string;

  @ApiPropertyOptional({ type: [WorkoutPlanExerciseDto] })
  @ValidateIf((dto: CreateWorkoutPlanDto) => dto.workoutId === undefined)
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => WorkoutPlanExerciseDto)
  exercises?: WorkoutPlanExerciseDto[];
}
