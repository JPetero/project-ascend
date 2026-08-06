import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsOptional,
  IsString,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { SavedMealItemDto } from './create-saved-meal.dto';

/**
 * Editing a saved meal replaces its name and/or its full item list — there
 * is no per-item PATCH, matching how `updateCustom` on `FoodsService`
 * replaces the whole `servings` list rather than diffing it.
 */
export class UpdateSavedMealDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(80)
  name?: string;

  @ApiPropertyOptional({ type: [SavedMealItemDto] })
  @IsOptional()
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => SavedMealItemDto)
  items?: SavedMealItemDto[];
}
