import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { GalleryPoseTag } from '@prisma/client';
import { IsDateString, IsEnum, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class AddGalleryMediaDto {
  // A MediaAsset the caller already owns and has finished uploading
  // through the Media Platform — this endpoint never accepts raw bytes
  // or a URL directly (see media.module.ts for the one upload path
  // every feature shares).
  @ApiProperty()
  @IsUUID()
  mediaAssetId!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(280)
  note?: string;

  // Only meaningful for a PROGRESS-category album, but not enforced —
  // nothing stops tagging a pose on any photo.
  @ApiPropertyOptional({ enum: GalleryPoseTag })
  @IsOptional()
  @IsEnum(GalleryPoseTag)
  poseTag?: GalleryPoseTag;

  // A user-typed note, e.g. "72kg" — never a value Ascend measures,
  // infers, or calculates. See wellness-ethics-bible.md.
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(40)
  weightNote?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  capturedAt?: string;
}
