export interface UploadTarget {
  /** How the client should send the bytes — 'PUT' for a presigned S3-style URL, 'POST' for the local-dev direct-write endpoint. */
  method: 'PUT' | 'POST';
  /** Absolute or API-relative URL the client uploads to. */
  url: string;
  headers?: Record<string, string>;
  expiresAt: Date;
}

/**
 * Storage abstraction — Build Session 8 Part 2. Every module that needs
 * to move bytes in or out of storage goes through this interface, never
 * a concrete provider directly, so swapping local disk for Cloudflare
 * R2 (or any other S3-compatible service) in production is a config
 * change, not a rewrite. Never expose a server filesystem path through
 * any of these methods' return values.
 */
export interface MediaStorageProvider {
  /** Builds the one-shot upload contract the client uses to send bytes for `storageKey`. */
  createUploadTarget(params: { storageKey: string; mimeType: string }): Promise<UploadTarget>;

  /** A URL suitable for reading the object back — never a raw filesystem path. */
  getObjectUrl(storageKey: string): string;

  deleteObject(storageKey: string): Promise<void>;

  objectExists(storageKey: string): Promise<boolean>;
}

export const MEDIA_STORAGE_PROVIDER = Symbol('MEDIA_STORAGE_PROVIDER');
