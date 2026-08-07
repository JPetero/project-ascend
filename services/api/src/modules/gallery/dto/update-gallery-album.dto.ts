import { ApiPropertyOptional } from '@nestjs/swagger';
import { GalleryCategory, GalleryVisibility } from '@prisma/client';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateGalleryAlbumDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(60)
  name?: string;

  @ApiPropertyOptional({ enum: GalleryCategory })
  @IsOptional()
  @IsEnum(GalleryCategory)
  category?: GalleryCategory;

  @ApiPropertyOptional({ enum: GalleryVisibility })
  @IsOptional()
  @IsEnum(GalleryVisibility)
  visibility?: GalleryVisibility;
}
