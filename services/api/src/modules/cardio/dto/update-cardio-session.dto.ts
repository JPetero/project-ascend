import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString, MaxLength } from 'class-validator';

/** Only the privacy toggles and notes are editable after the fact —
 * activity/duration/distance/etc. are a record of what happened and
 * aren't meant to be revised after logging. */
export class UpdateCardioSessionDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  hideRoute?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  hideStartLocation?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  hideEndLocation?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;
}
