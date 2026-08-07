import { ApiProperty } from '@nestjs/swagger';
import { PromotedCampaignStatus } from '@prisma/client';
import { IsEnum } from 'class-validator';

export class DecideCampaignDto {
  @ApiProperty({ enum: PromotedCampaignStatus })
  @IsEnum(PromotedCampaignStatus)
  status!: PromotedCampaignStatus;
}
