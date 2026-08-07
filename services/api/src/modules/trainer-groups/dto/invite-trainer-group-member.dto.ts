import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class InviteTrainerGroupMemberDto {
  @ApiProperty()
  @IsString()
  inviteeUserId!: string;
}
