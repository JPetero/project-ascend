import { describe, expect, it } from 'vitest';
import { validateApiConfig } from './apiConfigValidation';

describe('validateApiConfig', () => {
  it('is always valid in dev mode, regardless of VITE_API_BASE_URL', () => {
    expect(validateApiConfig({ DEV: true })).toEqual({
      isValid: true,
      violations: [],
    });
    expect(
      validateApiConfig({ DEV: true, VITE_API_BASE_URL: 'not-a-url' }),
    ).toEqual({ isValid: true, violations: [] });
  });

  it('rejects a production build with no VITE_API_BASE_URL set', () => {
    const result = validateApiConfig({ DEV: false });
    expect(result.isValid).toBe(false);
    expect(result.violations[0]).toContain('VITE_API_BASE_URL is not set');
  });

  it('rejects a production build with an empty/whitespace VITE_API_BASE_URL', () => {
    const result = validateApiConfig({ DEV: false, VITE_API_BASE_URL: '   ' });
    expect(result.isValid).toBe(false);
  });

  it('rejects an unparseable VITE_API_BASE_URL', () => {
    const result = validateApiConfig({
      DEV: false,
      VITE_API_BASE_URL: 'not a url at all',
    });
    expect(result.isValid).toBe(false);
    expect(result.violations[0]).toContain('is not a valid URL');
  });

  it('rejects a non-https VITE_API_BASE_URL in production', () => {
    const result = validateApiConfig({
      DEV: false,
      VITE_API_BASE_URL: 'http://api.projectascend.example.com',
    });
    expect(result.isValid).toBe(false);
    expect(result.violations[0]).toContain('must use https://');
  });

  it('rejects a localhost VITE_API_BASE_URL in production', () => {
    const result = validateApiConfig({
      DEV: false,
      VITE_API_BASE_URL: 'https://localhost:3000',
    });
    expect(result.isValid).toBe(false);
    expect(result.violations[0]).toContain('local-development-only');
  });

  it('rejects a 127.0.0.1 VITE_API_BASE_URL in production', () => {
    const result = validateApiConfig({
      DEV: false,
      VITE_API_BASE_URL: 'https://127.0.0.1:3000',
    });
    expect(result.isValid).toBe(false);
  });

  it('accepts a real https VITE_API_BASE_URL in production', () => {
    const result = validateApiConfig({
      DEV: false,
      VITE_API_BASE_URL: 'https://api.projectascend.example.com',
    });
    expect(result).toEqual({ isValid: true, violations: [] });
  });

  it('can report multiple violations at once', () => {
    const result = validateApiConfig({
      DEV: false,
      VITE_API_BASE_URL: 'http://localhost:3000',
    });
    expect(result.isValid).toBe(false);
    expect(result.violations).toHaveLength(2);
  });
});
