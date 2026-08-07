import { ApiPropertyOptional } from '@nestjs/swagger';
import { CommunityPostMediaType, CommunityVisibility } from '@prisma/client';
import {
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
  IsUrl,
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

  // Required whenever mediaType isn't TEXT — this session has no media
  // upload/transcoding pipeline, so the client is responsible for
  // producing a URL (e.g. from its own object storage) before creating
  // the post. See packages/docs/build-session-7.md Part 4.
  @ApiPropertyOptional()
  @ValidateIf(
    (o: CreateCommunityPostDto) =>
      o.mediaType != null && o.mediaType !== CommunityPostMediaType.TEXT,
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
