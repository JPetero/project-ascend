import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsUUID } from 'class-validator';

export class AcceptLegalDocumentDto {
  @ApiProperty()
  @IsUUID()
  legalDocumentId!: string;

  @ApiPropertyOptional({ description: 'Optional region/country metadata, e.g. "PH".' })
  @IsOptional()
  @IsString()
  regionCode?: string;
}
