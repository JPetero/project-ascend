import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { CommunityReportStatus } from '@prisma/client';
import { IsBoolean, IsEnum, IsOptional } from 'class-validator';

export class ActionReportDto {
  @ApiProperty({ enum: CommunityReportStatus })
  @IsEnum(CommunityReportStatus)
  status!: CommunityReportStatus;

  // Only meaningful (and only ever applied) when status is ACTIONED and
  // the report's target is a post — see AdminService.actionReport.
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  removeContent?: boolean;
}
