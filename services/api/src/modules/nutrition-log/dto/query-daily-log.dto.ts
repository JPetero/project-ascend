import { ApiProperty } from '@nestjs/swagger';
import { IsDateString } from 'class-validator';

export class QueryDailyLogDto {
  @ApiProperty({ description: 'YYYY-MM-DD' })
  @IsDateString()
  date!: string;
}
