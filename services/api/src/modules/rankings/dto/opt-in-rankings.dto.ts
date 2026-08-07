import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { RankingScope } from '@prisma/client';
import { IsEnum, IsString, MaxLength, ValidateIf } from 'class-validator';

export class OptInRankingsDto {
  @ApiProperty({ enum: RankingScope })
  @IsEnum(RankingScope)
  scope!: RankingScope;

  // Required only for REGION scope — a coarse, user-typed label (e.g.
  // "Quezon City"), never a coordinate, same pattern as
  // CardioSession.regionLabel.
  @ApiPropertyOptional()
  @ValidateIf((dto: OptInRankingsDto) => dto.scope === RankingScope.REGION)
  @IsString()
  @MaxLength(100)
  regionLabel?: string;
}
