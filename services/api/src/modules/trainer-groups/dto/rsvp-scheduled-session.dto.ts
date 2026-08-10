import { ApiProperty } from '@nestjs/swagger';
import { IsEnum } from 'class-validator';
import { TrainerGroupScheduledSessionRsvpStatus } from '@prisma/client';

export class RsvpScheduledSessionDto {
  @ApiProperty({ enum: TrainerGroupScheduledSessionRsvpStatus })
  @IsEnum(TrainerGroupScheduledSessionRsvpStatus)
  status!: TrainerGroupScheduledSessionRsvpStatus;
}
