import { ApiPropertyOptional } from '@nestjs/swagger';
import { HealthMetric } from '@prisma/client';
import { Type } from 'class-transformer';
import { IsDateString, IsEnum, IsInt, IsOptional, Max, Min } from 'class-validator';

export class QueryHealthSamplesDto {
  @ApiPropertyOptional({ enum: HealthMetric })
  @IsOptional()
  @IsEnum(HealthMetric)
  metric?: HealthMetric;

  @ApiPropertyOptional({ description: 'ISO 8601 — inclusive lower bound on recordedAt.' })
  @IsOptional()
  @IsDateString()
  from?: string;

  @ApiPropertyOptional({ description: 'ISO 8601 — inclusive upper bound on recordedAt.' })
  @IsOptional()
  @IsDateString()
  to?: string;

  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page: number = 1;

  @ApiPropertyOptional({ default: 50 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(200)
  limit: number = 50;
}
