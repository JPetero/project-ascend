import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class AppleSignInDto {
  @ApiProperty()
  @IsString()
  idToken!: string;

  // Apple only returns the user's name in the client's first
  // authorization response, never inside the ID token itself — the
  // client forwards it here on first sign-in only.
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(80)
  firstName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(120)
  deviceName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(40)
  platform?: string;
}
