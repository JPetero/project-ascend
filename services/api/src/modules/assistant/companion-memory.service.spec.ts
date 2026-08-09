import { NotFoundException } from '@nestjs/common';
import { CompanionMemoryService } from './companion-memory.service';
import { CompanionMemoryCategory } from './memory-extraction.types';
import { PrismaService } from '../../prisma/prisma.service';

function note(
  overrides: Partial<{
    id: string;
    category: CompanionMemoryCategory;
    value: string;
    createdAt: Date;
  }> = {},
) {
  return {
    id: 'note-1',
    category: CompanionMemoryCategory.GOAL,
    value: 'Goal: build strength.',
    createdAt: new Date('2026-01-01'),
    ...overrides,
  };
}

describe('CompanionMemoryService', () => {
  let prisma: {
    companionMemoryNote: {
      findMany: jest.Mock;
      create: jest.Mock;
      deleteMany: jest.Mock;
    };
  };
  let service: CompanionMemoryService;

  beforeEach(() => {
    prisma = {
      companionMemoryNote: {
        findMany: jest.fn().mockResolvedValue([]),
        create: jest.fn().mockResolvedValue(undefined),
        deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
    };
    service = new CompanionMemoryService(prisma as unknown as PrismaService);
  });

  describe('getNotes', () => {
    it('returns an empty list when nothing is remembered yet', async () => {
      await expect(service.getNotes('user-1')).resolves.toEqual([]);
    });

    it('returns the stored structured notes, oldest first', async () => {
      const notes = [note({ id: 'a' }), note({ id: 'b' })];
      prisma.companionMemoryNote.findMany.mockResolvedValue(notes);
      await expect(service.getNotes('user-1')).resolves.toEqual(notes);
      expect(prisma.companionMemoryNote.findMany).toHaveBeenCalledWith({
        where: { userId: 'user-1' },
        orderBy: { createdAt: 'asc' },
      });
    });
  });

  describe('remember', () => {
    it('creates a new structured note for a fresh candidate', async () => {
      await service.remember('user-1', {
        category: CompanionMemoryCategory.EQUIPMENT,
        value: 'Has access to: dumbbells.',
      });
      expect(prisma.companionMemoryNote.create).toHaveBeenCalledWith({
        data: {
          userId: 'user-1',
          category: CompanionMemoryCategory.EQUIPMENT,
          value: 'Has access to: dumbbells.',
        },
      });
    });

    it('skips an exact duplicate of an already-known fact in the same category', async () => {
      prisma.companionMemoryNote.findMany.mockResolvedValue([
        note({ category: CompanionMemoryCategory.GOAL, value: 'Goal: build strength.' }),
      ]);
      await service.remember('user-1', {
        category: CompanionMemoryCategory.GOAL,
        value: 'Goal: build strength.',
      });
      expect(prisma.companionMemoryNote.create).not.toHaveBeenCalled();
    });

    it('stores the same value under a different category (not deduped across categories)', async () => {
      prisma.companionMemoryNote.findMany.mockResolvedValue([
        note({ category: CompanionMemoryCategory.GOAL, value: 'Marathon' }),
      ]);
      await service.remember('user-1', {
        category: CompanionMemoryCategory.WORKOUT_PREFERENCE,
        value: 'Marathon',
      });
      expect(prisma.companionMemoryNote.create).toHaveBeenCalled();
    });

    it('evicts the oldest note once the cap is exceeded', async () => {
      const existing = Array.from({ length: 12 }, (_, i) =>
        note({ id: `note-${i}`, value: `fact ${i}`, createdAt: new Date(2026, 0, i + 1) }),
      );
      prisma.companionMemoryNote.findMany.mockResolvedValue(existing);

      await service.remember('user-1', {
        category: CompanionMemoryCategory.GOAL,
        value: 'a brand new fact',
      });

      expect(prisma.companionMemoryNote.deleteMany).toHaveBeenCalledWith({
        where: { id: { in: ['note-0'] } },
      });
    });
  });

  describe('deleteNote', () => {
    it('scopes deletion to both the note id and the caller', async () => {
      await service.deleteNote('user-1', 'note-1');
      expect(prisma.companionMemoryNote.deleteMany).toHaveBeenCalledWith({
        where: { id: 'note-1', userId: 'user-1' },
      });
    });

    it('404s when the note does not exist or belongs to someone else', async () => {
      prisma.companionMemoryNote.deleteMany.mockResolvedValue({ count: 0 });
      await expect(service.deleteNote('user-1', 'not-mine')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });

  describe('clear', () => {
    it('scopes the delete to the caller', async () => {
      await service.clear('user-1');
      expect(prisma.companionMemoryNote.deleteMany).toHaveBeenCalledWith({
        where: { userId: 'user-1' },
      });
    });
  });
});
