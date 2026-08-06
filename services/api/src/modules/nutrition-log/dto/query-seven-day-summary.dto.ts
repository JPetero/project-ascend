import { ApiProperty } from '@nestjs/swagger';
import { IsDateString } from 'class-validator';

export class QuerySevenDaySummaryDto {
  @ApiProperty({ description: 'Last day of the 7-day window (inclusive), YYYY-MM-DD.' })
  @IsDateString()
  endDate!: string;
}
