import { ApiProperty } from '@nestjs/swagger';
import { IsIn } from 'class-validator';

// OWNER is deliberately excluded — ownership never transfers through
// this endpoint (see TrainerGroupsService.setMemberRole).
export class SetTrainerGroupMemberRoleDto {
  @ApiProperty({ enum: ['MODERATOR', 'MEMBER'] })
  @IsIn(['MODERATOR', 'MEMBER'])
  role!: 'MODERATOR' | 'MEMBER';
}
