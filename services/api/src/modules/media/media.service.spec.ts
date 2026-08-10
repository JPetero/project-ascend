import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { MediaService } from './media.service';
import { MEDIA_STORAGE_PROVIDER } from './storage/media-storage.provider';
import { LocalDevelopmentStorageProvider } from './storage/local-development-storage.provider';

function asset(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    id: 'asset-1',
    ownerId: 'user-1',
    mediaType: 'PROFILE_IMAGE',
    originalFilename: 'photo.jpg',
    mimeType: 'image/jpeg',
    sizeBytes: 1000,
    width: 100,
    height: 100,
    durationSeconds: null,
    storageKey: 'user-1/profile_image/key.jpg',
    visibility: 'PRIVATE',
    processingState: 'PENDING',
    moderationState: 'PENDING',
    retentionState: 'ACTIVE',
    deletedAt: null,
    ...overrides,
  };
}

describe('MediaService', () => {
  let service: MediaService;
  let prisma: {
    mediaAsset: {
      create: jest.Mock;
      findUnique: jest.Mock;
      findMany: jest.Mock;
      update: jest.Mock;
    };
    mediaUpload: { create: jest.Mock; findUnique: jest.Mock; update: jest.Mock };
    mediaVariant: { create: jest.Mock; findMany: jest.Mock };
    mediaModerationResult: { create: jest.Mock };
    mediaUsage: { create: jest.Mock };
    communityReport: { create: jest.Mock };
    $transaction: jest.Mock;
  };
  let storage: {
    createUploadTarget: jest.Mock;
    getObjectUrl: jest.Mock;
    getSignedGetUrl: jest.Mock;
    deleteObject: jest.Mock;
    objectExists: jest.Mock;
  };
  let localStorage: { writeObject: jest.Mock; readObject: jest.Mock };

  beforeEach(async () => {
    prisma = {
      mediaAsset: {
        create: jest.fn(),
        findUnique: jest.fn(),
        findMany: jest.fn(),
        update: jest.fn(),
      },
      mediaUpload: { create: jest.fn(), findUnique: jest.fn(), update: jest.fn() },
      mediaVariant: { create: jest.fn(), findMany: jest.fn().mockResolvedValue([]) },
      mediaModerationResult: { create: jest.fn() },
      mediaUsage: { create: jest.fn() },
      communityReport: { create: jest.fn() },
      $transaction: jest.fn((ops: unknown[]) => Promise.all(ops)),
    };
    storage = {
      createUploadTarget: jest.fn().mockResolvedValue({
        method: 'POST',
        url: '/media/uploads/asset-1/local-bytes',
        expiresAt: new Date(Date.now() + 60_000),
      }),
      getObjectUrl: jest.fn().mockReturnValue('/media/objects/key'),
      getSignedGetUrl: jest.fn().mockResolvedValue('/media/objects?key=signed'),
      deleteObject: jest.fn().mockResolvedValue(undefined),
      objectExists: jest.fn().mockResolvedValue(true),
    };
    localStorage = {
      writeObject: jest.fn().mockResolvedValue(undefined),
      readObject: jest.fn().mockResolvedValue(Buffer.from('bytes')),
    };

    const moduleRef = await Test.createTestingModule({
      providers: [
        MediaService,
        { provide: PrismaService, useValue: prisma },
        { provide: MEDIA_STORAGE_PROVIDER, useValue: storage },
        { provide: LocalDevelopmentStorageProvider, useValue: localStorage },
      ],
    }).compile();

    service = moduleRef.get(MediaService);
  });

  describe('initiateUpload', () => {
    it('rejects a disallowed MIME type for the media type', async () => {
      await expect(
        service.initiateUpload('user-1', {
          mediaType: 'PROFILE_IMAGE' as never,
          originalFilename: 'clip.mp4',
          mimeType: 'video/mp4',
          sizeBytes: 100,
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('rejects a file over the size limit', async () => {
      await expect(
        service.initiateUpload('user-1', {
          mediaType: 'PROFILE_IMAGE' as never,
          originalFilename: 'photo.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 999_999_999,
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('rejects a Reel over the duration limit', async () => {
      await expect(
        service.initiateUpload('user-1', {
          mediaType: 'COMMUNITY_REEL' as never,
          originalFilename: 'clip.mp4',
          mimeType: 'video/mp4',
          sizeBytes: 1000,
          durationSeconds: 200,
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('creates an asset and upload row, and returns a storage upload target', async () => {
      prisma.mediaAsset.create.mockResolvedValue(asset());
      prisma.mediaUpload.create.mockResolvedValue({});

      const result = await service.initiateUpload('user-1', {
        mediaType: 'PROFILE_IMAGE' as never,
        originalFilename: 'photo.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 1000,
        width: 100,
        height: 100,
      });

      expect(prisma.mediaAsset.create).toHaveBeenCalled();
      expect(storage.createUploadTarget).toHaveBeenCalled();
      expect(result.uploadTarget.method).toBe('POST');
    });
  });

  describe('completeUpload', () => {
    it('404s when the caller does not own the asset', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(asset({ ownerId: 'someone-else' }));
      await expect(service.completeUpload('user-1', 'asset-1')).rejects.toThrow(NotFoundException);
    });

    it('rejects completing an upload that was already completed', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(asset());
      prisma.mediaUpload.findUnique.mockResolvedValue({
        state: 'COMPLETED',
        expiresAt: new Date(Date.now() + 60_000),
      });
      await expect(service.completeUpload('user-1', 'asset-1')).rejects.toThrow(
        BadRequestException,
      );
    });

    it('rejects an expired upload contract', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(asset());
      prisma.mediaUpload.findUnique.mockResolvedValue({
        state: 'INITIATED',
        expiresAt: new Date(Date.now() - 60_000),
      });
      prisma.mediaUpload.update.mockResolvedValue({});

      await expect(service.completeUpload('user-1', 'asset-1')).rejects.toThrow(
        BadRequestException,
      );
      expect(prisma.mediaUpload.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: { state: 'EXPIRED' } }),
      );
    });

    it('rejects completion when the object was never actually received by storage', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(asset());
      prisma.mediaUpload.findUnique.mockResolvedValue({
        state: 'INITIATED',
        expiresAt: new Date(Date.now() + 60_000),
      });
      storage.objectExists.mockResolvedValue(false);

      await expect(service.completeUpload('user-1', 'asset-1')).rejects.toThrow(
        BadRequestException,
      );
    });

    it('marks the asset READY and APPROVED on successful completion', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(asset());
      prisma.mediaUpload.findUnique.mockResolvedValue({
        state: 'INITIATED',
        expiresAt: new Date(Date.now() + 60_000),
      });
      prisma.mediaAsset.update.mockResolvedValue(
        asset({ processingState: 'READY', moderationState: 'APPROVED' }),
      );

      const result = await service.completeUpload('user-1', 'asset-1');

      expect(prisma.mediaVariant.create).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ variantType: 'ORIGINAL' }) }),
      );
      expect(prisma.mediaModerationResult.create).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ status: 'APPROVED' }) }),
      );
      expect(result.moderationState).toBe('APPROVED');
    });
  });

  describe('receiveLocalBytes', () => {
    it('rejects a payload larger than the declared limit', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(asset());
      prisma.mediaUpload.findUnique.mockResolvedValue({
        state: 'INITIATED',
        expiresAt: new Date(Date.now() + 60_000),
      });

      const oversized = Buffer.alloc(6 * 1024 * 1024);
      await expect(service.receiveLocalBytes('user-1', 'asset-1', oversized)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('rejects bytes whose signature does not match the declared MIME type', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(asset());
      prisma.mediaUpload.findUnique.mockResolvedValue({
        state: 'INITIATED',
        expiresAt: new Date(Date.now() + 60_000),
      });

      const notAJpeg = Buffer.from('this is definitely not a jpeg', 'ascii');
      await expect(service.receiveLocalBytes('user-1', 'asset-1', notAJpeg)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('writes valid bytes and completes the upload', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(asset());
      prisma.mediaUpload.findUnique.mockResolvedValue({
        state: 'INITIATED',
        expiresAt: new Date(Date.now() + 60_000),
      });
      prisma.mediaAsset.update.mockResolvedValue(asset({ processingState: 'READY' }));

      const validJpeg = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10]);
      await service.receiveLocalBytes('user-1', 'asset-1', validJpeg);

      expect(localStorage.writeObject).toHaveBeenCalledWith(asset().storageKey, validJpeg);
    });
  });

  describe('getById', () => {
    it('404s a private asset for a non-owner', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(asset({ visibility: 'PRIVATE' }));
      await expect(service.getById('someone-else', 'asset-1')).rejects.toThrow(NotFoundException);
    });

    it('returns a public asset to a non-owner', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(asset({ visibility: 'PUBLIC' }));
      await expect(service.getById('someone-else', 'asset-1')).resolves.toEqual(
        asset({ visibility: 'PUBLIC' }),
      );
    });

    it('returns a private asset to its owner', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(asset());
      await expect(service.getById('user-1', 'asset-1')).resolves.toEqual(asset());
    });

    it('404s a soft-deleted asset even for its owner', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(asset({ retentionState: 'DELETED' }));
      await expect(service.getById('user-1', 'asset-1')).rejects.toThrow(NotFoundException);
    });
  });

  describe('getPrivateUrl', () => {
    it('delegates to a time-limited signed URL, not the permanent object URL', async () => {
      const url = await service.getPrivateUrl('user-1/gallery/key.jpg');

      expect(storage.getSignedGetUrl).toHaveBeenCalledWith(
        'user-1/gallery/key.jpg',
        expect.any(Number),
      );
      expect(storage.getObjectUrl).not.toHaveBeenCalled();
      expect(url).toBe('/media/objects?key=signed');
    });
  });

  describe('readLocalObject', () => {
    it('404s a private object for a non-owner', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(asset({ visibility: 'PRIVATE' }));
      await expect(service.readLocalObject('someone-else', asset().storageKey)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('returns bytes for the owner of a private object', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(asset({ visibility: 'PRIVATE' }));
      const result = await service.readLocalObject('user-1', asset().storageKey);
      expect(result.buffer).toEqual(Buffer.from('bytes'));
      expect(result.mimeType).toBe('image/jpeg');
    });

    it('returns bytes for a non-owner when the object is not private', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(asset({ visibility: 'PUBLIC' }));
      await expect(service.readLocalObject('someone-else', asset().storageKey)).resolves.toEqual({
        buffer: Buffer.from('bytes'),
        mimeType: 'image/jpeg',
      });
    });

    it('404s an object with no matching MediaAsset row', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(null);
      await expect(service.readLocalObject('user-1', 'missing-key')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('404s a soft-deleted object even for its owner', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(asset({ retentionState: 'DELETED' }));
      await expect(service.readLocalObject('user-1', asset().storageKey)).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('deleteAsset', () => {
    it('404s when the caller does not own the asset', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(asset({ ownerId: 'someone-else' }));
      await expect(service.deleteAsset('user-1', 'asset-1')).rejects.toThrow(NotFoundException);
    });

    it('deletes storage objects and soft-deletes the asset row', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(asset());
      prisma.mediaVariant.findMany.mockResolvedValue([{ storageKey: 'variant-key' }]);
      prisma.mediaAsset.update.mockResolvedValue(asset({ retentionState: 'DELETED' }));

      await service.deleteAsset('user-1', 'asset-1');

      expect(storage.deleteObject).toHaveBeenCalledWith(asset().storageKey);
      expect(storage.deleteObject).toHaveBeenCalledWith('variant-key');
      expect(prisma.mediaAsset.update).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ retentionState: 'DELETED' }) }),
      );
    });
  });

  describe('attachUsage', () => {
    it('404s a missing asset', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(null);
      await expect(
        service.attachUsage('missing', 'COMMUNITY_POST' as never, 'post-1'),
      ).rejects.toThrow(NotFoundException);
    });

    it('rejects attaching an asset that is not yet READY', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(asset({ processingState: 'PENDING' }));
      await expect(
        service.attachUsage('asset-1', 'COMMUNITY_POST' as never, 'post-1'),
      ).rejects.toThrow(BadRequestException);
    });

    it('rejects attaching a removed asset', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(
        asset({ processingState: 'READY', moderationState: 'REMOVED' }),
      );
      await expect(
        service.attachUsage('asset-1', 'COMMUNITY_POST' as never, 'post-1'),
      ).rejects.toThrow(ForbiddenException);
    });

    it('attaches a ready, approved asset', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(
        asset({ processingState: 'READY', moderationState: 'APPROVED' }),
      );
      const usage = { id: 'usage-1' };
      prisma.mediaUsage.create.mockResolvedValue(usage);

      await expect(
        service.attachUsage('asset-1', 'COMMUNITY_POST' as never, 'post-1'),
      ).resolves.toEqual(usage);
    });
  });

  describe('reportAsset', () => {
    it('404s a missing asset', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(null);
      await expect(service.reportAsset('reporter-1', 'missing', 'inappropriate')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('creates a MEDIA_ASSET report', async () => {
      prisma.mediaAsset.findUnique.mockResolvedValue(asset());
      prisma.communityReport.create.mockResolvedValue({
        id: 'report-1',
        status: 'OPEN',
        createdAt: new Date(),
      });

      const result = await service.reportAsset('reporter-1', 'asset-1', 'inappropriate');

      expect(prisma.communityReport.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ targetType: 'MEDIA_ASSET', targetId: 'asset-1' }),
        }),
      );
      expect(result.id).toBe('report-1');
    });
  });
});
