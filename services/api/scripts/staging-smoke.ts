/**
 * S15 Part 14 — a real smoke test against a real, running staging
 * deployment. Not a unit test and not a substitute for one: this makes
 * actual HTTPS requests to a host you name and reports what actually
 * happened.
 *
 * The point is to answer "is this deployment genuinely working" with
 * evidence rather than assumption. Every check below either passed
 * against a live host or it did not — there is no path through this
 * script that reports success without a real response.
 *
 * Usage:
 *   pnpm staging:smoke --base-url https://staging-api.example.com
 *
 * Optionally, to exercise authenticated surfaces too:
 *   pnpm staging:smoke --base-url https://... \
 *     --admin-email you@example.com --admin-password '...'
 *
 * Exits non-zero if any required check fails, so it is usable as a
 * deploy gate.
 */

interface CheckResult {
  name: string;
  status: 'PASS' | 'FAIL' | 'SKIP';
  detail: string;
}

interface Args {
  baseUrl: string;
  adminEmail?: string;
  adminPassword?: string;
}

function parseArgs(argv: string[]): Args {
  const get = (flag: string): string | undefined => {
    const i = argv.indexOf(flag);
    return i >= 0 && i + 1 < argv.length ? argv[i + 1] : undefined;
  };

  const baseUrl = get('--base-url') ?? process.env.STAGING_BASE_URL;
  if (!baseUrl) {
    throw new Error(
      'No target given. Pass --base-url https://staging-api.example.com ' +
        '(or set STAGING_BASE_URL). This script never guesses a host — pointing a smoke ' +
        'test at the wrong environment is worse than not running it.',
    );
  }

  let parsed: URL;
  try {
    parsed = new URL(baseUrl);
  } catch {
    throw new Error(`--base-url "${baseUrl}" is not a valid URL.`);
  }

  // A staging deployment is internet-reachable and must be https — the
  // API itself refuses to boot otherwise (DeploymentConfigValidation),
  // so smoke-testing over http would be testing something that cannot
  // be the real deployment. localhost is allowed as the one exception,
  // since the CI integration workflow (S15 Part 16) runs this script
  // against an ephemeral container over plain http.
  const isLocal = ['localhost', '127.0.0.1'].includes(parsed.hostname);
  if (parsed.protocol !== 'https:' && !isLocal) {
    throw new Error(
      `--base-url must use https:// for a real staging host (got "${parsed.protocol}//"). ` +
        'Android blocks cleartext traffic by default and the API refuses to boot without ' +
        'https — see release/reverse-proxy-tls-contract.md.',
    );
  }

  return {
    baseUrl: baseUrl.replace(/\/+$/, ''),
    adminEmail: get('--admin-email') ?? process.env.STAGING_ADMIN_EMAIL,
    adminPassword: get('--admin-password') ?? process.env.STAGING_ADMIN_PASSWORD,
  };
}

const TIMEOUT_MS = 15_000;

async function request(
  url: string,
  init: RequestInit = {},
): Promise<{ status: number; body: unknown; raw: string }> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const response = await fetch(url, { ...init, signal: controller.signal });
    const raw = await response.text();
    let body: unknown = raw;
    try {
      body = JSON.parse(raw);
    } catch {
      // Non-JSON is a legitimate response for some endpoints; keep raw.
    }
    return { status: response.status, body, raw };
  } finally {
    clearTimeout(timer);
  }
}

function asRecord(value: unknown): Record<string, unknown> {
  return value !== null && typeof value === 'object' ? (value as Record<string, unknown>) : {};
}

/**
 * Every API response is wrapped by the global response interceptor as
 * `{ data, meta, error }` — so the payload a caller actually wants lives
 * under `.data`, never at the top level. Unwrapping in one helper (rather
 * than at each call site) is what keeps this script honest: reading
 * `body.status` directly silently yields undefined and would have turned
 * a healthy endpoint into a reported failure.
 */
function unwrap(body: unknown): Record<string, unknown> {
  const top = asRecord(body);
  return 'data' in top ? asRecord(top.data) : top;
}

