import { ApiProperty } from '@nestjs/swagger';
import { IsInt, Min } from 'class-validator';

export class ProposeScoreDto {
  @ApiProperty()
  @IsInt()
  @Min(0)
  proposerScore!: number;

  @ApiProperty()
  @IsInt()
  @Min(0)
  opponentScore!: number;
}
