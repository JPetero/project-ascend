import { ApiProperty } from '@nestjs/swagger';
import { AffordabilityStatus } from '@prisma/client';
import { IsEnum } from 'class-validator';

export class DecideEligibilityDto {
  @ApiProperty({ enum: AffordabilityStatus })
  @IsEnum(AffordabilityStatus)
  status!: AffordabilityStatus;
}
