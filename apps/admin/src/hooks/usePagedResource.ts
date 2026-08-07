import { useCallback, useEffect, useState } from 'react';
import { ApiError } from '../api/client';
import type { PaginationMeta } from '../api/types';

interface PagedResult<T> {
  items: T[];
  meta: PaginationMeta | null;
  isLoading: boolean;
  error: string | null;
  reload: () => void;
}

/** Shared list/loading/error state for the four admin moderation queues
 * (support tickets, community reports, eligibility, promoted campaigns)
 * — Build Session 8 Part 17. Re-fetches whenever `deps` changes (e.g.
 * a status filter), and again after `reload()` is called (e.g. after
 * an action mutates the list). */
export function usePagedResource<T>(
  fetcher: () => Promise<{ data: T[]; meta: PaginationMeta }>,
  deps: unknown[],
): PagedResult<T> {
  const [items, setItems] = useState<T[]>([]);
  const [meta, setMeta] = useState<PaginationMeta | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [reloadToken, setReloadToken] = useState(0);

  const load = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const page = await fetcher();
      setItems(page.data);
      setMeta(page.meta);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Something went wrong.');
    } finally {
      setIsLoading(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);

  useEffect(() => {
    load();
  }, [load, reloadToken]);

  const reload = useCallback(() => setReloadToken((t) => t + 1), []);

  return { items, meta, isLoading, error, reload };
}
