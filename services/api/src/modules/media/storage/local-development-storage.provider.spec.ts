import { promises as fs } from 'fs';
import * as os from 'os';
import * as path from 'path';
import { LocalDevelopmentStorageProvider } from './local-development-storage.provider';

describe('LocalDevelopmentStorageProvider', () => {
  let provider: LocalDevelopmentStorageProvider;
  let originalCwd: string;
  let tempDir: string;

  beforeEach(async () => {
    tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'ascend-media-test-'));
    originalCwd = process.cwd();
    process.chdir(tempDir);
    provider = new LocalDevelopmentStorageProvider();
  });

  afterEach(async () => {
    process.chdir(originalCwd);
    await fs.rm(tempDir, { recursive: true, force: true });
  });

  it('returns a same-origin upload target, never a filesystem path', async () => {
    const target = await provider.createUploadTarget({
      storageKey: 'user-1/profile_image/abc.jpg',
      mimeType: 'image/jpeg',
    });

    expect(target.method).toBe('POST');
    expect(target.url).toBe('/media/uploads/user-1%2Fprofile_image%2Fabc.jpg/local-bytes');
    expect(target.url).not.toContain(tempDir);
  });

  it('returns an API-relative object URL, never a filesystem path', () => {
    const url = provider.getObjectUrl('user-1/profile_image/abc.jpg');
    expect(url).toBe('/media/objects/user-1%2Fprofile_image%2Fabc.jpg');
    expect(url).not.toContain(tempDir);
  });

  it('writes and reads bytes for a storage key', async () => {
    const buffer = Buffer.from('hello media platform');
    await provider.writeObject('user-1/profile_image/abc.jpg', buffer);

    const readBack = await provider.readObject('user-1/profile_image/abc.jpg');
    expect(readBack.equals(buffer)).toBe(true);
  });

  it('confirms an object exists after writing it', async () => {
    await provider.writeObject('user-1/profile_image/abc.jpg', Buffer.from('x'));
    await expect(provider.objectExists('user-1/profile_image/abc.jpg')).resolves.toBe(true);
  });

  it('reports an object does not exist before it is written', async () => {
    await expect(provider.objectExists('user-1/profile_image/never-written.jpg')).resolves.toBe(
      false,
    );
  });

  it('deletes a written object', async () => {
    await provider.writeObject('user-1/profile_image/abc.jpg', Buffer.from('x'));
    await provider.deleteObject('user-1/profile_image/abc.jpg');
    await expect(provider.objectExists('user-1/profile_image/abc.jpg')).resolves.toBe(false);
  });

  it('does not throw when deleting an object that was never written', async () => {
    await expect(
      provider.deleteObject('user-1/profile_image/never-written.jpg'),
    ).resolves.toBeUndefined();
  });

  it('normalizes a path-traversal storage key rather than escaping the storage root', async () => {
    await provider.writeObject('../../etc/evil.jpg', Buffer.from('x'));
    const escapedPath = path.join(tempDir, '..', '..', 'etc', 'evil.jpg');
    await expect(fs.access(escapedPath)).rejects.toThrow();
  });
});
