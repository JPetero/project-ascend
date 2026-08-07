import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SportCode } from '@prisma/client';
import { IsEnum, IsOptional, IsUUID } from 'class-validator';

export class CreateSportMatchDto {
  @ApiProperty({ enum: SportCode })
  @IsEnum(SportCode)
  sportCode!: SportCode;

  @ApiProperty()
  @IsUUID()
  opponentId!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  ruleSetId?: string;
}
