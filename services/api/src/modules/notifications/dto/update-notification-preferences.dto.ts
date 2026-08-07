import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional } from 'class-validator';

export class UpdateNotificationPreferencesDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  workoutReminders?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  restDayReminders?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  waterReminders?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  mealReminders?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  achievementNotifications?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  socialNotifications?: boolean;
}
