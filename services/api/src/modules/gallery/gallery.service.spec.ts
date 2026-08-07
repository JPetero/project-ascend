import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { MediaService } from '../media/media.service';
import { GalleryService } from './gallery.service';

describe('GalleryService', () => {
  let service: GalleryService;
  let prisma: {
    galleryAlbum: {
      findMany: jest.Mock;
      findUnique: jest.Mock;
      create: jest.Mock;
      update: jest.Mock;
      delete: jest.Mock;
    };
    galleryMedia: {
      findMany: jest.Mock;
      findUnique: jest.Mock;
      create: jest.Mock;
      delete: jest.Mock;
    };
    mediaUsage: { deleteMany: jest.Mock; count: jest.Mock };
    communityProfile: { findUnique: jest.Mock; update: jest.Mock; count: jest.Mock };
    $transaction: jest.Mock;
  };
  let mediaService: {
    getById: jest.Mock;
    getObjectUrl: jest.Mock;
    attachUsage: jest.Mock;
    deleteAsset: jest.Mock;
  };

  beforeEach(async () => {
    prisma = {
      galleryAlbum: {
        findMany: jest.fn(),
        findUnique: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
      },
      galleryMedia: {
        findMany: jest.fn(),
        findUnique: jest.fn(),
        create: jest.fn(),
        delete: jest.fn(),
      },
      mediaUsage: { deleteMany: jest.fn(), count: jest.fn() },
      communityProfile: { findUnique: jest.fn(), update: jest.fn(), count: jest.fn() },
      $transaction: jest.fn((ops: unknown[]) => Promise.resolve(ops)),
    };
    mediaService = {
      getById: jest.fn(),
      getObjectUrl: jest.fn().mockReturnValue('https://media.example/key.jpg'),
      attachUsage: jest.fn(),
      deleteAsset: jest.fn(),
    };
    prisma.communityProfile.count.mockResolvedValue(0);

    const moduleRef = await Test.createTestingModule({
      providers: [
        GalleryService,
        { provide: PrismaService, useValue: prisma },
        { provide: MediaService, useValue: mediaService },
      ],
    }).compile();

    service = moduleRef.get(GalleryService);
  });

  describe('addMedia', () => {
    it('404s an album the caller does not own', async () => {
      prisma.galleryAlbum.findUnique.mockResolvedValue({ id: 'album-1', ownerId: 'someone-else' });

      await expect(
        service.addMedia('user-1', 'album-1', { mediaAssetId: 'asset-1' }),
      ).rejects.toThrow(NotFoundException);
    });

    it('rejects a media asset the caller does not own', async () => {
      prisma.galleryAlbum.findUnique.mockResolvedValue({ id: 'album-1', ownerId: 'user-1' });
      mediaService.getById.mockResolvedValue({ ownerId: 'someone-else', processingState: 'READY' });

      await expect(
        service.addMedia('user-1', 'album-1', { mediaAssetId: 'asset-1' }),
      ).rejects.toThrow(NotFoundException);
    });

    it('rejects an asset that has not finished processing', async () => {
      prisma.galleryAlbum.findUnique.mockResolvedValue({ id: 'album-1', ownerId: 'user-1' });
      mediaService.getById.mockResolvedValue({ ownerId: 'user-1', processingState: 'PENDING' });

      await expect(
        service.addMedia('user-1', 'album-1', { mediaAssetId: 'asset-1' }),
      ).rejects.toThrow(BadRequestException);
    });

    it('creates the gallery entry and attaches a GALLERY media usage', async () => {
      prisma.galleryAlbum.findUnique.mockResolvedValue({ id: 'album-1', ownerId: 'user-1' });
      mediaService.getById.mockResolvedValue({
        ownerId: 'user-1',
        processingState: 'READY',
        storageKey: 'key.jpg',
      });
      prisma.galleryMedia.create.mockResolvedValue({ id: 'media-1', mediaAssetId: 'asset-1' });

      const result = await service.addMedia('user-1', 'album-1', {
        mediaAssetId: 'asset-1',
        note: 'front pose',
      });

      expect(mediaService.attachUsage).toHaveBeenCalledWith('asset-1', 'GALLERY', 'media-1');
      expect(result.url).toBe('https://media.example/key.jpg');
    });
  });

  describe('removeMedia — safe deletion', () => {
    it('does not delete the underlying asset while another usage still references it', async () => {
      prisma.galleryMedia.findUnique.mockResolvedValue({
        id: 'media-1',
        mediaAssetId: 'asset-1',
        album: { ownerId: 'user-1' },
      });
      prisma.mediaUsage.count.mockResolvedValue(1); // still attached to a Community post

      await service.removeMedia('user-1', 'media-1');

      expect(mediaService.deleteAsset).not.toHaveBeenCalled();
    });

    it('deletes the underlying asset once nothing else references it', async () => {
      prisma.galleryMedia.findUnique.mockResolvedValue({
        id: 'media-1',
        mediaAssetId: 'asset-1',
        album: { ownerId: 'user-1' },
      });
      prisma.mediaUsage.count.mockResolvedValue(0);
      prisma.communityProfile.count.mockResolvedValue(0);

      await service.removeMedia('user-1', 'media-1');

      expect(mediaService.deleteAsset).toHaveBeenCalledWith('user-1', 'asset-1');
    });

    it('does not delete the asset if it is still set as a profile avatar/cover', async () => {
      prisma.galleryMedia.findUnique.mockResolvedValue({
        id: 'media-1',
        mediaAssetId: 'asset-1',
        album: { ownerId: 'user-1' },
      });
      prisma.mediaUsage.count.mockResolvedValue(0);
      prisma.communityProfile.count.mockResolvedValue(1);

      await service.removeMedia('user-1', 'media-1');

      expect(mediaService.deleteAsset).not.toHaveBeenCalled();
    });

    it('404s gallery media belonging to someone else', async () => {
      prisma.galleryMedia.findUnique.mockResolvedValue({
        id: 'media-1',
        mediaAssetId: 'asset-1',
        album: { ownerId: 'someone-else' },
      });

      await expect(service.removeMedia('user-1', 'media-1')).rejects.toThrow(NotFoundException);
    });
  });

  describe('setAsAvatar / setAsCover', () => {
    it('requires a Community profile to already exist', async () => {
      prisma.galleryMedia.findUnique.mockResolvedValue({
        id: 'media-1',
        mediaAssetId: 'asset-1',
        album: { ownerId: 'user-1' },
      });
      prisma.communityProfile.findUnique.mockResolvedValue(null);

      await expect(service.setAsAvatar('user-1', 'media-1')).rejects.toThrow(BadRequestException);
    });

    it('sets the profile avatarMediaAssetId and attaches PROFILE_AVATAR usage', async () => {
      prisma.galleryMedia.findUnique.mockResolvedValue({
        id: 'media-1',
        mediaAssetId: 'asset-1',
        album: { ownerId: 'user-1' },
      });
      prisma.communityProfile.findUnique.mockResolvedValue({ id: 'profile-1', userId: 'user-1' });

      await service.setAsAvatar('user-1', 'media-1');

      expect(prisma.communityProfile.update).toHaveBeenCalledWith({
        where: { userId: 'user-1' },
        data: { avatarMediaAssetId: 'asset-1' },
      });
      expect(mediaService.attachUsage).toHaveBeenCalledWith(
        'asset-1',
        'PROFILE_AVATAR',
        'profile-1',
      );
    });

    it('sets the profile coverMediaAssetId and attaches PROFILE_COVER usage', async () => {
      prisma.galleryMedia.findUnique.mockResolvedValue({
        id: 'media-1',
        mediaAssetId: 'asset-1',
        album: { ownerId: 'user-1' },
      });
      prisma.communityProfile.findUnique.mockResolvedValue({ id: 'profile-1', userId: 'user-1' });

      await service.setAsCover('user-1', 'media-1');

      expect(prisma.communityProfile.update).toHaveBeenCalledWith({
        where: { userId: 'user-1' },
        data: { coverMediaAssetId: 'asset-1' },
      });
      expect(mediaService.attachUsage).toHaveBeenCalledWith(
        'asset-1',
        'PROFILE_COVER',
        'profile-1',
      );
    });
  });

  describe('deleteAlbum', () => {
    it('404s an album the caller does not own', async () => {
      prisma.galleryAlbum.findUnique.mockResolvedValue({ id: 'album-1', ownerId: 'someone-else' });

      await expect(service.deleteAlbum('user-1', 'album-1')).rejects.toThrow(NotFoundException);
    });

    it('safely deletes each media item, skipping still-referenced assets', async () => {
      prisma.galleryAlbum.findUnique.mockResolvedValue({ id: 'album-1', ownerId: 'user-1' });
      prisma.galleryMedia.findMany.mockResolvedValue([
        { id: 'media-1', mediaAssetId: 'asset-1' },
        { id: 'media-2', mediaAssetId: 'asset-2' },
      ]);
      prisma.mediaUsage.count.mockImplementation(({ where }: { where: { mediaAssetId: string } }) =>
        Promise.resolve(where.mediaAssetId === 'asset-1' ? 1 : 0),
      );

      await service.deleteAlbum('user-1', 'album-1');

      expect(mediaService.deleteAsset).toHaveBeenCalledTimes(1);
      expect(mediaService.deleteAsset).toHaveBeenCalledWith('user-1', 'asset-2');
    });
  });

  describe('createAlbum', () => {
    it('creates an album owned by the caller', async () => {
      prisma.galleryAlbum.create.mockResolvedValue({
        id: 'album-1',
        ownerId: 'user-1',
        name: 'Progress',
        category: 'PROGRESS',
        visibility: 'PRIVATE',
      });

      const result = await service.createAlbum('user-1', { name: 'Progress' });

      expect(prisma.galleryAlbum.create).toHaveBeenCalledWith(
        expect.objectContaining({ data: expect.objectContaining({ ownerId: 'user-1' }) }),
      );
      expect(result.mediaCount).toBe(0);
    });
  });
});
