import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class SubstituteExerciseDto {
  @ApiProperty({ description: 'The exercise currently prescribed that is being replaced.' })
  @IsString()
  originalExerciseId!: string;

  @ApiProperty({ description: 'The replacement exercise to log remaining sets against.' })
  @IsString()
  substituteExerciseId!: string;

  @ApiPropertyOptional({
    description:
      'Client-generated key identifying this exact substitution attempt, so a network retry never creates a duplicate or conflicting substitution.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  idempotencyKey?: string;
}
