import { CompanionMemoryCategory } from '@prisma/client';

export { CompanionMemoryCategory };

/** A structured fact `MemoryExtractionService` found in one user turn —
 * never the raw turn itself. See that service's doc comment for the
 * boundary this enforces. */
export interface MemoryCandidate {
  category: CompanionMemoryCategory;
  value: string;
}

/**
 * Build Session 12 Part 4 — a second privacy boundary on top of the
 * category allowlist itself. Even an allowed category can carry
 * sensitive information (an allergy, a disability/accessibility fact) —
 * those categories must never be auto-saved just because
 * `Preference.aiMemoryEnabled` is on. A STANDARD candidate is saved
 * immediately, same as before; a SENSITIVE one is surfaced to the user
 * as a pending confirmation instead (see `AssistantService.reply`'s
 * `pendingMemory` return field) and only saved once they explicitly
 * confirm it.
 */
export enum MemorySensitivity {
  STANDARD = 'STANDARD',
  SENSITIVE = 'SENSITIVE',
}

const SENSITIVE_MEMORY_CATEGORIES: ReadonlySet<CompanionMemoryCategory> = new Set([
  CompanionMemoryCategory.DIETARY_RESTRICTION,
  CompanionMemoryCategory.ACCESSIBILITY_PREFERENCE,
]);

export function memorySensitivityOf(category: CompanionMemoryCategory): MemorySensitivity {
  return SENSITIVE_MEMORY_CATEGORIES.has(category)
    ? MemorySensitivity.SENSITIVE
    : MemorySensitivity.STANDARD;
}
