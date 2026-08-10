import { ApiPropertyOptional } from '@nestjs/swagger';
import { TrainerVerificationStatus } from '@prisma/client';
import { IsEnum, IsOptional } from 'class-validator';
import { PaginationQueryDto } from '../../../common/pagination/pagination-query.dto';

export class ListTrainerVerificationDto extends PaginationQueryDto {
  @ApiPropertyOptional({ enum: TrainerVerificationStatus })
  @IsOptional()
  @IsEnum(TrainerVerificationStatus)
  status?: TrainerVerificationStatus;
}
