/**
 * Magic-number ("file signature") checks — Build Session 8 Part 2's
 * "never trust client MIME type alone" requirement. Only usable when
 * the server actually has the file bytes in hand (the local-dev direct
 * upload path); a presigned direct-to-cloud upload never gives the API
 * server the bytes to inspect, which is why this is "where practical"
 * rather than universal — see MediaService's doc comment.
 */
export function fileSignatureMatchesMimeType(buffer: Buffer, mimeType: string): boolean {
  if (buffer.length < 4) return false;

  switch (mimeType) {
    case 'image/jpeg':
      return buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff;
    case 'image/png':
      return buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4e && buffer[3] === 0x47;
    case 'image/webp':
      return (
        buffer.length >= 12 &&
        buffer.subarray(0, 4).toString('ascii') === 'RIFF' &&
        buffer.subarray(8, 12).toString('ascii') === 'WEBP'
      );
    case 'video/mp4':
      return buffer.length >= 12 && buffer.subarray(4, 8).toString('ascii') === 'ftyp';
    case 'video/quicktime':
      return (
        buffer.length >= 12 &&
        (buffer.subarray(4, 8).toString('ascii') === 'ftyp' ||
          buffer.subarray(4, 8).toString('ascii') === 'moov' ||
          buffer.subarray(4, 8).toString('ascii') === 'free')
      );
    case 'video/webm':
      return buffer[0] === 0x1a && buffer[1] === 0x45 && buffer[2] === 0xdf && buffer[3] === 0xa3;
    default:
      // No known signature for this MIME type — cannot prove it's wrong,
      // so let declared-MIME-type validation elsewhere be authoritative.
      return true;
  }
}
