import { useState } from 'react';
import { adminApi } from '../api/adminApi';
import type { CommunityReportStatus } from '../api/adminApi';
import { ApiError } from '../api/client';
import { EmptyState, ErrorState, LoadingState } from '../components/StateViews';
import { usePagedResource } from '../hooks/usePagedResource';

const STATUSES: CommunityReportStatus[] = ['OPEN', 'REVIEWED', 'ACTIONED'];

export function CommunityReportsPage() {
  const [statusFilter, setStatusFilter] = useState<CommunityReportStatus | ''>('OPEN');
  const [actionError, setActionError] = useState<string | null>(null);
  const { items, isLoading, error, reload } = usePagedResource(
    () => adminApi.listReports(statusFilter || undefined),
    [statusFilter],
  );

  const decide = async (id: string, status: CommunityReportStatus, removeContent?: boolean) => {
    setActionError(null);
    try {
      await adminApi.actionReport(id, status, removeContent);
      reload();
    } catch (err) {
      setActionError(err instanceof ApiError ? err.message : 'Something went wrong.');
    }
  };

  return (
    <div>
      <h2>Community reports</h2>
      <label>
        Status
        <select
          value={statusFilter}
          onChange={(event) => setStatusFilter(event.target.value as CommunityReportStatus | '')}
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
        <EmptyState message="No community reports match this filter." />
      )}

      {!isLoading && !error && items.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Target</th>
              <th>Reason</th>
              <th>Status</th>
              <th>Reported</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {items.map((report) => (
              <tr key={report.id}>
                <td>
                  {report.targetType} · {report.targetId}
                </td>
                <td>{report.reason}</td>
                <td>{report.status}</td>
                <td>{new Date(report.createdAt).toLocaleString()}</td>
                <td>
                  {report.status !== 'ACTIONED' && (
                    <>
                      <button onClick={() => decide(report.id, 'REVIEWED')}>Mark reviewed</button>
                      <button onClick={() => decide(report.id, 'ACTIONED', true)}>
                        Action &amp; remove content
                      </button>
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
