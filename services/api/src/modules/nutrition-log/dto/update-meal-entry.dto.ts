import { OmitType, PartialType } from '@nestjs/swagger';
import { CreateMealEntryDto } from './create-meal-entry.dto';

export class UpdateMealEntryDto extends PartialType(
  OmitType(CreateMealEntryDto, ['idempotencyKey'] as const),
) {}
