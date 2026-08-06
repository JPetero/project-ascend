import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { MealType } from '@prisma/client';
import { IsDateString, IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

export class LogSavedMealDto {
  @ApiProperty({ enum: MealType })
  @IsEnum(MealType)
  mealType!: MealType;

  @ApiProperty({ description: 'Date to log against, YYYY-MM-DD.' })
  @IsDateString()
  date!: string;

  @ApiPropertyOptional({
    description:
      'Client-generated key identifying this exact log attempt, so a network retry never creates duplicate entries.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  idempotencyKey?: string;
}
