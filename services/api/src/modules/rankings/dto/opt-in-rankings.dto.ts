import { ApiPropertyOptional, ApiProperty } from '@nestjs/swagger';
import { RankingScope } from '@prisma/client';
import { Transform } from 'class-transformer';
import { IsEnum, IsString, MaxLength, ValidateIf } from 'class-validator';
import { requiredLocalityFields } from '../../../common/rankings/locality.util';

const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);

// Each locality field is required exactly when the chosen scope's tier
// needs it — NATIONAL needs localityCountry only, LOCAL needs all four.
// See common/rankings/locality.util.ts for the tier order this mirrors.
export class OptInRankingsDto {
  @ApiProperty({ enum: RankingScope })
  @IsEnum(RankingScope)
  scope!: RankingScope;

  // A coarse, user-typed label (e.g. "Philippines"), never a
  // coordinate — same pattern as CardioSession.regionLabel.
  @ApiPropertyOptional()
  @ValidateIf((dto: OptInRankingsDto) =>
    requiredLocalityFields(dto.scope).includes('localityCountry'),
  )
  @IsString()
  @MaxLength(100)
  @Transform(trim)
  localityCountry?: string;

  // Region/state, e.g. "Metro Manila".
  @ApiPropertyOptional()
  @ValidateIf((dto: OptInRankingsDto) =>
    requiredLocalityFields(dto.scope).includes('localityRegion'),
  )
  @IsString()
  @MaxLength(100)
  @Transform(trim)
  localityRegion?: string;

  // City, e.g. "Quezon City".
  @ApiPropertyOptional()
  @ValidateIf((dto: OptInRankingsDto) => requiredLocalityFields(dto.scope).includes('localityCity'))
  @IsString()
  @MaxLength(100)
  @Transform(trim)
  localityCity?: string;

  // A neighborhood or district within the city, e.g. "Diliman".
  @ApiPropertyOptional()
  @ValidateIf((dto: OptInRankingsDto) => requiredLocalityFields(dto.scope).includes('localityArea'))
  @IsString()
  @MaxLength(100)
  @Transform(trim)
  localityArea?: string;
}
