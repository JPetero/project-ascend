import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsNumber, IsOptional, IsString, Min, MaxLength } from 'class-validator';

export class FoodServingDto {
  @ApiProperty()
  @IsString()
  @MaxLength(60)
  label!: string;

  @ApiPropertyOptional({ description: 'Grams this serving option resolves to, if convertible.' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  grams?: number;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}
