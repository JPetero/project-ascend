import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { GalleryCategory, GalleryVisibility } from '@prisma/client';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateGalleryAlbumDto {
  @ApiProperty()
  @IsString()
  @MaxLength(60)
  name!: string;

  @ApiPropertyOptional({ enum: GalleryCategory, default: GalleryCategory.PRIVATE })
  @IsOptional()
  @IsEnum(GalleryCategory)
  category?: GalleryCategory;

  // Private by default — see GalleryAlbum's schema comment.
  @ApiPropertyOptional({ enum: GalleryVisibility, default: GalleryVisibility.PRIVATE })
  @IsOptional()
  @IsEnum(GalleryVisibility)
  visibility?: GalleryVisibility;
}
