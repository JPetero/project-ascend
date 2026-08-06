import { ApiPropertyOptional } from '@nestjs/swagger';
import { ExerciseDifficulty } from '@prisma/client';
import { IsEnum, IsOptional, IsString } from 'class-validator';

export class QueryWorkoutsDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  categorySlug?: string;

  @ApiPropertyOptional({ enum: ExerciseDifficulty })
  @IsOptional()
  @IsEnum(ExerciseDifficulty)
  difficulty?: ExerciseDifficulty;
}
