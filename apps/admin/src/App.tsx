import type { ReactNode } from 'react';
import { Navigate, Route, Routes } from 'react-router-dom';
import { Layout } from './components/Layout';
import { AuthProvider, useAuth } from './auth/AuthContext';
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
        <Route path="/support-tickets" element={<SupportTicketsPage />} />
        <Route path="/community-reports" element={<CommunityReportsPage />} />
        <Route path="/eligibility" element={<EligibilityPage />} />
        <Route path="/promoted-campaigns" element={<PromotedCampaignsPage />} />
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
