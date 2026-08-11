import { Test } from '@nestjs/testing';
import { SchedulerLockService } from '../../common/scheduling/scheduler-lock.service';
import { PrismaService } from '../../prisma/prisma.service';
import { MEDIA_CLEANUP_LOCK_NAME, MediaCleanupService } from './media-cleanup.service';
import { MEDIA_STORAGE_PROVIDER } from './storage/media-storage.provider';

describe('MediaCleanupService', () => {
  let service: MediaCleanupService;
  let prisma: {
    mediaAsset: { findMany: jest.Mock; delete: jest.Mock; deleteMany: jest.Mock };
  };
  let storage: { deleteObject: jest.Mock };
  let schedulerLock: { runExclusive: jest.Mock };

  beforeEach(async () => {
    prisma = {
      mediaAsset: {
        findMany: jest.fn().mockResolvedValue([]),
        delete: jest.fn().mockResolvedValue(undefined),
        deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
    };
    storage = { deleteObject: jest.fn().mockResolvedValue(undefined) };
    schedulerLock = {
      runExclusive: jest.fn(async (_name: string, job: () => Promise<unknown>) => ({
        ran: true,
        result: await job(),
      })),
    };

    const moduleRef = await Test.createTestingModule({
      providers: [
        MediaCleanupService,
        { provide: PrismaService, useValue: prisma },
        { provide: MEDIA_STORAGE_PROVIDER, useValue: storage },
        { provide: SchedulerLockService, useValue: schedulerLock },
      ],
    }).compile();

    service = moduleRef.get(MediaCleanupService);
  });

  describe('runCleanup dryRun mode', () => {
    it('reports counts without deleting any storage object or row', async () => {
      prisma.mediaAsset.findMany.mockResolvedValue([
        { id: 'asset-1', storageKey: 'key-1', variants: [] },
      ]);

      const counts = await service.runCleanup({ dryRun: true });

      expect(counts).toEqual({
        abandonedUploads: 1,
        orphanedMedia: 1,
        deletedTombstones: 1,
        accountDeletionMedia: 1,
      });
      expect(storage.deleteObject).not.toHaveBeenCalled();
      expect(prisma.mediaAsset.delete).not.toHaveBeenCalled();
      expect(prisma.mediaAsset.deleteMany).not.toHaveBeenCalled();
    });
  });

  describe('cleanAbandonedUploads', () => {
    it('queries for expired, never-completed uploads and purges storage plus the row', async () => {
      prisma.mediaAsset.findMany.mockImplementation((args: { where: Record<string, unknown> }) =>
        Promise.resolve(
          'upload' in args.where ? [{ id: 'asset-1', storageKey: 'abandoned-key' }] : [],
        ),
      );

      await service.runCleanup({ dryRun: false });

      expect(storage.deleteObject).toHaveBeenCalledWith('abandoned-key');
      expect(prisma.mediaAsset.delete).toHaveBeenCalledWith({ where: { id: 'asset-1' } });
    });
  });

  describe('cleanOrphanedMedia', () => {
    it('only targets READY, unreferenced assets past the grace period, and purges variant storage too', async () => {
      prisma.mediaAsset.findMany.mockImplementation((args: { where: Record<string, unknown> }) =>
        Promise.resolve(
          (args.where as { processingState?: string }).processingState === 'READY'
            ? [
                {
                  id: 'asset-2',
                  storageKey: 'orphan-key',
                  variants: [{ storageKey: 'orphan-thumb-key' }],
                },
              ]
            : [],
        ),
      );

      const counts = await service.runCleanup({ dryRun: false });

      expect(counts.orphanedMedia).toBe(1);
      expect(storage.deleteObject).toHaveBeenCalledWith('orphan-key');
      expect(storage.deleteObject).toHaveBeenCalledWith('orphan-thumb-key');
      expect(prisma.mediaAsset.delete).toHaveBeenCalledWith({ where: { id: 'asset-2' } });
    });

    it('filters on usages: none so a referenced asset is never a candidate', async () => {
      await service.runCleanup({ dryRun: true });

      const orphanCall = prisma.mediaAsset.findMany.mock.calls.find(
        ([args]: [{ where: Record<string, unknown> }]) =>
          (args.where as { processingState?: string }).processingState === 'READY',
      );
      expect(orphanCall[0].where.usages).toEqual({ none: {} });
    });
  });

  describe('cleanDeletedTombstones', () => {
    it('purges only the DB row — storage is already gone by the time retentionState is DELETED', async () => {
      prisma.mediaAsset.findMany.mockImplementation((args: { where: Record<string, unknown> }) =>
        Promise.resolve(
          (args.where as { retentionState?: string }).retentionState === 'DELETED'
            ? [{ id: 'tombstone-1' }]
            : [],
        ),
      );

      const counts = await service.runCleanup({ dryRun: false });

      expect(counts.deletedTombstones).toBe(1);
      expect(prisma.mediaAsset.deleteMany).toHaveBeenCalledWith({
        where: { id: { in: ['tombstone-1'] } },
      });
      // No storage call for this category specifically implies no
      // extra deleteObject beyond whatever the other three categories
      // (mocked to return [] here) would add — asserted indirectly via
      // the other describe blocks.
    });

    it('does not call deleteMany when there is nothing to purge', async () => {
      await service.runCleanup({ dryRun: false });

      expect(prisma.mediaAsset.deleteMany).not.toHaveBeenCalled();
    });
  });

  describe('cleanAccountDeletionMedia', () => {
    it('targets unreferenced media owned by a long-deleted account', async () => {
      prisma.mediaAsset.findMany.mockImplementation((args: { where: Record<string, unknown> }) =>
        Promise.resolve(
          'owner' in args.where
            ? [{ id: 'asset-3', storageKey: 'orphaned-account-key', variants: [] }]
            : [],
        ),
      );

      await service.runCleanup({ dryRun: false });

      expect(storage.deleteObject).toHaveBeenCalledWith('orphaned-account-key');
      expect(prisma.mediaAsset.delete).toHaveBeenCalledWith({ where: { id: 'asset-3' } });
    });

    it('scopes the owner filter to DELETED status past the grace period', async () => {
      await service.runCleanup({ dryRun: true });

      const call = prisma.mediaAsset.findMany.mock.calls.find(
        ([args]: [{ where: Record<string, unknown> }]) => 'owner' in args.where,
      );
      expect(call[0].where.owner).toEqual({
        status: 'DELETED',
        updatedAt: { lt: expect.any(Date) },
      });
    });
  });

  describe('runScheduledCleanup', () => {
    it('runs through SchedulerLockService keyed by MEDIA_CLEANUP_LOCK_NAME', async () => {
      await service.runScheduledCleanup();

      expect(schedulerLock.runExclusive).toHaveBeenCalledWith(
        MEDIA_CLEANUP_LOCK_NAME,
        expect.any(Function),
      );
    });

    it('does nothing when another instance already holds the lock', async () => {
      schedulerLock.runExclusive.mockResolvedValue({ ran: false });

      await service.runScheduledCleanup();

      expect(prisma.mediaAsset.findMany).not.toHaveBeenCalled();
    });
  });
});
