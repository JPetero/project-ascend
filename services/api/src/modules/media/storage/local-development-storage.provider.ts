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
    // Never a filesystem path — an API-relative serving route.
    return `/media/objects/${encodeURIComponent(storageKey)}`;
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
