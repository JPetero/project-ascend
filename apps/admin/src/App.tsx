import type { ReactNode } from 'react';
import { Navigate, Route, Routes } from 'react-router-dom';
import type { AdminPermission } from './api/adminApi';
import { Layout } from './components/Layout';
import { AuthProvider, useAuth } from './auth/AuthContext';
import { AdminsPage } from './pages/AdminsPage';
import { CommunityReportsPage } from './pages/CommunityReportsPage';
import { EligibilityPage } from './pages/EligibilityPage';
import { LoginPage } from './pages/LoginPage';
import { NotAuthorizedPage } from './pages/NotAuthorizedPage';
import { PromotedCampaignsPage } from './pages/PromotedCampaignsPage';
import { SupportTicketsPage } from './pages/SupportTicketsPage';

function RequireAdmin({ children }: { children: ReactNode }) {
  const { user, isAdmin } = useAuth();
  if (!user) return <Navigate to="/login" replace />;
  if (!isAdmin) return <NotAuthorizedPage />;
  return <>{children}</>;
}

/** Route-level counterpart to Layout's nav filtering (Build Session 9
 * Part 19) — reachable directly by URL even when not in the nav, so
 * this is what actually keeps an ADMIN without the matching permission
 * off a page it would otherwise just get a 403 from the API on. */
function RequirePermission({
  permission,
  children,
}: {
  permission: AdminPermission;
  children: ReactNode;
}) {
  const { hasPermission } = useAuth();
  if (!hasPermission(permission)) return <NotAuthorizedPage />;
  return <>{children}</>;
}

function AppRoutes() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route
        element={
          <RequireAdmin>
            <Layout />
          </RequireAdmin>
        }
      >
        <Route
          path="/support-tickets"
          element={
            <RequirePermission permission="MANAGE_SUPPORT">
              <SupportTicketsPage />
            </RequirePermission>
          }
        />
        <Route
          path="/community-reports"
          element={
            <RequirePermission permission="MODERATE_COMMUNITY">
              <CommunityReportsPage />
            </RequirePermission>
          }
        />
        <Route
          path="/eligibility"
          element={
            <RequirePermission permission="REVIEW_ELIGIBILITY">
              <EligibilityPage />
            </RequirePermission>
          }
        />
        <Route
          path="/promoted-campaigns"
          element={
            <RequirePermission permission="REVIEW_PROMOTIONS">
              <PromotedCampaignsPage />
            </RequirePermission>
          }
        />
        <Route
          path="/admins"
          element={
            <RequirePermission permission="MANAGE_ADMINS">
              <AdminsPage />
            </RequirePermission>
          }
        />
        <Route path="/" element={<Navigate to="/support-tickets" replace />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

export function App() {
  return (
    <AuthProvider>
      <AppRoutes />
    </AuthProvider>
  );
}
