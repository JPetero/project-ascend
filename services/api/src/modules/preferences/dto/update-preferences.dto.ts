import { ApiPropertyOptional } from '@nestjs/swagger';
import { CoachingStyle, Companion, CompanionMode, ThemeMode } from '@prisma/client';
import { IsBoolean, IsEnum, IsInt, IsOptional, Max, Min } from 'class-validator';

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
}
