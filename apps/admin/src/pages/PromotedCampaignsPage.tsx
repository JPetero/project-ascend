import { useState } from 'react';
import { adminApi } from '../api/adminApi';
import type { PromotedCampaignStatus } from '../api/adminApi';
import { ApiError } from '../api/client';
import { EmptyState, ErrorState, LoadingState } from '../components/StateViews';
import { usePagedResource } from '../hooks/usePagedResource';

const STATUSES: PromotedCampaignStatus[] = ['PENDING_REVIEW', 'ACTIVE', 'REJECTED', 'ENDED'];

export function PromotedCampaignsPage() {
  const [statusFilter, setStatusFilter] = useState<PromotedCampaignStatus | ''>('PENDING_REVIEW');
  const [actionError, setActionError] = useState<string | null>(null);
  const { items, isLoading, error, reload } = usePagedResource(
    () => adminApi.listCampaigns(statusFilter || undefined),
    [statusFilter],
  );

  const decide = async (id: string, status: 'ACTIVE' | 'REJECTED') => {
    setActionError(null);
    try {
      await adminApi.decideCampaign(id, status);
      reload();
    } catch (err) {
      setActionError(err instanceof ApiError ? err.message : 'Something went wrong.');
    }
  };

  return (
    <div>
      <h2>Promoted campaigns</h2>
      <label>
        Status
        <select
          value={statusFilter}
          onChange={(event) => setStatusFilter(event.target.value as PromotedCampaignStatus | '')}
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
        <EmptyState message="No promoted campaigns match this filter." />
      )}

      {!isLoading && !error && items.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Post</th>
              <th>Creator</th>
              <th>Status</th>
              <th>Created</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {items.map((campaign) => (
              <tr key={campaign.id}>
                <td>{campaign.postId}</td>
                <td>{campaign.creatorId}</td>
                <td>{campaign.status}</td>
                <td>{new Date(campaign.createdAt).toLocaleString()}</td>
                <td>
                  {campaign.status === 'PENDING_REVIEW' && (
                    <>
                      <button onClick={() => decide(campaign.id, 'ACTIVE')}>Approve</button>
                      <button onClick={() => decide(campaign.id, 'REJECTED')}>Reject</button>
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
