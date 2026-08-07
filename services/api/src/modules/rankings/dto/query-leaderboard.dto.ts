import { ApiProperty } from '@nestjs/swagger';
import { RankingScope } from '@prisma/client';
import { IsEnum } from 'class-validator';
import { PaginationQueryDto } from '../../../common/pagination/pagination-query.dto';

export class QueryLeaderboardDto extends PaginationQueryDto {
  @ApiProperty({ enum: RankingScope })
  @IsEnum(RankingScope)
  scope!: RankingScope;
}
