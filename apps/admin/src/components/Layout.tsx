import { NavLink, Outlet } from 'react-router-dom';
import type { AdminPermission } from '../api/adminApi';
import { useAuth } from '../auth/AuthContext';

// Each item's `permission` is the AdminPermission (Build Session 9 Part
// 19) that must be granted for this account to see the item at all —
// matches exactly what the corresponding page's API calls require
// server-side, so nothing is shown that would just 403 anyway.
const NAV_ITEMS: { to: string; label: string; permission: AdminPermission }[] = [
  { to: '/support-tickets', label: 'Support tickets', permission: 'MANAGE_SUPPORT' },
  { to: '/community-reports', label: 'Community reports', permission: 'MODERATE_COMMUNITY' },
  { to: '/eligibility', label: 'Affordability eligibility', permission: 'REVIEW_ELIGIBILITY' },
  { to: '/promoted-campaigns', label: 'Promoted campaigns', permission: 'REVIEW_PROMOTIONS' },
  { to: '/admins', label: 'Admins', permission: 'MANAGE_ADMINS' },
  {
    to: '/trainer-verification',
    label: 'Trainer verification',
    permission: 'REVIEW_TRAINER_VERIFICATION',
  },
  { to: '/feature-flags', label: 'Feature flags', permission: 'MANAGE_PLATFORM' },
  { to: '/release-readiness', label: 'Release readiness', permission: 'MANAGE_PLATFORM' },
];

export function Layout() {
  const { user, logout, hasPermission } = useAuth();
  const visibleItems = NAV_ITEMS.filter((item) => hasPermission(item.permission));

  return (
    <div className="layout">
      <aside className="sidebar">
        <h1>Ascend Admin</h1>
        <nav>
          <ul>
            {visibleItems.map((item) => (
              <li key={item.to}>
                <NavLink to={item.to}>{item.label}</NavLink>
              </li>
            ))}
          </ul>
        </nav>
        <div className="sidebar-footer">
          <p>{user?.email}</p>
          <button onClick={logout}>Sign out</button>
        </div>
      </aside>
      <main className="content">
        <Outlet />
      </main>
    </div>
  );
}
