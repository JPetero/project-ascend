import { OmitType, PartialType } from '@nestjs/swagger';
import { LogSetDto } from './log-set.dto';

export class UpdateSetDto extends PartialType(
  OmitType(LogSetDto, ['exerciseId', 'idempotencyKey'] as const),
) {}
