import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { RankingScope } from '@prisma/client';
import { IsEnum, IsOptional } from 'class-validator';
import { PaginationQueryDto } from '../../../common/pagination/pagination-query.dto';
import { RankingCategory } from '../../../common/scoring/ranking-category';

export class QueryLeaderboardDto extends PaginationQueryDto {
  @ApiProperty({ enum: RankingScope })
  @IsEnum(RankingScope)
  scope!: RankingScope;

  @ApiPropertyOptional({ enum: RankingCategory, default: RankingCategory.OVERALL })
  @IsOptional()
  @IsEnum(RankingCategory)
  category: RankingCategory = RankingCategory.OVERALL;
}
