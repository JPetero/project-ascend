import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { DeviceConnectionStatus } from '@prisma/client';
import { IsEnum, IsObject, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateDeviceDto {
  @ApiProperty()
  @IsString()
  @MaxLength(60)
  provider!: string;

  @ApiProperty()
  @IsString()
  @MaxLength(120)
  displayName!: string;

  @ApiPropertyOptional({ enum: DeviceConnectionStatus })
  @IsOptional()
  @IsEnum(DeviceConnectionStatus)
  status?: DeviceConnectionStatus;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(200)
  externalAccountId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsObject()
  metadata?: Record<string, unknown>;
}
