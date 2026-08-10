import { Injectable } from '@nestjs/common';
import {
  DeleteObjectCommand,
  GetObjectCommand,
  HeadObjectCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { ConfigService } from '@nestjs/config';
import { MediaStorageProvider, UploadTarget } from './media-storage.provider';
import { MEDIA_UPLOAD_EXPIRY_MINUTES } from '../../../common/policy/media-policy';

/**
 * Production storage adapter — Build Session 8 Part 2. Talks to any
 * S3-compatible object store via a configurable custom endpoint, so the
 * same code works against Cloudflare R2 (the intended target), MinIO
 * for self-hosting, or real AWS S3. Never instantiated without real
 * credentials in this repository's tests — see MediaStorageModule's
 * factory, which only selects this provider when
 * `MEDIA_STORAGE_PROVIDER=s3` is explicitly set. A dedicated spec file
 * exercises this class in isolation against a mocked S3Client so the
 * signing/URL logic itself is still covered without needing a real
 * bucket.
 */
@Injectable()
export class S3CompatibleStorageProvider implements MediaStorageProvider {
  private readonly client: S3Client;
  private readonly bucket: string;
  private readonly publicBaseUrl?: string;

  constructor(private readonly configService: ConfigService) {
    const endpoint = this.configService.get<string>('media.s3Endpoint');
    const region = this.configService.get<string>('media.s3Region') ?? 'auto';
    this.bucket = this.configService.get<string>('media.s3Bucket') ?? '';
    this.publicBaseUrl = this.configService.get<string>('media.s3PublicBaseUrl');

    this.client = new S3Client({
      region,
      endpoint,
      forcePathStyle: true,
      credentials: {
        accessKeyId: this.configService.get<string>('media.s3AccessKeyId') ?? '',
        secretAccessKey: this.configService.get<string>('media.s3SecretAccessKey') ?? '',
      },
    });
  }

  async createUploadTarget(params: {
    storageKey: string;
    mimeType: string;
  }): Promise<UploadTarget> {
    const expiresInSeconds = MEDIA_UPLOAD_EXPIRY_MINUTES * 60;
    const command = new PutObjectCommand({
      Bucket: this.bucket,
      Key: params.storageKey,
      ContentType: params.mimeType,
    });
    const url = await getSignedUrl(this.client, command, { expiresIn: expiresInSeconds });
    return {
      method: 'PUT',
      url,
      headers: { 'Content-Type': params.mimeType },
      expiresAt: new Date(Date.now() + expiresInSeconds * 1000),
    };
  }

  getObjectUrl(storageKey: string): string {
    if (this.publicBaseUrl) {
      return `${this.publicBaseUrl.replace(/\/$/, '')}/${storageKey}`;
    }
    return `${this.bucket}/${storageKey}`;
  }

  async getSignedGetUrl(storageKey: string, expirySeconds: number): Promise<string> {
    const command = new GetObjectCommand({ Bucket: this.bucket, Key: storageKey });
    return getSignedUrl(this.client, command, { expiresIn: expirySeconds });
  }

  async deleteObject(storageKey: string): Promise<void> {
    await this.client.send(new DeleteObjectCommand({ Bucket: this.bucket, Key: storageKey }));
  }

  async objectExists(storageKey: string): Promise<boolean> {
    try {
      await this.client.send(new HeadObjectCommand({ Bucket: this.bucket, Key: storageKey }));
      return true;
    } catch {
      return false;
    }
  }
}
