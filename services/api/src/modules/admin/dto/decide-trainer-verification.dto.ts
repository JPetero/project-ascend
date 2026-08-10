import { ApiProperty } from '@nestjs/swagger';
import { TrainerVerificationStatus } from '@prisma/client';
import { IsEnum } from 'class-validator';

export class DecideTrainerVerificationDto {
  @ApiProperty({ enum: TrainerVerificationStatus })
  @IsEnum(TrainerVerificationStatus)
  status!: TrainerVerificationStatus;
}
