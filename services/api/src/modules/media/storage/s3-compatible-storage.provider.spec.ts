import { ConfigService } from '@nestjs/config';
import { S3CompatibleStorageProvider } from './s3-compatible-storage.provider';

const sendMock = jest.fn();

jest.mock('@aws-sdk/client-s3', () => {
  return {
    S3Client: jest.fn().mockImplementation(() => ({ send: sendMock })),
    PutObjectCommand: jest.fn().mockImplementation((input) => ({ input })),
    DeleteObjectCommand: jest.fn().mockImplementation((input) => ({ input })),
    HeadObjectCommand: jest.fn().mockImplementation((input) => ({ input })),
  };
});

jest.mock('@aws-sdk/s3-request-presigner', () => ({
  getSignedUrl: jest.fn().mockResolvedValue('https://r2.example.com/bucket/key?signature=abc'),
}));

function configService(overrides: Record<string, string> = {}) {
  const values: Record<string, string> = {
    'media.s3Endpoint': 'https://accountid.r2.cloudflarestorage.com',
    'media.s3Region': 'auto',
    'media.s3Bucket': 'ascend-media',
    'media.s3AccessKeyId': 'test-key',
    'media.s3SecretAccessKey': 'test-secret',
    'media.s3PublicBaseUrl': 'https://media.example.com',
    ...overrides,
  };
  return { get: (key: string) => values[key] } as unknown as ConfigService;
}

describe('S3CompatibleStorageProvider', () => {
  beforeEach(() => {
    sendMock.mockReset();
  });

  it('never requires real credentials to construct — reads whatever config is present', () => {
    expect(() => new S3CompatibleStorageProvider(configService())).not.toThrow();
  });

  it('returns a presigned PUT upload target', async () => {
    const provider = new S3CompatibleStorageProvider(configService());
    const target = await provider.createUploadTarget({
      storageKey: 'user-1/profile_image/abc.jpg',
      mimeType: 'image/jpeg',
    });

    expect(target.method).toBe('PUT');
    expect(target.url).toContain('r2.example.com');
  });

  it('builds a public object URL from the configured public base URL', () => {
    const provider = new S3CompatibleStorageProvider(configService());
    expect(provider.getObjectUrl('user-1/profile_image/abc.jpg')).toBe(
      'https://media.example.com/user-1/profile_image/abc.jpg',
    );
  });

  it('falls back to a bucket-relative URL when no public base URL is configured', () => {
    const provider = new S3CompatibleStorageProvider(
      configService({ 'media.s3PublicBaseUrl': '' }),
    );
    expect(provider.getObjectUrl('key.jpg')).toBe('ascend-media/key.jpg');
  });

  it('deletes an object via the S3 client', async () => {
    sendMock.mockResolvedValue({});
    const provider = new S3CompatibleStorageProvider(configService());
    await provider.deleteObject('user-1/profile_image/abc.jpg');
    expect(sendMock).toHaveBeenCalled();
  });

  it('reports an object exists when HeadObject succeeds', async () => {
    sendMock.mockResolvedValue({});
    const provider = new S3CompatibleStorageProvider(configService());
    await expect(provider.objectExists('key.jpg')).resolves.toBe(true);
  });

  it('reports an object does not exist when HeadObject throws', async () => {
    sendMock.mockRejectedValue(new Error('NotFound'));
    const provider = new S3CompatibleStorageProvider(configService());
    await expect(provider.objectExists('key.jpg')).resolves.toBe(false);
  });
});
