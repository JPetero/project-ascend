import { useState } from 'react';
import { adminApi } from '../api/adminApi';
import type { AffordabilityStatus } from '../api/adminApi';
import { ApiError } from '../api/client';
import { EmptyState, ErrorState, LoadingState } from '../components/StateViews';
import { usePagedResource } from '../hooks/usePagedResource';

const STATUSES: AffordabilityStatus[] = ['PENDING', 'APPROVED', 'REJECTED'];

export function EligibilityPage() {
  const [statusFilter, setStatusFilter] = useState<AffordabilityStatus | ''>('PENDING');
  const [actionError, setActionError] = useState<string | null>(null);
  const { items, isLoading, error, reload } = usePagedResource(
    () => adminApi.listEligibility(statusFilter || undefined),
    [statusFilter],
  );

  const decide = async (userId: string, status: AffordabilityStatus) => {
    setActionError(null);
    try {
      await adminApi.decideEligibility(userId, status);
      reload();
    } catch (err) {
      setActionError(err instanceof ApiError ? err.message : 'Something went wrong.');
    }
  };

  return (
    <div>
      <h2>Affordability eligibility applications</h2>
      <label>
        Status
        <select
          value={statusFilter}
          onChange={(event) => setStatusFilter(event.target.value as AffordabilityStatus | '')}
        >
          <option value="">All</option>
          {STATUSES.map((status) => (
            <option key={status} value={status}>
              {status}
            </option>
          ))}
        </select>
      </label>

      {actionError && <ErrorState message={actionError} />}
      {isLoading && <LoadingState />}
      {error && <ErrorState message={error} onRetry={reload} />}
      {!isLoading && !error && items.length === 0 && (
        <EmptyState message="No eligibility applications match this filter." />
      )}

      {!isLoading && !error && items.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>User</th>
              <th>Program</th>
              <th>Notes</th>
              <th>Status</th>
              <th>Submitted</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {items.map((application) => (
              <tr key={application.id}>
                <td>{application.userId}</td>
                <td>{application.program}</td>
                <td>{application.notes ?? '—'}</td>
                <td>{application.status}</td>
                <td>{new Date(application.submittedAt).toLocaleString()}</td>
                <td>
                  {application.status === 'PENDING' && (
                    <>
                      <button onClick={() => decide(application.userId, 'APPROVED')}>
                        Approve
                      </button>
                      <button onClick={() => decide(application.userId, 'REJECTED')}>Reject</button>
                    </>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
