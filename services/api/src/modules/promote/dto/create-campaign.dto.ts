import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, IsPositive, IsString, IsUUID, MaxLength, MinLength } from 'class-validator';

export class CreateCampaignDto {
  @ApiProperty()
  @IsUUID()
  postId!: string;

  // Non-final business hypothesis — a spend budget, not a live charge.
  // No billing exists this session (see build-session-7.md Part 11).
  @ApiProperty()
  @IsNumber()
  @IsPositive()
  budgetAmount!: number;

  @ApiProperty()
  @IsString()
  @MinLength(3)
  @MaxLength(3)
  budgetCurrency!: string;
}
