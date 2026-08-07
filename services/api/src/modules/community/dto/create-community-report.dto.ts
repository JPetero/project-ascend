import { ApiProperty } from '@nestjs/swagger';
import { CommunityReportTargetType } from '@prisma/client';
import { IsEnum, IsString, MaxLength } from 'class-validator';

// Feeds Scenario 21/25's "reports/blocks/moderation before promotion"
// requirement — this creates an OPEN report for a human moderator (Part
// 10's Support/Admin foundation) to review; nothing here is auto-actioned.
export class CreateCommunityReportDto {
  @ApiProperty({ enum: CommunityReportTargetType })
  @IsEnum(CommunityReportTargetType)
  targetType!: CommunityReportTargetType;

  @ApiProperty()
  @IsString()
  targetId!: string;

  @ApiProperty()
  @IsString()
  @MaxLength(500)
  reason!: string;
}
