import { IsEnum, IsString, MaxLength, MinLength } from 'class-validator';
import { CompanionMemoryCategory } from '../memory-extraction.types';

/**
 * Build Session 12 Part 4 — explicit user confirmation for a SENSITIVE
 * memory candidate `AssistantService.reply` surfaced but did not
 * auto-save (see `memorySensitivityOf`). The category/value pair must
 * match what the assistant actually offered; the client re-sends both
 * rather than a candidate id since nothing is persisted server-side
 * until this call succeeds.
 */
export class ConfirmMemoryDto {
  @IsEnum(CompanionMemoryCategory)
  category!: CompanionMemoryCategory;

  @IsString()
  @MinLength(1)
  @MaxLength(200)
  value!: string;
}
