import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  CoachingStyle,
  Companion,
  CommunityVisibility,
  CompanionMode,
  GalleryVisibility,
  ThemeMode,
} from '@prisma/client';
import { IsBoolean, IsEnum, IsInt, IsNumber, IsOptional, Max, Min } from 'class-validator';

export class UpdatePreferencesDto {
  @ApiPropertyOptional({ enum: Companion })
  @IsOptional()
  @IsEnum(Companion)
  companion?: Companion;

  @ApiPropertyOptional({ enum: CompanionMode })
  @IsOptional()
  @IsEnum(CompanionMode)
  companionMode?: CompanionMode;

  // Deliberately independent of `companion` — see
  // packages/docs/product/atlas-nova-bible.md. Neither the frontend nor this
  // DTO ties a coaching style to a companion or to sex/gender.
  @ApiPropertyOptional({ enum: CoachingStyle })
  @IsOptional()
  @IsEnum(CoachingStyle)
  coachingStyle?: CoachingStyle;

  @ApiPropertyOptional({ minimum: 1, maximum: 5 })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(5)
  toneIntensity?: number;

  @ApiPropertyOptional({ enum: ThemeMode })
  @IsOptional()
  @IsEnum(ThemeMode)
  themeMode?: ThemeMode;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  reducedMotion?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  notificationsEnabled?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  aiMemoryEnabled?: boolean;

  // Build Session 12 Part 8 — deliberately separate from
  // `aiMemoryEnabled`; see Preference.conversationHistoryEnabled's doc
  // comment in schema.prisma.
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  conversationHistoryEnabled?: boolean;

  // Build Session 12 Part 12-14 (Accessibility Center) — see
  // Preference.textScale's schema comment.
  @ApiPropertyOptional({ minimum: 0.85, maximum: 1.5 })
  @IsOptional()
  @IsNumber()
  @Min(0.85)
  @Max(1.5)
  textScale?: number;

  // Build Session 13 continuation Part C (Privacy Center) — see each
  // field's own schema.prisma comment.
  @ApiPropertyOptional({ enum: CommunityVisibility })
  @IsOptional()
  @IsEnum(CommunityVisibility)
  defaultPostVisibility?: CommunityVisibility;

  @ApiPropertyOptional({ enum: GalleryVisibility })
  @IsOptional()
  @IsEnum(GalleryVisibility)
  defaultGalleryVisibility?: GalleryVisibility;

  @ApiPropertyOptional({ enum: GalleryVisibility })
  @IsOptional()
  @IsEnum(GalleryVisibility)
  progressPhotoDefaultVisibility?: GalleryVisibility;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  defaultHideCardioRoute?: boolean;
}
