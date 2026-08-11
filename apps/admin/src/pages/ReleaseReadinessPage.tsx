import { useCallback, useEffect, useState } from 'react';
import { adminApi } from '../api/adminApi';
import type { ReleaseReadiness, ReleaseReadinessItem, ReleaseReadinessStatus } from '../api/adminApi';
import { ApiError } from '../api/client';
import { ErrorState, LoadingState } from '../components/StateViews';

function StatusBadge({ ok }: { ok: boolean }) {
  return <span>{ok ? '✅' : '❌'}</span>;
}

// S14 Part 7 — a symbol per status, not just ok/not-ok: READY and
// CODE_READY both look "fine" but mean different things (this service
// verified it live vs. the code is correct but an external step this
// service can't see is still needed), and DISABLED is a deliberate
// product decision, not a gap, so it must never look like a failure.
const STATUS_SYMBOL: Record<ReleaseReadinessStatus, string> = {
  READY: '✅',
  CODE_READY: '🟡',
  CONFIG_REQUIRED: '⚠️',
  CREDENTIALS_REQUIRED: '⚠️',
  STORE_SETUP_REQUIRED: '🏬',
  DEVICE_QA_REQUIRED: '📱',
  BLOCKED: '⛔',
  DISABLED: '⏸️',
  ERROR: '❌',
};

const CATEGORY_LABEL: Record<string, string> = {
  mobile: 'Mobile / CI',
  infrastructure: 'Infrastructure',
  integrations: 'Integrations',
  billing: 'Billing',
  'device-qa': 'Physical-device QA',
  operations: 'Operations',
};

function groupByCategory(items: ReleaseReadinessItem[]): Array<[string, ReleaseReadinessItem[]]> {
  const order: string[] = [];
  const groups = new Map<string, ReleaseReadinessItem[]>();
  for (const item of items) {
    if (!groups.has(item.category)) {
      groups.set(item.category, []);
      order.push(item.category);
    }
    groups.get(item.category)!.push(item);
  }
  return order.map((category) => [category, groups.get(category)!]);
}

// Release Readiness admin UI — Build Session 12 Part 25-26. Read-only:
// every value here reflects live server configuration (see
// ReleaseReadinessService), nothing on this page is editable.
export function ReleaseReadinessPage() {
  const [readiness, setReadiness] = useState<ReleaseReadiness | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const result = await adminApi.getReleaseReadiness();
      setReadiness(result);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Something went wrong.');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  return (
    <div>
      <h2>Release readiness</h2>

      {isLoading && <LoadingState />}
      {error && <ErrorState message={error} onRetry={load} />}

      {!isLoading && !error && readiness && (
        <>
          <p>
            Environment: <strong>{readiness.environment}</strong>
          </p>

          {readiness.items && readiness.items.length > 0 && (
            <>
              <h3>Beta readiness checklist</h3>
              {groupByCategory(readiness.items).map(([category, items]) => (
                <div key={category}>
                  <h4>{CATEGORY_LABEL[category] ?? category}</h4>
                  <table>
                    <tbody>
                      {items.map((item) => (
                        <tr key={item.key}>
                          <td>{STATUS_SYMBOL[item.status]}</td>
                          <td>{item.label}</td>
                          <td>{item.status}</td>
                          <td>{item.detail}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ))}
            </>
          )}

          <h3>Security</h3>
          <table>
            <tbody>
              <tr>
                <td>Production-safe overall</td>
                <td>
                  <StatusBadge ok={readiness.security.productionSafe} />
                </td>
              </tr>
              <tr>
                <td>Using dev JWT secrets</td>
                <td>
                  <StatusBadge ok={!readiness.security.usingDevJwtSecrets} />
                </td>
              </tr>
              <tr>
                <td>CORS wildcard</td>
                <td>
                  <StatusBadge ok={!readiness.security.corsWildcard} />
                </td>
              </tr>
            </tbody>
          </table>

          <h3>Integrations</h3>
          <table>
            <tbody>
              {Object.entries(readiness.integrations).map(([key, configured]) => (
                <tr key={key}>
                  <td>{key}</td>
                  <td>
                    <StatusBadge ok={configured} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          <h3>Database migrations</h3>
          <p>
            <StatusBadge ok={readiness.migrations.upToDate} />{' '}
            {readiness.migrations.upToDate
              ? 'Up to date'
              : `${readiness.migrations.pending.length} pending`}
          </p>
          {readiness.migrations.pending.length > 0 && (
            <ul>
              {readiness.migrations.pending.map((name) => (
                <li key={name}>{name}</li>
              ))}
            </ul>
          )}

          <h3>Feature flags</h3>
          <p>
            {readiness.featureFlags.enabled} of {readiness.featureFlags.total} enabled
          </p>
        </>
      )}
    </div>
  );
}
