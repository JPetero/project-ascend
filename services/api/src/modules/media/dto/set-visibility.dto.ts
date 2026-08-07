import { ApiProperty } from '@nestjs/swagger';
import { MediaVisibility } from '@prisma/client';
import { IsEnum } from 'class-validator';

export class SetVisibilityDto {
  @ApiProperty({ enum: MediaVisibility })
  @IsEnum(MediaVisibility)
  visibility!: MediaVisibility;
}
