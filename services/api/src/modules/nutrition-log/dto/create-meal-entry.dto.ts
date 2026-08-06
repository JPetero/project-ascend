import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { MealType } from '@prisma/client';
import {
  IsBoolean,
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateMealEntryDto {
  @ApiProperty()
  @IsString()
  foodId!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  foodServingId?: string;

  @ApiProperty({ enum: MealType })
  @IsEnum(MealType)
  mealType!: MealType;

  @ApiProperty({ description: 'Date this entry is logged against, YYYY-MM-DD.' })
  @IsDateString()
  date!: string;

  @ApiProperty({
    description:
      "Number of servings (of the selected serving option, or the food's reference serving).",
  })
  @IsNumber()
  @Min(0.01)
  @Max(1000)
  quantity!: number;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  loggedByGrams?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0.1)
  @Max(10000)
  gramsLogged?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(280)
  notes?: string;

  @ApiPropertyOptional({
    description:
      'Client-generated key identifying this exact log attempt, so a network retry never creates a duplicate entry.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  idempotencyKey?: string;
}
