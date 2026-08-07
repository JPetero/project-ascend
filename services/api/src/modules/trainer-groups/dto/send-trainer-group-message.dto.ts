import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsUrl, MaxLength } from 'class-validator';

// At least one of body/imageUrl must be present — enforced in
// TrainerGroupsService.sendMessage, not here, since it's a cross-field
// rule rather than a single-field constraint.
export class SendTrainerGroupMessageDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  body?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUrl()
  imageUrl?: string;
}
