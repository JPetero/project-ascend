import { ApiPropertyOptional } from '@nestjs/swagger';
import { RankingScope } from '@prisma/client';
import { Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, Max, Min } from 'class-validator';

// GLOBAL (every rated player) is the default, matching this endpoint's
// pre-existing unscoped behavior. FRIENDS/LOCAL/CITY/REGION/NATIONAL
// reuse RankingsService's exact scope vocabulary — see
// common/rankings/resolve-scope-candidates.util.ts.
export class QuerySportLeaderboardDto {
  @ApiPropertyOptional({ enum: RankingScope, default: RankingScope.GLOBAL })
  @IsOptional()
  @IsEnum(RankingScope)
  scope: RankingScope = RankingScope.GLOBAL;

  @ApiPropertyOptional({ default: 50 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit: number = 50;
}
