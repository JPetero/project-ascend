import { ApiPropertyOptional, ApiProperty } from '@nestjs/swagger';
import { CommunityProfileVisibility } from '@prisma/client';
import { IsBoolean, IsEnum, IsOptional, IsString, IsUrl, MaxLength } from 'class-validator';

export class UpsertCommunityProfileDto {
  @ApiProperty()
  @IsString()
  @MaxLength(60)
  displayName!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(280)
  bio?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUrl()
  avatarUrl?: string;

  // Self-declared, not verified — a real "verified trainer" program is
  // future work (see the Ascend Promote / trainer-groups roadmap
  // entries). This only controls whether a "Trainer" badge shows.
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isTrainer?: boolean;

  // Free from day one — see CommunityProfileVisibility's schema comment.
  // Setting the avatar/cover MediaAsset is a separate action (Gallery's
  // set-avatar/set-cover endpoints), not a field here.
  @ApiPropertyOptional({ enum: CommunityProfileVisibility })
  @IsOptional()
  @IsEnum(CommunityProfileVisibility)
  visibility?: CommunityProfileVisibility;
}
