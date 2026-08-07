import { useCallback, useEffect, useState } from 'react';
import { adminApi } from '../api/adminApi';
import type { SupportTicketReply, SupportTicketStatus } from '../api/adminApi';
import { ApiError } from '../api/client';
import { EmptyState, ErrorState, LoadingState } from '../components/StateViews';
import { usePagedResource } from '../hooks/usePagedResource';

const STATUSES: SupportTicketStatus[] = ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'];

export function SupportTicketsPage() {
  const [statusFilter, setStatusFilter] = useState<SupportTicketStatus | ''>('OPEN');
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const { items, isLoading, error, reload } = usePagedResource(
    () => adminApi.listTickets(statusFilter || undefined),
    [statusFilter],
  );

  return (
    <div>
      <h2>Support tickets</h2>
      <label>
        Status
        <select
          value={statusFilter}
          onChange={(event) => setStatusFilter(event.target.value as SupportTicketStatus | '')}
        >
          <option value="">All</option>
          {STATUSES.map((status) => (
            <option key={status} value={status}>
              {status}
            </option>
          ))}
        </select>
      </label>

      {isLoading && <LoadingState />}
      {error && <ErrorState message={error} onRetry={reload} />}
      {!isLoading && !error && items.length === 0 && (
        <EmptyState message="No support tickets match this filter." />
      )}

      {!isLoading && !error && items.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Subject</th>
              <th>Category</th>
              <th>Status</th>
              <th>Created</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {items.map((ticket) => (
              <tr key={ticket.id}>
                <td>{ticket.subject}</td>
                <td>{ticket.category}</td>
                <td>{ticket.status}</td>
                <td>{new Date(ticket.createdAt).toLocaleString()}</td>
                <td>
                  <button onClick={() => setSelectedId(ticket.id)}>Open</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

      {selectedId && (
        <TicketDetail
          ticketId={selectedId}
          onClose={() => setSelectedId(null)}
          onReplied={reload}
        />
      )}
    </div>
  );
}

function TicketDetail({
  ticketId,
  onClose,
  onReplied,
}: {
  ticketId: string;
  onClose: () => void;
  onReplied: () => void;
}) {
  const [ticket, setTicket] = useState<Awaited<ReturnType<typeof adminApi.getTicket>> | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [replyBody, setReplyBody] = useState('');
  const [nextStatus, setNextStatus] = useState<SupportTicketStatus | ''>('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const load = useCallback(() => {
    setIsLoading(true);
    setError(null);
    adminApi
      .getTicket(ticketId)
      .then(setTicket)
      .catch((err) => setError(err instanceof ApiError ? err.message : 'Something went wrong.'))
      .finally(() => setIsLoading(false));
  }, [ticketId]);

  useEffect(() => {
    load();
  }, [load]);

  const submitReply = async (event: React.FormEvent) => {
    event.preventDefault();
    if (!replyBody.trim()) return;
    setIsSubmitting(true);
    setError(null);
    try {
      await adminApi.replyToTicket(ticketId, replyBody.trim(), nextStatus || undefined);
      setReplyBody('');
      setNextStatus('');
      load();
      onReplied();
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Something went wrong.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="detail-panel" role="dialog" aria-label="Ticket detail">
      <button onClick={onClose}>Close</button>
      {isLoading && <LoadingState />}
      {error && <ErrorState message={error} onRetry={load} />}
      {ticket && (
        <>
          <h3>{ticket.subject}</h3>
          <p>{ticket.message}</p>
          <ul>
            {ticket.replies.map((reply: SupportTicketReply) => (
              <li key={reply.id}>
                <strong>{reply.isStaff ? 'Staff' : 'User'}:</strong> {reply.body}
              </li>
            ))}
          </ul>
          <form onSubmit={submitReply}>
            <label>
              Reply
              <textarea
                value={replyBody}
                onChange={(event) => setReplyBody(event.target.value)}
                required
              />
            </label>
            <label>
              Set status
              <select
                value={nextStatus}
                onChange={(event) => setNextStatus(event.target.value as SupportTicketStatus | '')}
              >
                <option value="">Leave unchanged</option>
                {STATUSES.map((status) => (
                  <option key={status} value={status}>
                    {status}
                  </option>
                ))}
              </select>
            </label>
            <button type="submit" disabled={isSubmitting}>
              {isSubmitting ? 'Sending…' : 'Send reply'}
            </button>
          </form>
        </>
      )}
    </div>
  );
}
