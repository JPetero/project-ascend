import { ApiPropertyOptional } from '@nestjs/swagger';
import { AffordabilityStatus } from '@prisma/client';
import { IsEnum, IsOptional } from 'class-validator';
import { PaginationQueryDto } from '../../../common/pagination/pagination-query.dto';

export class ListEligibilityDto extends PaginationQueryDto {
  @ApiPropertyOptional({ enum: AffordabilityStatus })
  @IsOptional()
  @IsEnum(AffordabilityStatus)
  status?: AffordabilityStatus;
}
