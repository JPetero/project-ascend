import { ApiProperty } from '@nestjs/swagger';
import { IsUUID } from 'class-validator';

export class InviteToJointWorkoutSessionDto {
  @ApiProperty()
  @IsUUID()
  inviteeId!: string;
}
