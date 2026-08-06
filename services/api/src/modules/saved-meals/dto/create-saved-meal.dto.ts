import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

export class SavedMealItemDto {
  @ApiProperty()
  @IsString()
  foodId!: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  foodServingId?: string;

  @ApiProperty()
  @IsNumber()
  @Min(0.01)
  @Max(1000)
  quantity!: number;
}

export class CreateSavedMealDto {
  @ApiProperty()
  @IsString()
  @MaxLength(80)
  name!: string;

  @ApiProperty({ type: [SavedMealItemDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => SavedMealItemDto)
  items!: SavedMealItemDto[];
}
