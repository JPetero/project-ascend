import { Injectable } from '@nestjs/common';
import { promises as fs } from 'fs';
import * as path from 'path';
import { MediaStorageProvider, UploadTarget } from './media-storage.provider';
import { MEDIA_UPLOAD_EXPIRY_MINUTES } from '../../../common/policy/media-policy';

/**
 * Safe local adapter — Build Session 8 Part 2's "development mode must
 * have a safe local adapter; do not require real credentials to run
 * tests" requirement. Writes under `services/api/storage/media/`
 * (gitignored, never committed). There is no real signed-URL flow
 * without a cloud provider, so the "upload target" this returns points
 * at our own `POST /media/uploads/:id/local-bytes` endpoint — same
 * shape of contract (method + url + expiry) the client code follows,
 * just same-origin instead of a cloud host.
 */
@Injectable()
export class LocalDevelopmentStorageProvider implements MediaStorageProvider {
  private readonly root = path.join(process.cwd(), 'storage', 'media');

  async createUploadTarget(params: {
    storageKey: string;
    mimeType: string;
  }): Promise<UploadTarget> {
    return {
      method: 'POST',
      url: `/media/uploads/${encodeURIComponent(params.storageKey)}/local-bytes`,
      headers: { 'Content-Type': params.mimeType },
      expiresAt: new Date(Date.now() + MEDIA_UPLOAD_EXPIRY_MINUTES * 60_000),
    };
  }

  getObjectUrl(storageKey: string): string {
    // Never a filesystem path — an API-relative serving route, gated by
    // MediaController.getObject's auth + visibility check (see
    // getSignedGetUrl's doc comment for why the same route backs both).
    // `key` is a query param rather than a path segment so a storage key
    // containing "/" never has to survive Express's path decoding.
    return `/media/objects?key=${encodeURIComponent(storageKey)}`;
  }

  // Build Session 12 Part 18-21 — local dev has no real cloud signing
  // capability, so `GET /media/objects` (MediaController) is the real
  // access gate here instead of an expiring token: it re-checks
  // ownership/visibility on every request via MediaService.readLocalObject.
  // `expirySeconds` is accepted only to satisfy the shared interface.
  async getSignedGetUrl(storageKey: string, _expirySeconds: number): Promise<string> {
    return this.getObjectUrl(storageKey);
  }

  async deleteObject(storageKey: string): Promise<void> {
    const filePath = this.resolvePath(storageKey);
    await fs.unlink(filePath).catch((error: NodeJS.ErrnoException) => {
      if (error.code !== 'ENOENT') throw error;
    });
  }

  async objectExists(storageKey: string): Promise<boolean> {
    try {
      await fs.access(this.resolvePath(storageKey));
      return true;
    } catch {
      return false;
    }
  }

  /** Local-dev-only: actually persist bytes. Not part of the shared interface — production uploads go straight to cloud storage from the client. */
  async writeObject(storageKey: string, buffer: Buffer): Promise<void> {
    const filePath = this.resolvePath(storageKey);
    await fs.mkdir(path.dirname(filePath), { recursive: true });
    await fs.writeFile(filePath, buffer);
  }

  async readObject(storageKey: string): Promise<Buffer> {
    return fs.readFile(this.resolvePath(storageKey));
  }

  private resolvePath(storageKey: string): string {
    // storageKey is server-generated (uuid-based), never client input used
    // directly as a path — still normalize defensively against traversal.
    const normalized = path.normalize(storageKey).replace(/^(\.\.[/\\])+/, '');
    return path.join(this.root, normalized);
  }
}
