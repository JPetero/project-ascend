import { ApiProperty } from '@nestjs/swagger';
import { IsInt, Max, Min } from 'class-validator';

export class UpdateWaterDto {
  @ApiProperty({ description: 'Amount of water in millilitres.' })
  @IsInt()
  @Min(1)
  @Max(5000)
  amountMl!: number;
}
