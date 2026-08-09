import { CompanionMemoryCategory } from '@prisma/client';

export { CompanionMemoryCategory };

/** A structured fact `MemoryExtractionService` found in one user turn —
 * never the raw turn itself. See that service's doc comment for the
 * boundary this enforces. */
export interface MemoryCandidate {
  category: CompanionMemoryCategory;
  value: string;
}
