import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class ShareTrainerGroupPlanDto {
  @ApiProperty()
  @IsString()
  workoutPlanId!: string;
}
