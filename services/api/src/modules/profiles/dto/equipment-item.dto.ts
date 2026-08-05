import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class EquipmentItemDto {
  @ApiPropertyOptional()
  @IsString()
  @MaxLength(80)
  type!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(80)
  customName?: string;
}
