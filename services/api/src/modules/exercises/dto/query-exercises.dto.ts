import { ApiPropertyOptional } from '@nestjs/swagger';
import { ExerciseDifficulty } from '@prisma/client';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

export class QueryExercisesDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  categorySlug?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  muscleSlug?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  equipmentSlug?: string;

  @ApiPropertyOptional({ enum: ExerciseDifficulty })
  @IsOptional()
  @IsEnum(ExerciseDifficulty)
  difficulty?: ExerciseDifficulty;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(100)
  search?: string;
}
