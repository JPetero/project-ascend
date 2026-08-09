import { ApiPropertyOptional } from '@nestjs/swagger';
import { ArrayMaxSize, IsArray, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class CreateJointWorkoutSessionDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(120)
  title?: string;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(8)
  @IsUUID('4', { each: true })
  inviteeIds?: string[];

  @ApiPropertyOptional({
    description:
      'Schedule this session for every member of a Trainer Group instead of hand-picking ' +
      'friends — mutually exclusive with inviteeIds. Requires the group owner’s expanded ' +
      '(Premium) tier; see TrainerGroupsService.resolveGroupSessionInvitees.',
  })
  @IsOptional()
  @IsUUID('4')
  trainerGroupId?: string;
}
