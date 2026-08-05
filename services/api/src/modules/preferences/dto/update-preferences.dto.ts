import { ApiPropertyOptional } from '@nestjs/swagger';
import { Companion, CompanionMode, ThemeMode } from '@prisma/client';
import { IsBoolean, IsEnum, IsOptional } from 'class-validator';

export class UpdatePreferencesDto {
  @ApiPropertyOptional({ enum: Companion })
  @IsOptional()
  @IsEnum(Companion)
  companion?: Companion;

  @ApiPropertyOptional({ enum: CompanionMode })
  @IsOptional()
  @IsEnum(CompanionMode)
  companionMode?: CompanionMode;

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
}
