import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CompanionMemoryCategory, MemoryCandidate } from './memory-extraction.types';

// A small, capped list — this is a handful of durable structured facts
// (goals, equipment, preferences), not a transcript. Oldest entries drop
// off once the cap is hit.
const MAX_NOTES = 12;

export interface CompanionMemoryNoteView {
  id: string;
  category: CompanionMemoryCategory;
  value: string;
  createdAt: Date;
}

/**
 * Build Session 11 Part 4 rewrite: one row per structured fact (see
 * `CompanionMemoryNote` in schema.prisma) instead of the original single
 * `notes: string[]` row per user. `MemoryExtractionService` is the only
 * source of what gets saved — this class never inspects raw
 * conversation text itself, it only persists/lists/deletes whatever
 * candidate it's given. `AssistantService` is the only caller that
 * decides *whether* to consult/update memory at all (gated on
 * `Preference.aiMemoryEnabled`, which now defaults off).
 */
@Injectable()
export class CompanionMemoryService {
  constructor(private readonly prisma: PrismaService) {}

  async getNotes(userId: string): Promise<CompanionMemoryNoteView[]> {
    return this.prisma.companionMemoryNote.findMany({
      where: { userId },
      orderBy: { createdAt: 'asc' },
    });
  }

  async remember(userId: string, candidate: MemoryCandidate): Promise<void> {
    const existing = await this.getNotes(userId);
    // Skip an exact duplicate of an already-remembered fact in the same
    // category rather than piling up repeats every time the user
    // mentions the same preference again.
    const alreadyKnown = existing.some(
      (note) => note.category === candidate.category && note.value === candidate.value,
    );
    if (alreadyKnown) return;

    await this.prisma.companionMemoryNote.create({
      data: { userId, category: candidate.category, value: candidate.value },
    });

    const overflow = existing.length + 1 - MAX_NOTES;
    if (overflow > 0) {
      const oldest = existing.slice(0, overflow).map((note) => note.id);
      await this.prisma.companionMemoryNote.deleteMany({ where: { id: { in: oldest } } });
    }
  }

  async deleteNote(userId: string, noteId: string): Promise<void> {
    const result = await this.prisma.companionMemoryNote.deleteMany({
      where: { id: noteId, userId },
    });
    if (result.count === 0) {
      throw new NotFoundException('Memory not found.');
    }
  }

  async clear(userId: string): Promise<void> {
    await this.prisma.companionMemoryNote.deleteMany({ where: { userId } });
  }
}
