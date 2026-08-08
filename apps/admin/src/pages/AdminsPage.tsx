import { useCallback, useEffect, useState } from 'react';
import type { AdminAccount, AdminPermission } from '../api/adminApi';
import { ADMIN_PERMISSIONS, adminApi } from '../api/adminApi';
import { ApiError } from '../api/client';
import { EmptyState, ErrorState, LoadingState } from '../components/StateViews';

/**
 * Granular admin RBAC management (Build Session 9 Part 19) — the
 * self-service half of what used to be a purely out-of-band DB
 * operation. Only reachable by an account holding MANAGE_ADMINS (see
 * App.tsx's RequirePermission); becoming ADMIN in the first place is
 * still an out-of-band DB write (see build-session-7.md Part 10), and
 * so is the very first MANAGE_ADMINS grant.
 */
export function AdminsPage() {
  const [admins, setAdmins] = useState<AdminAccount[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);
  const [pendingPermission, setPendingPermission] = useState<Record<string, AdminPermission>>({});

  const load = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      setAdmins(await adminApi.listAdmins());
    } catch (err) {
      setError(err instanceof ApiError ? err.message : 'Something went wrong.');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const grant = async (userId: string) => {
    setActionError(null);
    const permission = pendingPermission[userId] ?? ADMIN_PERMISSIONS[0];
    try {
      await adminApi.grantPermission(userId, permission);
      await load();
    } catch (err) {
      setActionError(err instanceof ApiError ? err.message : 'Something went wrong.');
    }
  };

  const revoke = async (userId: string, permission: AdminPermission) => {
    setActionError(null);
    try {
      await adminApi.revokePermission(userId, permission);
      await load();
    } catch (err) {
      setActionError(err instanceof ApiError ? err.message : 'Something went wrong.');
    }
  };

  return (
    <div>
      <h2>Admins</h2>
      <p>
        Each admin can only use the surfaces it holds a specific permission for. Granting or
        revoking a permission takes effect on that admin&apos;s next request.
      </p>

      {actionError && <ErrorState message={actionError} />}
      {isLoading && <LoadingState />}
      {error && <ErrorState message={error} onRetry={load} />}
      {!isLoading && !error && admins.length === 0 && (
        <EmptyState message="No ADMIN-role accounts exist yet." />
      )}

      {!isLoading && !error && admins.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Admin</th>
              <th>Permissions</th>
              <th>Grant a permission</th>
            </tr>
          </thead>
          <tbody>
            {admins.map((admin) => (
              <tr key={admin.id}>
                <td>{admin.email}</td>
                <td>
                  {admin.permissions.length === 0 ? (
                    <em>No permissions granted</em>
                  ) : (
                    admin.permissions.map((permission) => (
                      <span key={permission} className="permission-badge">
                        {permission}
                        <button
                          type="button"
                          aria-label={`Revoke ${permission} from ${admin.email}`}
                          onClick={() => revoke(admin.id, permission)}
                        >
                          ×
                        </button>
                      </span>
                    ))
                  )}
                </td>
                <td>
                  <select
                    aria-label={`Permission to grant to ${admin.email}`}
                    value={pendingPermission[admin.id] ?? ADMIN_PERMISSIONS[0]}
                    onChange={(event) =>
                      setPendingPermission((prev) => ({
                        ...prev,
                        [admin.id]: event.target.value as AdminPermission,
                      }))
                    }
                  >
                    {ADMIN_PERMISSIONS.map((permission) => (
                      <option key={permission} value={permission}>
                        {permission}
                      </option>
                    ))}
                  </select>
                  <button type="button" onClick={() => grant(admin.id)}>
                    Grant
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
