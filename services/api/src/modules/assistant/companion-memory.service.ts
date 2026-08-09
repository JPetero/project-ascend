import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

// A small, capped list — this is a handful of durable facts (goals,
// injuries, equipment, preferences), not a transcript. Oldest entries
// drop off once the cap is hit.
const MAX_NOTES = 12;
// Skips conversational filler ("ok", "thanks!") that isn't worth
// remembering — a low bar, not an attempt at real classification.
const MIN_NOTE_LENGTH = 12;

/**
 * Real, durable Atlas/Nova memory (Build Session 10 Part 15) — see
 * `CompanionMemory`'s doc comment in schema.prisma. Notes are the user's
 * own words, stored verbatim, never summarized or rewritten by an LLM,
 * so nothing here can drift into a fabricated "fact." `AssistantService`
 * is the only caller that decides *whether* to consult/update memory
 * (gated on `Preference.aiMemoryEnabled`); this service only knows how.
 */
@Injectable()
export class CompanionMemoryService {
  constructor(private readonly prisma: PrismaService) {}

  async getNotes(userId: string): Promise<string[]> {
    const memory = await this.prisma.companionMemory.findUnique({ where: { userId } });
    return memory?.notes ?? [];
  }

  async remember(userId: string, input: string): Promise<void> {
    const note = input.trim();
    if (note.length < MIN_NOTE_LENGTH) return;

    const existing = await this.getNotes(userId);
    if (existing[existing.length - 1] === note) return;

    const notes = [...existing, note].slice(-MAX_NOTES);
    await this.prisma.companionMemory.upsert({
      where: { userId },
      update: { notes },
      create: { userId, notes },
    });
  }

  async clear(userId: string): Promise<void> {
    await this.prisma.companionMemory.deleteMany({ where: { userId } });
  }
}
