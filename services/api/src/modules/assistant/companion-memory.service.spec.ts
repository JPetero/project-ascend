import { CompanionMemoryService } from './companion-memory.service';
import { PrismaService } from '../../prisma/prisma.service';

describe('CompanionMemoryService', () => {
  let prisma: {
    companionMemory: { findUnique: jest.Mock; upsert: jest.Mock; deleteMany: jest.Mock };
  };
  let service: CompanionMemoryService;

  beforeEach(() => {
    prisma = {
      companionMemory: {
        findUnique: jest.fn().mockResolvedValue(null),
        upsert: jest.fn(),
        deleteMany: jest.fn(),
      },
    };
    service = new CompanionMemoryService(prisma as unknown as PrismaService);
  });

  describe('getNotes', () => {
    it('returns an empty list when no memory row exists yet', async () => {
      await expect(service.getNotes('user-1')).resolves.toEqual([]);
    });

    it('returns the stored notes', async () => {
      prisma.companionMemory.findUnique.mockResolvedValue({ notes: ['a fact', 'another fact'] });
      await expect(service.getNotes('user-1')).resolves.toEqual(['a fact', 'another fact']);
    });
  });

  describe('remember', () => {
    it('skips short, non-substantive input rather than storing conversational filler', async () => {
      await service.remember('user-1', 'ok thanks');
      expect(prisma.companionMemory.upsert).not.toHaveBeenCalled();
    });

    it('stores a substantive statement verbatim, trimmed', async () => {
      await service.remember('user-1', '  Training for a half marathon in the spring.  ');
      expect(prisma.companionMemory.upsert).toHaveBeenCalledWith({
        where: { userId: 'user-1' },
        update: { notes: ['Training for a half marathon in the spring.'] },
        create: { userId: 'user-1', notes: ['Training for a half marathon in the spring.'] },
      });
    });

    it('skips an exact consecutive duplicate of the most recent note', async () => {
      prisma.companionMemory.findUnique.mockResolvedValue({
        notes: ['Training for a half marathon in the spring.'],
      });
      await service.remember('user-1', 'Training for a half marathon in the spring.');
      expect(prisma.companionMemory.upsert).not.toHaveBeenCalled();
    });

    it('caps the notes list, dropping the oldest entry once full', async () => {
      const existing = Array.from({ length: 12 }, (_, i) => `note number ${i}`);
      prisma.companionMemory.findUnique.mockResolvedValue({ notes: existing });

      await service.remember('user-1', 'a brand new remembered fact');

      const [[call]] = prisma.companionMemory.upsert.mock.calls;
      expect(call.update.notes).toHaveLength(12);
      expect(call.update.notes[0]).toBe('note number 1');
      expect(call.update.notes.at(-1)).toBe('a brand new remembered fact');
    });
  });

  describe('clear', () => {
    it('scopes the delete to the caller', async () => {
      await service.clear('user-1');
      expect(prisma.companionMemory.deleteMany).toHaveBeenCalledWith({
        where: { userId: 'user-1' },
      });
    });
  });
});
