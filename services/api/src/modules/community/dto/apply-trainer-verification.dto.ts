import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength, MinLength } from 'class-validator';

export class ApplyTrainerVerificationDto {
  // Free-text credentials/certifications for an admin to review — e.g.
  // certification body, license number, years of experience. Required,
  // unlike AffordabilityEligibility's optional notes: there is nothing
  // else for an admin to review a trainer application on.
  @ApiProperty()
  @IsString()
  @MinLength(10)
  @MaxLength(1000)
  credentials!: string;
}
