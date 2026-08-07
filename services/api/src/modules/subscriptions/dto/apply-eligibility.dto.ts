import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { AffordabilityProgram } from '@prisma/client';
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

export class ApplyEligibilityDto {
  @ApiProperty({ enum: AffordabilityProgram })
  @IsEnum(AffordabilityProgram)
  program!: AffordabilityProgram;

  // Free-text context the applicant chooses to share (e.g. "current
  // student ID on file with my school"). Never required — approval
  // review, when it exists, is future work (Part 10's admin
  // foundation); this endpoint only records the request.
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}
