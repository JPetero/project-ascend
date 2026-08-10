import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { GalleryCategory } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { MediaService } from '../media/media.service';
import { AddGalleryMediaDto } from './dto/add-gallery-media.dto';
import { CreateGalleryAlbumDto } from './dto/create-gallery-album.dto';
import { UpdateGalleryAlbumDto } from './dto/update-gallery-album.dto';

/**
 * A private-by-default personal gallery — Build Session 9 Part 2. Owns no
 * storage of its own: every item is a MediaAsset already uploaded through
 * the shared Media Platform (media.service.ts), referenced here the same
 * way a Community post or chat message references one. Deleting a
 * gallery item never blindly deletes the underlying MediaAsset — see
 * `safeDeleteAssetIfUnused` — because the same photo may still be
 * attached to a Community post, a chat message, or a profile avatar/
 * cover; only once nothing references it anymore does the object itself
 * get removed.
 */
@Injectable()
export class GalleryService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly mediaService: MediaService,
  ) {}

  async listAlbums(ownerId: string) {
    const albums = await this.prisma.galleryAlbum.findMany({
      where: { ownerId },
      orderBy: { createdAt: 'desc' },
      include: { _count: { select: { media: true } } },
    });
    return albums.map((album) => ({
      id: album.id,
      name: album.name,
      category: album.category,
      visibility: album.visibility,
      mediaCount: album._count.media,
      createdAt: album.createdAt,
      updatedAt: album.updatedAt,
    }));
  }

  async createAlbum(ownerId: string, dto: CreateGalleryAlbumDto) {
    // Build Session 13 continuation Part C (Privacy Center) — an
    // omitted `visibility` used to fall straight through to the Prisma
    // column's own PRIVATE default, which no per-user preference could
    // override. Progress albums fall back to their own, independently
    // tightenable default — see Preference.progressPhotoDefaultVisibility's
    // schema comment.
    let visibility = dto.visibility;
    if (!visibility) {
      const preference = await this.prisma.preference.findUnique({
        where: { userId: ownerId },
        select: { defaultGalleryVisibility: true, progressPhotoDefaultVisibility: true },
      });
      visibility =
        dto.category === GalleryCategory.PROGRESS
          ? preference?.progressPhotoDefaultVisibility
          : preference?.defaultGalleryVisibility;
    }

    const album = await this.prisma.galleryAlbum.create({
      data: {
        ownerId,
        name: dto.name,
        category: dto.category ?? undefined,
        visibility: visibility ?? undefined,
      },
    });
    return { ...album, mediaCount: 0 };
  }

  async getAlbum(ownerId: string, albumId: string) {
    const album = await this.loadOwnedAlbum(ownerId, albumId);
    const media = await this.prisma.galleryMedia.findMany({
      where: { albumId },
      orderBy: { createdAt: 'desc' },
      include: { mediaAsset: { select: { storageKey: true, mediaType: true } } },
    });
    return {
      id: album.id,
      name: album.name,
      category: album.category,
      visibility: album.visibility,
      createdAt: album.createdAt,
      updatedAt: album.updatedAt,
      media: await Promise.all(media.map((item) => this.serializeMedia(item))),
    };
  }

  async updateAlbum(ownerId: string, albumId: string, dto: UpdateGalleryAlbumDto) {
    await this.loadOwnedAlbum(ownerId, albumId);
    const album = await this.prisma.galleryAlbum.update({
      where: { id: albumId },
      data: {
        name: dto.name ?? undefined,
        category: dto.category ?? undefined,
        visibility: dto.visibility ?? undefined,
      },
    });
    return album;
  }

  async deleteAlbum(ownerId: string, albumId: string): Promise<void> {
    await this.loadOwnedAlbum(ownerId, albumId);
    const mediaItems = await this.prisma.galleryMedia.findMany({ where: { albumId } });

    await this.prisma.$transaction([
      this.prisma.mediaUsage.deleteMany({
        where: { usageType: 'GALLERY', referenceId: { in: mediaItems.map((m) => m.id) } },
      }),
      // Cascades the GalleryMedia rows themselves (onDelete: Cascade).
      this.prisma.galleryAlbum.delete({ where: { id: albumId } }),
    ]);

    for (const item of mediaItems) {
      await this.safeDeleteAssetIfUnused(ownerId, item.mediaAssetId);
    }
  }

  async addMedia(ownerId: string, albumId: string, dto: AddGalleryMediaDto) {
    await this.loadOwnedAlbum(ownerId, albumId);
    const asset = await this.mediaService.getById(ownerId, dto.mediaAssetId);
    if (asset.ownerId !== ownerId) {
      throw new NotFoundException('Media asset not found.');
    }
    if (asset.processingState !== 'READY') {
      throw new BadRequestException('This upload has not finished processing yet.');
    }

    const media = await this.prisma.galleryMedia.create({
      data: {
        albumId,
        mediaAssetId: dto.mediaAssetId,
        note: dto.note,
        poseTag: dto.poseTag,
        weightNote: dto.weightNote,
        capturedAt: dto.capturedAt ? new Date(dto.capturedAt) : undefined,
      },
    });
    await this.mediaService.attachUsage(dto.mediaAssetId, 'GALLERY', media.id);

    return this.serializeMedia({ ...media, mediaAsset: asset });
  }

  private async serializeMedia(item: {
    id: string;
    albumId: string;
    mediaAssetId: string;
    note: string | null;
    poseTag: string | null;
    weightNote: string | null;
    capturedAt: Date | null;
    createdAt: Date;
    mediaAsset: { storageKey: string; mediaType?: string };
  }) {
    return {
      id: item.id,
      albumId: item.albumId,
      mediaAssetId: item.mediaAssetId,
      // Build Session 12 Part 18-21 — a time-limited signed URL, not the
      // permanent link getObjectUrl hands out: every gallery item is a
      // PRIVATE-visibility MediaAsset by default (this is a "private-by-
      // default personal gallery" — see this class's own doc comment),
      // so its underlying object must never resolve forever if the URL
      // leaks. See MediaService.getPrivateUrl's doc comment.
      url: await this.mediaService.getPrivateUrl(item.mediaAsset.storageKey),
      note: item.note,
      poseTag: item.poseTag,
      weightNote: item.weightNote,
      capturedAt: item.capturedAt,
      createdAt: item.createdAt,
    };
  }

  async removeMedia(ownerId: string, mediaId: string): Promise<void> {
    const media = await this.loadOwnedMedia(ownerId, mediaId);

    await this.prisma.$transaction([
      this.prisma.mediaUsage.deleteMany({ where: { usageType: 'GALLERY', referenceId: mediaId } }),
      this.prisma.galleryMedia.delete({ where: { id: mediaId } }),
    ]);

    await this.safeDeleteAssetIfUnused(ownerId, media.mediaAssetId);
  }

  /** Sets a gallery photo as the caller's Community profile avatar. */
  async setAsAvatar(ownerId: string, mediaId: string) {
    const media = await this.loadOwnedMedia(ownerId, mediaId);
    const profile = await this.assertOwnCommunityProfile(ownerId);
    await this.prisma.communityProfile.update({
      where: { userId: ownerId },
      data: { avatarMediaAssetId: media.mediaAssetId },
    });
    await this.mediaService.attachUsage(media.mediaAssetId, 'PROFILE_AVATAR', profile.id);
  }

  /** Sets a gallery photo as the caller's Community profile cover image. */
  async setAsCover(ownerId: string, mediaId: string) {
    const media = await this.loadOwnedMedia(ownerId, mediaId);
    const profile = await this.assertOwnCommunityProfile(ownerId);
    await this.prisma.communityProfile.update({
      where: { userId: ownerId },
      data: { coverMediaAssetId: media.mediaAssetId },
    });
    await this.mediaService.attachUsage(media.mediaAssetId, 'PROFILE_COVER', profile.id);
  }

  private async assertOwnCommunityProfile(ownerId: string) {
    const profile = await this.prisma.communityProfile.findUnique({ where: { userId: ownerId } });
    if (!profile) {
      throw new BadRequestException(
        'Create your Community profile before setting an avatar or cover.',
      );
    }
    return profile;
  }

  /**
   * Called after removing a gallery reference to a MediaAsset — deletes
   * the underlying object only if nothing else (a Community post, a
   * chat message, a profile avatar/cover, another gallery entry) still
   * references it. This is what makes "deleting a Community post must
   * not unexpectedly delete a private original" true in both
   * directions: removing either side alone never touches the asset
   * while the other side still needs it.
   */
  private async safeDeleteAssetIfUnused(ownerId: string, mediaAssetId: string): Promise<void> {
    const remainingUsages = await this.prisma.mediaUsage.count({ where: { mediaAssetId } });
    if (remainingUsages > 0) return;
    // Also still referenced as a profile avatar/cover — those live on
    // CommunityProfile's own FK column, not a MediaUsage row.
    const stillProfileMedia = await this.prisma.communityProfile.count({
      where: { OR: [{ avatarMediaAssetId: mediaAssetId }, { coverMediaAssetId: mediaAssetId }] },
    });
    if (stillProfileMedia > 0) return;
    await this.mediaService.deleteAsset(ownerId, mediaAssetId);
  }

  private async loadOwnedAlbum(ownerId: string, albumId: string) {
    const album = await this.prisma.galleryAlbum.findUnique({ where: { id: albumId } });
    if (!album || album.ownerId !== ownerId) {
      throw new NotFoundException('Album not found.');
    }
    return album;
  }

  private async loadOwnedMedia(ownerId: string, mediaId: string) {
    const media = await this.prisma.galleryMedia.findUnique({
      where: { id: mediaId },
      include: { album: true },
    });
    if (!media || media.album.ownerId !== ownerId) {
      throw new NotFoundException('Gallery media not found.');
    }
    return media;
  }
}
