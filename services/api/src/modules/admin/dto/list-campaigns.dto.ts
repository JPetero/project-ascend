import { ApiPropertyOptional } from '@nestjs/swagger';
import { PromotedCampaignStatus } from '@prisma/client';
import { IsEnum, IsOptional } from 'class-validator';
import { PaginationQueryDto } from '../../../common/pagination/pagination-query.dto';

export class ListCampaignsDto extends PaginationQueryDto {
  @ApiPropertyOptional({ enum: PromotedCampaignStatus })
  @IsOptional()
  @IsEnum(PromotedCampaignStatus)
  status?: PromotedCampaignStatus;
}
