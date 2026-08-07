import { useAuth } from '../auth/AuthContext';

/** Shown when a real, successfully-authenticated account is signed in
 * but its role isn't ADMIN — distinct from a login failure. Never
 * silently lets a MEMBER account reach a moderation queue. */
export function NotAuthorizedPage() {
  const { user, logout } = useAuth();

  return (
    <div className="login-page">
      <div>
        <h1>Not authorized</h1>
        <p>
          {user?.email} is signed in but does not have admin access. Ask an existing admin to grant
          your account the ADMIN role.
        </p>
        <button onClick={logout}>Sign out</button>
      </div>
    </div>
  );
}
