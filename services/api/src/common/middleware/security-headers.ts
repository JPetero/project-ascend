import helmet, { HelmetOptions } from 'helmet';

/**
 * S13 Part 33-49 — the tuned Helmet configuration `main.ts`'s bootstrap
 * passes to `helmet()`. Pulled into its own pure function so the
 * directive set is unit-testable without spinning up a live Nest
 * application (see security-headers.spec.ts) — the same "extract for
 * testability" pattern used throughout this codebase for anything more
 * than a one-line config literal.
 *
 * Diverges from Helmet's strict CSP defaults in exactly three
 * directives, and only because Swagger UI (mounted at `/docs` in
 * main.ts) is the sole HTML page this API serves — every other route
 * returns JSON, which a CSP directive has no effect on (a browser only
 * enforces CSP when rendering a page, not when parsing a JSON
 * response). Swagger's bundled UI renders inline `<style>`/`<script>`
 * and loads its logo via a `data:` URI; Helmet's strict defaults would
 * otherwise silently break the docs page rather than protect anything
 * real. Resolves security.md's previously-documented "security headers
 * beyond Helmet's defaults have not been reviewed" gap.
 */
export function buildHelmetOptions(): HelmetOptions {
  return {
    contentSecurityPolicy: {
      directives: {
        ...helmet.contentSecurityPolicy.getDefaultDirectives(),
        'script-src': ["'self'", "'unsafe-inline'"],
        'style-src': ["'self'", "'unsafe-inline'"],
        'img-src': ["'self'", 'data:'],
      },
    },
  };
}
