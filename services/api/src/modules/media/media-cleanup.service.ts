import { Inject, Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { SchedulerLockService } from '../../common/scheduling/scheduler-lock.service';
import { PrismaService } from '../../prisma/prisma.service';
import { MEDIA_STORAGE_PROVIDER, MediaStorageProvider } from './storage/media-storage.provider';

const MS_PER_HOUR = 60 * 60 * 1000;
const MS_PER_DAY = 24 * MS_PER_HOUR;

/** Name of this job's row in ScheduledJobLock — see SchedulerLockService's doc comment. */
export const MEDIA_CLEANUP_LOCK_NAME = 'media-cleanup';

/** How long an upload contract (15 min per MEDIA_UPLOAD_EXPIRY_MINUTES) can sit expired-and-never-completed before its asset/storage is purged. */
export const ABANDONED_UPLOAD_GRACE_HOURS = 24;
/** How long a fully-uploaded, ready asset can sit unattached to anything before it's considered orphaned. */
export const ORPHANED_MEDIA_GRACE_HOURS = 48;
/** How long a user-deleted (tombstone) MediaAsset row — storage already gone via MediaService.deleteAsset — is kept before its row is purged too. */
export const DELETED_TOMBSTONE_GRACE_DAYS = 30;
/** How long after an account is marked DELETED its remaining (unreferenced) media is cleaned up. */
export const ACCOUNT_DELETION_MEDIA_GRACE_DAYS = 30;

export interface MediaCleanupCounts {
  abandonedUploads: number;
  orphanedMedia: number;
  deletedTombstones: number;
  accountDeletionMedia: number;
}

/**
 * S14 Part 10 — the first real implementation of media retention
 * cleanup; before this, nothing ever reclaimed storage for uploads
 * that were never completed, assets that were uploaded but never
 * attached to anything, or a deleted account's leftover media.
 * `MediaService.deleteAsset` already deletes storage immediately on a
 * user-initiated delete (see its own doc comment), so this service's
 * "deletedTombstones" category is only pruning the now-storage-less DB
 * row after an audit grace period, not a second storage deletion.
 *
 * Every category checks `MediaUsage` before deleting anything —
 * `MediaService.attachUsage` is the one place every consumer
 * (Community, Gallery, Messages, profile avatar/cover) records that a
 * `MediaAsset` is in use, so `usages: { none: {} }` is a reliable
 * "nothing references this" signal. This is a load-bearing invariant:
 * any future feature that attaches a `MediaAsset` to something without
 * calling `attachUsage` would make its media look orphaned to this
 * cleanup even while still in use.
 *
 * There is currently no verification-document media (trainer
 * verification and affordability eligibility — `TrainerVerificationApplication`/
 * `AffordabilityEligibility` — store only free-text/self-attested
 * fields, no uploaded document) or Support-ticket attachment storage in
 * this codebase, so there is nothing to special-case for those
 * categories yet.
 */
@Injectable()
export class MediaCleanupService {
  private readonly logger = new Logger(MediaCleanupService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject(MEDIA_STORAGE_PROVIDER) private readonly storage: MediaStorageProvider,
    private readonly schedulerLock: SchedulerLockService,
  ) {}

  @Cron(CronExpression.EVERY_DAY_AT_3AM, { name: 'media-cleanup' })
  async runScheduledCleanup(): Promise<void> {
    const { ran, result } = await this.schedulerLock.runExclusive(MEDIA_CLEANUP_LOCK_NAME, () =>
      this.runCleanup({ dryRun: false }),
    );
    if (!ran) {
      this.logger.log('Media cleanup: another instance already holds the lock, skipping.');
      return;
    }
    this.logger.log(`Media cleanup: ${JSON.stringify(result)}`);
  }

  /**
   * The real work, safe to call directly (an admin diagnostic endpoint,
   * a one-off script, or a test) with `dryRun: true` to preview counts
   * without deleting anything. Each category is independent.
   */
  async runCleanup({ dryRun }: { dryRun: boolean }): Promise<MediaCleanupCounts> {
    const [abandonedUploads, orphanedMedia, deletedTombstones, accountDeletionMedia] =
      await Promise.all([
        this.cleanAbandonedUploads(dryRun),
        this.cleanOrphanedMedia(dryRun),
        this.cleanDeletedTombstones(dryRun),
        this.cleanAccountDeletionMedia(dryRun),
      ]);
    return { abandonedUploads, orphanedMedia, deletedTombstones, accountDeletionMedia };
  }

  /** Uploads whose 15-minute contract (MEDIA_UPLOAD_EXPIRY_MINUTES) expired long ago and were never completed. */
  private async cleanAbandonedUploads(dryRun: boolean): Promise<number> {
    const cutoff = new Date(Date.now() - ABANDONED_UPLOAD_GRACE_HOURS * MS_PER_HOUR);
    const abandoned = await this.prisma.mediaAsset.findMany({
      where: {
        retentionState: 'ACTIVE',
        upload: {
          state: { in: ['INITIATED', 'FAILED', 'EXPIRED'] },
          expiresAt: { lt: cutoff },
        },
      },
      select: { id: true, storageKey: true },
    });
    if (!dryRun) {
      for (const asset of abandoned) {
        await this.purgeAsset(asset.id, [asset.storageKey]);
      }
    }
    return abandoned.length;
  }

  /** Fully-uploaded assets nobody ever attached to a post, message, gallery album, or profile. */
  private async cleanOrphanedMedia(dryRun: boolean): Promise<number> {
    const cutoff = new Date(Date.now() - ORPHANED_MEDIA_GRACE_HOURS * MS_PER_HOUR);
    const orphaned = await this.prisma.mediaAsset.findMany({
      where: {
        processingState: 'READY',
        retentionState: 'ACTIVE',
        createdAt: { lt: cutoff },
        usages: { none: {} },
      },
      select: { id: true, storageKey: true, variants: { select: { storageKey: true } } },
    });
    if (!dryRun) {
      for (const asset of orphaned) {
        await this.purgeAsset(asset.id, [
          asset.storageKey,
          ...asset.variants.map((variant) => variant.storageKey),
        ]);
      }
    }
    return orphaned.length;
  }

  /** User-deleted tombstone rows — MediaService.deleteAsset already removed the storage objects; this purges the row after a retention/audit window. */
  private async cleanDeletedTombstones(dryRun: boolean): Promise<number> {
    const cutoff = new Date(Date.now() - DELETED_TOMBSTONE_GRACE_DAYS * MS_PER_DAY);
    const tombstones = await this.prisma.mediaAsset.findMany({
      where: { retentionState: 'DELETED', deletedAt: { lt: cutoff } },
      select: { id: true },
    });
    if (!dryRun && tombstones.length > 0) {
      await this.prisma.mediaAsset.deleteMany({
        where: { id: { in: tombstones.map((tombstone) => tombstone.id) } },
      });
    }
    return tombstones.length;
  }

  /**
   * A deleted account's media that was never attached to anything.
   * Media still referenced by a post/message/gallery item the account
   * left behind is deliberately left alone — `deleteAccount` never
   * deletes those records, so their attachments must keep working for
   * whoever else can still see them (e.g. a DM recipient).
   */
  private async cleanAccountDeletionMedia(dryRun: boolean): Promise<number> {
    const cutoff = new Date(Date.now() - ACCOUNT_DELETION_MEDIA_GRACE_DAYS * MS_PER_DAY);
    const candidates = await this.prisma.mediaAsset.findMany({
      where: {
        retentionState: 'ACTIVE',
        usages: { none: {} },
        owner: { status: 'DELETED', updatedAt: { lt: cutoff } },
      },
      select: { id: true, storageKey: true, variants: { select: { storageKey: true } } },
    });
    if (!dryRun) {
      for (const asset of candidates) {
        await this.purgeAsset(asset.id, [
          asset.storageKey,
          ...asset.variants.map((variant) => variant.storageKey),
        ]);
      }
    }
    return candidates.length;
  }

  private async purgeAsset(mediaAssetId: string, storageKeys: string[]): Promise<void> {
    await Promise.all(storageKeys.map((key) => this.storage.deleteObject(key)));
    // Cascades to MediaUpload/MediaVariant/MediaUsage/MediaModerationResult/
    // MessageAttachment/GalleryMedia rows (all `onDelete: Cascade` from
    // this side) and SetNulls any CommunityProfile avatar/cover pointer
    // still somehow aimed at this id — see schema.prisma's MediaAsset
    // relations.
    await this.prisma.mediaAsset.delete({ where: { id: mediaAssetId } });
  }
}
