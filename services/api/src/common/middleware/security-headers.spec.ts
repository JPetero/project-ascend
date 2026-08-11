import { buildHelmetOptions } from './security-headers';

describe('buildHelmetOptions', () => {
  it("keeps every one of Helmet's own default CSP directives, none dropped", () => {
    const options = buildHelmetOptions();
    const directives = (options.contentSecurityPolicy as { directives: Record<string, unknown> })
      .directives;

    expect(directives['default-src']).toEqual(["'self'"]);
    expect(directives['object-src']).toEqual(["'none'"]);
    expect(directives['frame-ancestors']).toEqual(["'self'"]);
  });

  it('relaxes only script-src/style-src/img-src, and only enough for Swagger UI to render', () => {
    const options = buildHelmetOptions();
    const directives = (options.contentSecurityPolicy as { directives: Record<string, unknown> })
      .directives;

    expect(directives['script-src']).toEqual(["'self'", "'unsafe-inline'"]);
    expect(directives['style-src']).toEqual(["'self'", "'unsafe-inline'"]);
    expect(directives['img-src']).toEqual(["'self'", 'data:']);
  });

  it('never relaxes script-src-attr — inline event-handler attributes stay blocked', () => {
    const options = buildHelmetOptions();
    const directives = (options.contentSecurityPolicy as { directives: Record<string, unknown> })
      .directives;

    expect(directives['script-src-attr']).toEqual(["'none'"]);
  });
});
