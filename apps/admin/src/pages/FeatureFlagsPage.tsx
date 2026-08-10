import { useCallback, useEffect, useState } from 'react';
import { adminApi } from '../api/adminApi';
import type { FeatureFlag } from '../api/adminApi';
import { ApiError } from '../api/client';
import { EmptyState, ErrorState, LoadingState } from '../components/StateViews';

// Feature Flags admin UI — Build Session 12 Part 25-26. The backend
// (Build Session 12 Part 15-17) has always supported arbitrary flag
// keys; there was just no admin surface to manage them until now.
// GET /admin/feature-flags returns a plain array, not the paginated
// {data, meta} envelope every other admin queue uses, so this page
// can't use usePagedResource and manages its own list state instead.
export function FeatureFlagsPage() {
  const [flags, setFlags] = useState<FeatureFlag[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);
  const [newKey, setNewKey] = useState('');

  const load = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const result = await adminApi.listFeatureFlags();
      setFlags(result);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Something went wrong.');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const toggleEnabled = async (flag: FeatureFlag) => {
    setActionError(null);
    try {
      await adminApi.upsertFeatureFlag(flag.key, { enabled: !flag.enabled });
      load();
    } catch (err) {
      setActionError(err instanceof ApiError ? err.message : 'Something went wrong.');
    }
  };

  const updateRollout = async (flag: FeatureFlag, rolloutPercentage: number) => {
    setActionError(null);
    try {
      await adminApi.upsertFeatureFlag(flag.key, { rolloutPercentage });
      load();
    } catch (err) {
      setActionError(err instanceof ApiError ? err.message : 'Something went wrong.');
    }
  };

  const remove = async (key: string) => {
    setActionError(null);
    try {
      await adminApi.deleteFeatureFlag(key);
      load();
    } catch (err) {
      setActionError(err instanceof ApiError ? err.message : 'Something went wrong.');
    }
  };

  const createFlag = async (event: React.FormEvent) => {
    event.preventDefault();
    if (!newKey.trim()) return;
    setActionError(null);
    try {
      await adminApi.upsertFeatureFlag(newKey.trim(), { enabled: false, rolloutPercentage: 0 });
      setNewKey('');
      load();
    } catch (err) {
      setActionError(err instanceof ApiError ? err.message : 'Something went wrong.');
    }
  };

  return (
    <div>
      <h2>Feature flags</h2>

      <form onSubmit={createFlag}>
        <label>
          New flag key
          <input value={newKey} onChange={(event) => setNewKey(event.target.value)} />
        </label>
        <button type="submit">Create</button>
      </form>

      {actionError && <ErrorState message={actionError} />}
      {isLoading && <LoadingState />}
      {error && <ErrorState message={error} onRetry={load} />}
      {!isLoading && !error && flags.length === 0 && (
        <EmptyState message="No feature flags exist yet." />
      )}

      {!isLoading && !error && flags.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Key</th>
              <th>Description</th>
              <th>Enabled</th>
              <th>Rollout %</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {flags.map((flag) => (
              <tr key={flag.id}>
                <td>{flag.key}</td>
                <td>{flag.description ?? '—'}</td>
                <td>
                  <input
                    type="checkbox"
                    checked={flag.enabled}
                    onChange={() => toggleEnabled(flag)}
                    aria-label={`${flag.key} enabled`}
                  />
                </td>
                <td>
                  <input
                    type="number"
                    min={0}
                    max={100}
                    value={flag.rolloutPercentage}
                    onChange={(event) => updateRollout(flag, Number(event.target.value))}
                    aria-label={`${flag.key} rollout percentage`}
                  />
                </td>
                <td>
                  <button onClick={() => remove(flag.key)}>Delete</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
