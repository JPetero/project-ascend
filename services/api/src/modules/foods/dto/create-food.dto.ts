import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

import { FoodServingDto } from './food-serving.dto';

/**
 * Creates a user-owned custom food (`sourceType: USER`). There is no way
 * for a client to create a `SEED` food — those only come from
 * `prisma/seed.ts` — so ownership and editability are structurally tied
 * together from creation.
 */
export class CreateFoodDto {
  @ApiProperty()
  @IsString()
  @MaxLength(120)
  name!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(120)
  alternateName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(80)
  brand?: string;

  @ApiProperty()
  @IsString()
  @MaxLength(60)
  servingDescription!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(5000)
  servingGrams?: number;

  @ApiProperty()
  @IsNumber()
  @Min(0)
  @Max(10000)
  caloriesPerServing!: number;

  @ApiProperty()
  @IsNumber()
  @Min(0)
  @Max(1000)
  proteinGramsPerServing!: number;

  @ApiProperty()
  @IsNumber()
  @Min(0)
  @Max(1000)
  carbGramsPerServing!: number;

  @ApiProperty()
  @IsNumber()
  @Min(0)
  @Max(1000)
  fatGramsPerServing!: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(200)
  fiberGramsPerServing?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(20000)
  sodiumMgPerServing?: number;

  @ApiPropertyOptional({
    default: true,
    description:
      'Whether these values are an approximation rather than a lab-verified figure — true for essentially every custom food a user enters by hand.',
  })
  @IsOptional()
  @IsBoolean()
  isEstimated?: boolean;

  @ApiPropertyOptional({ type: [FoodServingDto] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @ValidateNested({ each: true })
  @Type(() => FoodServingDto)
  servings?: FoodServingDto[];

  @ApiPropertyOptional({
    description:
      'Client-generated key identifying this exact create attempt, so a network retry never creates a duplicate custom food.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  idempotencyKey?: string;
}
