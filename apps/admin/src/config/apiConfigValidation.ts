// S14 Part 28 — mirrors the mobile app's AppConfigValidation
// (apps/mobile/lib/core/config/app_config_validation.dart): a
// production admin build must be given its real backend host
// explicitly, never silently fall back to localhost, which
// `src/api/client.ts` otherwise defaults to for local development.
//
// `env` is injectable so this stays testable without Vitest's own
// `import.meta.env.DEV` (always true under `vitest run`, which would
// make every "production" branch untestable) — real callers omit it and
// get the actual build-time `import.meta.env`.
export interface ApiConfigEnv {
  DEV: boolean;
  VITE_API_BASE_URL?: string;
}

export interface ApiConfigValidationResult {
  isValid: boolean;
  violations: string[];
}

const unsafeHosts = new Set(['localhost', '127.0.0.1']);

export function validateApiConfig(
  env: ApiConfigEnv = import.meta.env,
): ApiConfigValidationResult {
  // The Vite dev server (`pnpm admin:dev`) always has a genuinely
  // correct localhost default — never validated, same as AppConfig's
  // `dev` build variant.
  if (env.DEV) {
    return { isValid: true, violations: [] };
  }

  const configured = env.VITE_API_BASE_URL?.trim();
  if (!configured) {
    return {
      isValid: false,
      violations: [
        'VITE_API_BASE_URL is not set. A production admin build must be ' +
          'given its real backend host explicitly at build time — there ' +
          'is no safe default to fall back to.',
      ],
    };
  }

  let url: URL;
  try {
    url = new URL(configured);
  } catch {
    return {
      isValid: false,
      violations: [`VITE_API_BASE_URL "${configured}" is not a valid URL.`],
    };
  }

  const violations: string[] = [];
  if (url.protocol !== 'https:') {
    violations.push(
      `VITE_API_BASE_URL must use https:// — got "${url.protocol}//".`,
    );
  }
  if (unsafeHosts.has(url.hostname.toLowerCase())) {
    violations.push(
      `VITE_API_BASE_URL host "${url.hostname}" is a local-development-only ` +
        'address and must never be used in a production build.',
    );
  }

  return { isValid: violations.length === 0, violations };
}
