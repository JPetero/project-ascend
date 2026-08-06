import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, Max, Min } from 'class-validator';

/**
 * Explicit user-entered targets always replace the safe-default estimate
 * (`isEstimatedDefault` flips to false). A generous but bounded range is
 * enforced server-side so a typo can't produce a dangerously low or
 * nonsensical target — this is not a medical judgement, just a sanity
 * bound. Users with specific medical or clinical needs should work with a
 * qualified professional rather than relying on in-app targets.
 */
export class UpsertMacroTargetDto {
  @ApiProperty({ description: 'Daily calorie target. Never set below 1200 for safety.' })
  @IsInt()
  @Min(1200)
  @Max(6000)
  calorieTarget!: number;

  @ApiProperty()
  @IsInt()
  @Min(0)
  @Max(500)
  proteinGramsTarget!: number;

  @ApiProperty()
  @IsInt()
  @Min(0)
  @Max(800)
  carbGramsTarget!: number;

  @ApiProperty()
  @IsInt()
  @Min(0)
  @Max(300)
  fatGramsTarget!: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  fiberGramsTarget?: number;
}
