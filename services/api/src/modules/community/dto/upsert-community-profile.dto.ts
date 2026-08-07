import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString, IsUrl, MaxLength } from 'class-validator';

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
}
