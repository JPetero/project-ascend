import { ApiPropertyOptional } from '@nestjs/swagger';
import { CommunityPostMediaType, CommunityVisibility } from '@prisma/client';
import {
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  IsUrl,
  IsUUID,
  MaxLength,
  ValidateIf,
} from 'class-validator';

// A VIDEO post with a caption is what the product spec calls a "Reel" —
// see schema.prisma's CommunityPostMediaType comment. There is no
// separate reel DTO/endpoint.
export class CreateCommunityPostDto {
  @ApiPropertyOptional({ enum: CommunityPostMediaType, default: CommunityPostMediaType.TEXT })
  @IsOptional()
  @IsEnum(CommunityPostMediaType)
  mediaType?: CommunityPostMediaType;

  // The id of a MediaAsset already uploaded through the Media Platform
  // (Build Session 8 Part 2) — the preferred path. Required whenever
  // mediaType isn't TEXT and mediaUrl isn't supplied instead.
  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  mediaAssetId?: string;

  // Legacy/external path — an already-hosted URL, kept for content
  // hosted outside Ascend's own storage. Required whenever mediaType
  // isn't TEXT and mediaAssetId isn't supplied instead.
  @ApiPropertyOptional()
  @ValidateIf(
    (o: CreateCommunityPostDto) =>
      o.mediaType != null && o.mediaType !== CommunityPostMediaType.TEXT && !o.mediaAssetId,
  )
  @IsUrl()
  mediaUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(2200)
  caption?: string;

  @ApiPropertyOptional({ enum: CommunityVisibility, default: CommunityVisibility.PUBLIC })
  @IsOptional()
  @IsEnum(CommunityVisibility)
  visibility?: CommunityVisibility;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isTrainerContent?: boolean;
}
