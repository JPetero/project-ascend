import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { ArrayMaxSize, IsArray, IsString, MaxLength, ValidateNested } from 'class-validator';
import { HealthSampleDto } from './health-sample.dto';

export class SyncHealthSamplesDto {
  @ApiProperty({ description: "'HEALTH_CONNECT' | 'APPLE_HEALTH' | a vendor string." })
  @IsString()
  @MaxLength(64)
  provider!: string;

  @ApiProperty({ type: [HealthSampleDto] })
  @IsArray()
  @ArrayMaxSize(5000)
  @ValidateNested({ each: true })
  @Type(() => HealthSampleDto)
  samples!: HealthSampleDto[];
}
