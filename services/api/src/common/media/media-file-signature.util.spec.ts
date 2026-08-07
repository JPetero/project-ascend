import { fileSignatureMatchesMimeType } from './media-file-signature.util';

describe('fileSignatureMatchesMimeType', () => {
  it('accepts a real JPEG signature', () => {
    const buffer = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10]);
    expect(fileSignatureMatchesMimeType(buffer, 'image/jpeg')).toBe(true);
  });

  it('rejects a PNG file mislabeled as JPEG', () => {
    const buffer = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a]);
    expect(fileSignatureMatchesMimeType(buffer, 'image/jpeg')).toBe(false);
  });

  it('accepts a real PNG signature', () => {
    const buffer = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
    expect(fileSignatureMatchesMimeType(buffer, 'image/png')).toBe(true);
  });

  it('accepts a real WEBP signature', () => {
    const buffer = Buffer.concat([
      Buffer.from('RIFF', 'ascii'),
      Buffer.from([0x00, 0x00, 0x00, 0x00]),
      Buffer.from('WEBP', 'ascii'),
    ]);
    expect(fileSignatureMatchesMimeType(buffer, 'image/webp')).toBe(true);
  });

  it('accepts a real MP4 ftyp signature', () => {
    const buffer = Buffer.concat([
      Buffer.from([0x00, 0x00, 0x00, 0x18]),
      Buffer.from('ftyp', 'ascii'),
      Buffer.from('mp42', 'ascii'),
    ]);
    expect(fileSignatureMatchesMimeType(buffer, 'video/mp4')).toBe(true);
  });

  it('rejects a text file mislabeled as MP4', () => {
    const buffer = Buffer.from('this is not a video file at all', 'ascii');
    expect(fileSignatureMatchesMimeType(buffer, 'video/mp4')).toBe(false);
  });

  it('is too short to validate', () => {
    const buffer = Buffer.from([0xff]);
    expect(fileSignatureMatchesMimeType(buffer, 'image/jpeg')).toBe(false);
  });

  it('lets an unknown MIME type through since it has no known signature to check', () => {
    const buffer = Buffer.from('anything', 'ascii');
    expect(fileSignatureMatchesMimeType(buffer, 'application/octet-stream')).toBe(true);
  });
});
