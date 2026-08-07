import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { HealthMetric } from '@prisma/client';
import { IsDateString, IsEnum, IsNumber, IsOptional, IsString, MaxLength } from 'class-validator';

/** One normalized sample, already unit/timezone-normalized by the client
 * adapter before upload — see apps/mobile/lib/features/wearables/data/
 * health_adapter.dart's HealthSample class, which this mirrors exactly. */
export class HealthSampleDto {
  @ApiProperty({ enum: HealthMetric })
  @IsEnum(HealthMetric)
  metric!: HealthMetric;

  @ApiProperty()
  @IsNumber()
  value!: number;

  @ApiProperty({ description: 'Always the normalized unit for this metric.' })
  @IsString()
  @MaxLength(32)
  unit!: string;

  @ApiProperty({ description: 'ISO 8601 UTC timestamp.' })
  @IsDateString()
  recordedAt!: string;

  @ApiPropertyOptional({ description: 'IANA timezone the sample was recorded in.' })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  recordedTimezone?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(200)
  sourceDeviceId?: string;

  @ApiPropertyOptional({ description: "The platform's own record id, when available." })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  externalId?: string;
}
