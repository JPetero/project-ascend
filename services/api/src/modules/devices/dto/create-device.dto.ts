import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { DeviceConnectionStatus } from '@prisma/client';
import { IsEnum, IsObject, IsOptional, IsString, Matches, MaxLength } from 'class-validator';

export class CreateDeviceDto {
  @ApiProperty()
  @IsString()
  @MaxLength(60)
  provider!: string;

  @ApiProperty()
  @IsString()
  @MaxLength(120)
  displayName!: string;

  /**
   * Identifies one physical device among several the same provider might
   * report (e.g. two paired Garmin watches). Omit it for providers/clients
   * that only ever have one connection per provider — the service defaults
   * it to `"default"`, matching the DB column's default.
   */
  @ApiPropertyOptional({
    description:
      'Client- or provider-generated key distinguishing multiple physical devices for the same provider. Omit for a single-device provider.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  @Matches(/^[A-Za-z0-9._:-]+$/, {
    message: 'connectionKey may only contain letters, numbers, ".", "_", ":", and "-".',
  })
  connectionKey?: string;

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