async function main(): Promise<void> {
  const args = parseArgs(process.argv.slice(2));
  const results: CheckResult[] = [];

  const record = (name: string, status: CheckResult['status'], detail: string) => {
    results.push({ name, status, detail });
    const marker = status === 'PASS' ? '✓' : status === 'FAIL' ? '✗' : '−';
    console.log(`  ${marker} ${name}: ${detail}`);
  };

  console.log(`\nSmoke-testing ${args.baseUrl}\n`);

  // --- 1. Liveness: the process is up. No database involved.
  try {
    const { status, body } = await request(`${args.baseUrl}/livez`);
    const ok = status === 200 && unwrap(body).status === 'ok';
    record(
      'livez',
      ok ? 'PASS' : 'FAIL',
      ok ? 'process alive' : `expected 200 {status:"ok"}, got ${status}`,
    );
  } catch (error) {
    record('livez', 'FAIL', `request failed: ${(error as Error).message}`);
  }

  // --- 2. Readiness: the database is actually reachable from the API.
  //     This is the check that distinguishes "container running" from
  //     "deployment working".
  try {
    const { status, body } = await request(`${args.baseUrl}/readyz`);
    const ok = status === 200 && unwrap(body).status === 'ok';
    record(
      'readyz',
      ok ? 'PASS' : 'FAIL',
      ok ? 'database reachable' : `expected 200 {status:"ok"}, got ${status}`,
    );
  } catch (error) {
    record('readyz', 'FAIL', `request failed: ${(error as Error).message}`);
  }

  // --- 3. Reference data actually seeded. An empty exercise catalog
  //     means bootstrap never ran, and every workout screen depends on it.
  //     Runs anonymously first; if the endpoint requires auth, it is
  //     retried with the admin token below rather than left unverified.
  const checkReferenceData = async (token?: string): Promise<'ok' | 'needs-auth'> => {
    // No query parameters: the endpoint's DTO uses a strict whitelist and
    // rejects unknown ones with a 400, so a speculative `?limit=1` fails
    // validation rather than limiting anything. Confirmed against a
    // running API — "property limit should not exist".
    const { status, body } = await request(
      `${args.baseUrl}/exercises`,
      token ? { headers: { Authorization: `Bearer ${token}` } } : {},
    );
    const payload = unwrap(body);
    // The unwrapped payload is `{ items: [...] }` when paginated and a
    // bare array otherwise — accept either rather than guessing.
    const items = Array.isArray(payload)
      ? payload
      : Array.isArray(payload.items)
        ? payload.items
        : Array.isArray(payload.data)
          ? payload.data
          : [];

    if (status === 401 && !token) {
      return 'needs-auth';
    }
    if (status === 200 && items.length > 0) {
      record('reference data', 'PASS', 'exercise catalog is populated');
    } else if (status === 200) {
      record(
        'reference data',
        'FAIL',
        'exercise catalog is EMPTY — run pnpm staging:bootstrap against this database',
      );
    } else {
      record('reference data', 'FAIL', `unexpected status ${status}`);
    }
    return 'ok';
  };

  let referenceDataNeedsAuth = false;
  try {
    referenceDataNeedsAuth = (await checkReferenceData()) === 'needs-auth';
  } catch (error) {
    record('reference data', 'FAIL', `request failed: ${(error as Error).message}`);
  }

  // --- 4. Auth rejects bad credentials. Proves the auth stack is wired
  //     end to end (route, validation, database lookup, argon2) without
  //     needing a real account, and proves it fails closed.
  try {
    const { status } = await request(`${args.baseUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'smoke-test-nonexistent@invalid.example',
        password: 'definitely-not-a-real-password',
      }),
    });
    const ok = status === 401 || status === 400;
    record(
      'auth rejects bad credentials',
      ok ? 'PASS' : 'FAIL',
      ok ? `correctly rejected with ${status}` : `expected 401/400, got ${status}`,
    );
  } catch (error) {
    record('auth rejects bad credentials', 'FAIL', `request failed: ${(error as Error).message}`);
  }

  // --- 5. Admin diagnostics are not publicly readable.
  try {
    const { status } = await request(`${args.baseUrl}/admin/release-readiness`);
    const ok = status === 401 || status === 403;
    record(
      'admin route requires auth',
      ok ? 'PASS' : 'FAIL',
      ok
        ? `correctly rejected anonymous access with ${status}`
        : `SECURITY: expected 401/403, got ${status}`,
    );
  } catch (error) {
    record('admin route requires auth', 'FAIL', `request failed: ${(error as Error).message}`);
  }

  // --- 6. Authenticated readiness, only if credentials were supplied.
  if (args.adminEmail && args.adminPassword) {
    try {
      const login = await request(`${args.baseUrl}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: args.adminEmail, password: args.adminPassword }),
      });

      // Real shape, confirmed against a running API rather than assumed:
      //   { data: { user: {...}, tokens: { accessToken, ... } }, meta, error }
      const data = unwrap(login.body);
      const tokens = asRecord(data.tokens);
      const token =
        (tokens.accessToken as string | undefined) ?? (data.accessToken as string | undefined);

      if (login.status !== 200 || !token) {
        record('admin login', 'FAIL', `login failed with status ${login.status}`);
      } else {
        record('admin login', 'PASS', 'signed in successfully');

        if (referenceDataNeedsAuth) {
          await checkReferenceData(token);
        }

        const readiness = await request(`${args.baseUrl}/admin/release-readiness`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        const payload = unwrap(readiness.body);

        if (readiness.status !== 200) {
          record('release readiness', 'FAIL', `status ${readiness.status}`);
        } else {
          const ascendEnv = payload.ascendEnv;
          record(
            'ASCEND_ENV',
            ascendEnv === 'staging' ? 'PASS' : 'FAIL',
            ascendEnv === 'staging'
              ? 'reports "staging"'
              : `reports "${String(ascendEnv)}" — expected "staging"`,
          );

          const migrations = asRecord(payload.migrations);
          const upToDate = migrations.upToDate === true;
          const pending = Array.isArray(migrations.pending) ? migrations.pending : [];
          record(
            'migrations',
            upToDate ? 'PASS' : 'FAIL',
            upToDate
              ? 'every migration applied'
              : `${pending.length} pending — run prisma migrate deploy`,
          );

          const security = asRecord(payload.security);
          const safe = security.productionSafe === true;
          record(
            'deployment safety',
            safe ? 'PASS' : 'FAIL',
            safe
              ? 'no dev secrets, no wildcard CORS'
              : 'UNSAFE CONFIG — dev JWT secrets and/or wildcard CORS in a deployed environment',
          );
        }
      }
    } catch (error) {
      record('admin checks', 'FAIL', `request failed: ${(error as Error).message}`);
    }
  } else {
    record(
      'admin checks',
      'SKIP',
      'no --admin-email/--admin-password given (anonymous checks still ran)',
    );
    if (referenceDataNeedsAuth) {
      record(
        'reference data',
        'SKIP',
        'endpoint requires auth — pass --admin-email/--admin-password to verify it',
      );
    }
  }

  // --- Summary
  const failed = results.filter((r) => r.status === 'FAIL');
  const passed = results.filter((r) => r.status === 'PASS');
  const skipped = results.filter((r) => r.status === 'SKIP');

  console.log(`\n${passed.length} passed, ${failed.length} failed, ${skipped.length} skipped.\n`);

  if (failed.length > 0) {
    console.error('Smoke test FAILED. This deployment is not working correctly:');
    failed.forEach((f) => console.error(`  - ${f.name}: ${f.detail}`));
    console.error('');
    process.exitCode = 1;
    return;
  }

  console.log('Smoke test passed against a real, running deployment.');
  if (skipped.length > 0) {
    console.log('Note: skipped checks were not verified — they are not passes.');
  }
}

main().catch((error: unknown) => {
  console.error(`\n${error instanceof Error ? error.message : String(error)}\n`);
  process.exitCode = 1;
});
