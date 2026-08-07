import { ApiPropertyOptional } from '@nestjs/swagger';
import { CommunityReportStatus } from '@prisma/client';
import { IsEnum, IsOptional } from 'class-validator';
import { PaginationQueryDto } from '../../../common/pagination/pagination-query.dto';

export class ListReportsDto extends PaginationQueryDto {
  @ApiPropertyOptional({ enum: CommunityReportStatus })
  @IsOptional()
  @IsEnum(CommunityReportStatus)
  status?: CommunityReportStatus;
}
