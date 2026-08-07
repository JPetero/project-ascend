import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { ALLOWED_EXTENSIONS_BY_MIME_TYPE, MEDIA_LIMITS } from '../../common/policy/media-policy';
import { fileSignatureMatchesMimeType } from '../../common/media/media-file-signature.util';
import { InitiateUploadDto } from './dto/initiate-upload.dto';
import { MEDIA_STORAGE_PROVIDER, MediaStorageProvider } from './storage/media-storage.provider';
import { LocalDevelopmentStorageProvider } from './storage/local-development-storage.provider';
import { MediaUsageType, MediaVisibility } from '@prisma/client';

/**
 * The shared Media Platform (Build Session 8 Part 2) — every feature
 * that accepts a photo/video (Community, Trainer Groups chat, Fuel,
 * Vision, profile) goes through this service rather than inventing its
 * own upload handling. See `MEDIA_LIMITS` for per-type validation and
 * `MediaStorageProvider` for the swappable storage backend.
 */
@Injectable()
export class MediaService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(MEDIA_STORAGE_PROVIDER) private readonly storage: MediaStorageProvider,
    private readonly localStorage: LocalDevelopmentStorageProvider,
  ) {}

  async initiateUpload(ownerId: string, dto: InitiateUploadDto) {
    const limit = MEDIA_LIMITS[dto.mediaType];

    if (!limit.allowedMimeTypes.includes(dto.mimeType)) {
      throw new BadRequestException(`${dto.mimeType} is not allowed for ${dto.mediaType}.`);
    }
    if (dto.sizeBytes > limit.maxSizeBytes) {
      throw new BadRequestException(
        `File exceeds the ${Math.round(limit.maxSizeBytes / (1024 * 1024))}MB limit for ${dto.mediaType}.`,
      );
    }
    if (limit.maxWidth && dto.width && dto.width > limit.maxWidth) {
      throw new BadRequestException(`Width exceeds the ${limit.maxWidth}px limit.`);
    }
    if (limit.maxHeight && dto.height && dto.height > limit.maxHeight) {
      throw new BadRequestException(`Height exceeds the ${limit.maxHeight}px limit.`);
    }
    if (
      limit.maxDurationSeconds &&
      dto.durationSeconds &&
      dto.durationSeconds > limit.maxDurationSeconds
    ) {
      throw new BadRequestException(`Duration exceeds the ${limit.maxDurationSeconds}s limit.`);
    }

    const extension = this.extensionFor(dto.mimeType, dto.originalFilename);
    const storageKey = `${ownerId}/${dto.mediaType.toLowerCase()}/${randomUUID()}${extension}`;

    const asset = await this.prisma.mediaAsset.create({
      data: {
        ownerId,
        mediaType: dto.mediaType,
        originalFilename: dto.originalFilename,
        mimeType: dto.mimeType,
        sizeBytes: dto.sizeBytes,
        width: dto.width,
        height: dto.height,
        durationSeconds: dto.durationSeconds,
        storageKey,
      },
    });

    const uploadTarget = await this.storage.createUploadTarget({
      storageKey,
      mimeType: dto.mimeType,
    });

    await this.prisma.mediaUpload.create({
      data: {
        mediaAssetId: asset.id,
        storageProvider: uploadTarget.method === 'PUT' ? 's3' : 'local',
        uploadMethod: uploadTarget.method,
        expiresAt: uploadTarget.expiresAt,
      },
    });

    return { mediaAsset: asset, uploadTarget };
  }

  /** Local-dev-only direct write path — mirrors what a real S3 PUT does, then completes the upload. */
  async receiveLocalBytes(ownerId: string, mediaAssetId: string, buffer: Buffer): Promise<void> {
    const asset = await this.loadOwnedPendingAsset(ownerId, mediaAssetId);
    const limit = MEDIA_LIMITS[asset.mediaType];

    if (buffer.length > limit.maxSizeBytes) {
      throw new BadRequestException('Uploaded file exceeds the declared size limit.');
    }
    if (!fileSignatureMatchesMimeType(buffer, asset.mimeType)) {
      throw new BadRequestException('File contents do not match the declared file type.');
    }

    await this.localStorage.writeObject(asset.storageKey, buffer);
    await this.completeUpload(ownerId, mediaAssetId);
  }

  async completeUpload(ownerId: string, mediaAssetId: string) {
    const asset = await this.loadOwnedPendingAsset(ownerId, mediaAssetId);

    const exists = await this.storage.objectExists(asset.storageKey);
    if (!exists) {
      throw new BadRequestException('Upload has not been received by storage yet.');
    }

    const [, , updated] = await this.prisma.$transaction([
      this.prisma.mediaUpload.update({
        where: { mediaAssetId },
        data: { state: 'COMPLETED', completedAt: new Date() },
      }),
      this.prisma.mediaVariant.create({
        data: {
          mediaAssetId,
          variantType: 'ORIGINAL',
          storageKey: asset.storageKey,
          width: asset.width,
          height: asset.height,
          sizeBytes: asset.sizeBytes,
          mimeType: asset.mimeType,
        },
      }),
      this.prisma.mediaAsset.update({
        where: { id: mediaAssetId },
        data: { processingState: 'READY', moderationState: 'APPROVED' },
      }),
      this.prisma.mediaModerationResult.create({
        data: {
          mediaAssetId,
          status: 'APPROVED',
          reasonCode: 'AUTO_APPROVED_NO_CLASSIFIER',
        },
      }),
    ]);

    return updated;
  }

  async getById(userId: string, mediaAssetId: string) {
    const asset = await this.prisma.mediaAsset.findUnique({ where: { id: mediaAssetId } });
    if (!asset || asset.retentionState === 'DELETED') {
      throw new NotFoundException('Media asset not found.');
    }
    const isOwner = asset.ownerId === userId;
    const isVisible = asset.visibility !== 'PRIVATE';
    if (!isOwner && !isVisible) {
      throw new NotFoundException('Media asset not found.');
    }
    return asset;
  }

  async listMine(ownerId: string) {
    return this.prisma.mediaAsset.findMany({
      where: { ownerId, retentionState: { not: 'DELETED' } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async setVisibility(ownerId: string, mediaAssetId: string, visibility: MediaVisibility) {
    const asset = await this.assertOwned(ownerId, mediaAssetId);
    return this.prisma.mediaAsset.update({ where: { id: asset.id }, data: { visibility } });
  }

  async deleteAsset(ownerId: string, mediaAssetId: string): Promise<void> {
    const asset = await this.assertOwned(ownerId, mediaAssetId);

    await this.storage.deleteObject(asset.storageKey);
    const variants = await this.prisma.mediaVariant.findMany({ where: { mediaAssetId } });
    await Promise.all(variants.map((variant) => this.storage.deleteObject(variant.storageKey)));

    await this.prisma.mediaAsset.update({
      where: { id: mediaAssetId },
      data: { retentionState: 'DELETED', deletedAt: new Date() },
    });
  }

  /** Called in-process by other modules once their own record (a Community post, a chat message, …) references this asset. */
  async attachUsage(mediaAssetId: string, usageType: MediaUsageType, referenceId: string) {
    const asset = await this.prisma.mediaAsset.findUnique({ where: { id: mediaAssetId } });
    if (!asset || asset.retentionState === 'DELETED') {
      throw new NotFoundException('Media asset not found.');
    }
    if (asset.processingState !== 'READY') {
      throw new BadRequestException('Media asset is not ready to attach.');
    }
    if (asset.moderationState === 'REJECTED' || asset.moderationState === 'REMOVED') {
      throw new ForbiddenException('This media cannot be attached.');
    }
    return this.prisma.mediaUsage.create({ data: { mediaAssetId, usageType, referenceId } });
  }

  async reportAsset(reporterId: string, mediaAssetId: string, reason: string) {
    const asset = await this.prisma.mediaAsset.findUnique({ where: { id: mediaAssetId } });
    if (!asset || asset.retentionState === 'DELETED') {
      throw new NotFoundException('Media asset not found.');
    }
    const report = await this.prisma.communityReport.create({
      data: { reporterId, targetType: 'MEDIA_ASSET', targetId: mediaAssetId, reason },
    });
    return { id: report.id, status: report.status, createdAt: report.createdAt };
  }

  getObjectUrl(storageKey: string): string {
    return this.storage.getObjectUrl(storageKey);
  }

  private async assertOwned(ownerId: string, mediaAssetId: string) {
    const asset = await this.prisma.mediaAsset.findUnique({ where: { id: mediaAssetId } });
    if (!asset || asset.ownerId !== ownerId || asset.retentionState === 'DELETED') {
      throw new NotFoundException('Media asset not found.');
    }
    return asset;
  }

  private async loadOwnedPendingAsset(ownerId: string, mediaAssetId: string) {
    const asset = await this.assertOwned(ownerId, mediaAssetId);
    const upload = await this.prisma.mediaUpload.findUnique({ where: { mediaAssetId } });
    if (!upload || upload.state !== 'INITIATED') {
      throw new BadRequestException(
        'This upload has already been completed or is no longer valid.',
      );
    }
    if (upload.expiresAt < new Date()) {
      await this.prisma.mediaUpload.update({ where: { mediaAssetId }, data: { state: 'EXPIRED' } });
      throw new BadRequestException('This upload contract has expired — start a new upload.');
    }
    return asset;
  }

  private extensionFor(mimeType: string, originalFilename: string): string {
    const known = ALLOWED_EXTENSIONS_BY_MIME_TYPE[mimeType];
    if (known?.length) return known[0];
    const dotIndex = originalFilename.lastIndexOf('.');
    return dotIndex >= 0 ? originalFilename.slice(dotIndex) : '';
  }
}
