import { MediaType } from '@prisma/client';

/**
 * Single source of truth for per-media-type upload limits — Build
 * Session 8 Part 2's Media Platform. Nothing outside this file should
 * hard-code a max file size, dimension, or duration; every module that
 * accepts an upload (Community, Trainer Groups chat, Fuel, Vision,
 * profile) reads the same table through `MediaService`/`validateMediaUpload`.
 */
export interface MediaLimit {
  maxSizeBytes: number;
  allowedMimeTypes: readonly string[];
  maxWidth?: number;
  maxHeight?: number;
  maxDurationSeconds?: number;
}

const IMAGE_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'] as const;
const VIDEO_MIME_TYPES = ['video/mp4', 'video/quicktime', 'video/webm'] as const;

const MB = 1024 * 1024;

export const MEDIA_LIMITS: Record<MediaType, MediaLimit> = {
  PROFILE_IMAGE: {
    maxSizeBytes: 5 * MB,
    allowedMimeTypes: IMAGE_MIME_TYPES,
    maxWidth: 4096,
    maxHeight: 4096,
  },
  COVER_IMAGE: {
    maxSizeBytes: 8 * MB,
    allowedMimeTypes: IMAGE_MIME_TYPES,
    maxWidth: 4096,
    maxHeight: 4096,
  },
  COMMUNITY_IMAGE: {
    maxSizeBytes: 10 * MB,
    allowedMimeTypes: IMAGE_MIME_TYPES,
    maxWidth: 4096,
    maxHeight: 4096,
  },
  COMMUNITY_REEL: {
    maxSizeBytes: 200 * MB,
    allowedMimeTypes: VIDEO_MIME_TYPES,
    maxDurationSeconds: 90,
  },
  CHAT_IMAGE: {
    maxSizeBytes: 8 * MB,
    allowedMimeTypes: IMAGE_MIME_TYPES,
    maxWidth: 4096,
    maxHeight: 4096,
  },
  MEAL_PHOTO: {
    maxSizeBytes: 8 * MB,
    allowedMimeTypes: IMAGE_MIME_TYPES,
    maxWidth: 4096,
    maxHeight: 4096,
  },
  PROGRESS_PHOTO: {
    maxSizeBytes: 8 * MB,
    allowedMimeTypes: IMAGE_MIME_TYPES,
    maxWidth: 4096,
    maxHeight: 4096,
  },
  VISION_CAPTURE: {
    maxSizeBytes: 200 * MB,
    allowedMimeTypes: [...IMAGE_MIME_TYPES, ...VIDEO_MIME_TYPES],
    maxWidth: 4096,
    maxHeight: 4096,
    maxDurationSeconds: 60,
  },
  WORKOUT_SHARE_MEDIA: {
    maxSizeBytes: 10 * MB,
    allowedMimeTypes: IMAGE_MIME_TYPES,
    maxWidth: 4096,
    maxHeight: 4096,
  },
};

export const ALLOWED_EXTENSIONS_BY_MIME_TYPE: Record<string, readonly string[]> = {
  'image/jpeg': ['.jpg', '.jpeg'],
  'image/png': ['.png'],
  'image/webp': ['.webp'],
  'video/mp4': ['.mp4'],
  'video/quicktime': ['.mov'],
  'video/webm': ['.webm'],
};

/** Upload-attempt contracts expire after this long if never completed. */
export const MEDIA_UPLOAD_EXPIRY_MINUTES = 15;

/** Signed read URLs for PRIVATE-visibility media expire after this long. */
export const MEDIA_PRIVATE_URL_EXPIRY_SECONDS = 15 * 60;
