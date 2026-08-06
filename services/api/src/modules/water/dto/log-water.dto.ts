import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class LogWaterDto {
  @ApiProperty({ description: 'Date this water entry is logged against, YYYY-MM-DD.' })
  @IsDateString()
  date!: string;

  @ApiProperty({ description: 'Amount of water in millilitres.' })
  @IsInt()
  @Min(1)
  @Max(5000)
  amountMl!: number;

  @ApiPropertyOptional({
    description:
      'Client-generated key identifying this exact log attempt, so a network retry never creates a duplicate entry.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  idempotencyKey?: string;
}
