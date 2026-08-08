import { apiClient } from './client';
import type { PaginationMeta } from './types';

export type CommunityReportStatus = 'OPEN' | 'REVIEWED' | 'ACTIONED';
export type CommunityReportTargetType = 'POST' | 'COMMENT' | 'PROFILE' | 'MEDIA_ASSET';

export interface CommunityReport {
  id: string;
  reporterId: string;
  targetType: CommunityReportTargetType;
  targetId: string;
  reason: string;
  status: CommunityReportStatus;
  createdAt: string;
}

export type AffordabilityStatus = 'PENDING' | 'APPROVED' | 'REJECTED';

export interface AffordabilityEligibility {
  id: string;
  userId: string;
  program: string;
  status: AffordabilityStatus;
  notes: string | null;
  submittedAt: string;
  reviewedAt: string | null;
}

export type SupportTicketStatus = 'OPEN' | 'IN_PROGRESS' | 'RESOLVED' | 'CLOSED';

export interface SupportTicket {
  id: string;
  userId: string;
  category: string;
  subject: string;
  message: string;
  status: SupportTicketStatus;
  createdAt: string;
  resolvedAt: string | null;
}

export interface SupportTicketReply {
  id: string;
  ticketId: string;
  authorId: string;
  isStaff: boolean;
  body: string;
  createdAt: string;
}

export type PromotedCampaignStatus = 'PENDING_REVIEW' | 'ACTIVE' | 'REJECTED' | 'ENDED';

export interface PromotedCampaign {
  id: string;
  creatorId: string;
  postId: string;
  status: PromotedCampaignStatus;
  createdAt: string;
}

interface Page<T> {
  data: T[];
  meta: PaginationMeta;
}

// Granular admin RBAC — Build Session 9 Part 19. Kept in sync with
// services/api's AdminPermission enum.
export type AdminPermission =
  | 'MODERATE_COMMUNITY'
  | 'REVIEW_ELIGIBILITY'
  | 'MANAGE_SUPPORT'
  | 'REVIEW_PROMOTIONS'
  | 'MANAGE_ADMINS';

export const ADMIN_PERMISSIONS: AdminPermission[] = [
  'MODERATE_COMMUNITY',
  'REVIEW_ELIGIBILITY',
  'MANAGE_SUPPORT',
  'REVIEW_PROMOTIONS',
  'MANAGE_ADMINS',
];

export interface AdminAccount {
  id: string;
  email: string;
  permissions: AdminPermission[];
}

export const adminApi = {
  listReports: (status?: CommunityReportStatus) =>
    apiClient.get<Page<CommunityReport>>('/admin/community-reports', {
      status,
    }),
  actionReport: (id: string, status: CommunityReportStatus, removeContent?: boolean) =>
    apiClient.patch<CommunityReport>(`/admin/community-reports/${id}`, {
      status,
      removeContent,
    }),

  listEligibility: (status?: AffordabilityStatus) =>
    apiClient.get<Page<AffordabilityEligibility>>('/admin/eligibility-applications', { status }),
  decideEligibility: (userId: string, status: AffordabilityStatus) =>
    apiClient.patch<AffordabilityEligibility>(`/admin/eligibility-applications/${userId}`, {
      status,
    }),

  listTickets: (status?: SupportTicketStatus) =>
    apiClient.get<Page<SupportTicket>>('/admin/support-tickets', { status }),
  getTicket: (id: string) =>
    apiClient.get<SupportTicket & { replies: SupportTicketReply[] }>(
      `/admin/support-tickets/${id}`,
    ),
  replyToTicket: (id: string, body: string, status?: SupportTicketStatus) =>
    apiClient.patch<SupportTicketReply>(`/admin/support-tickets/${id}/reply`, {
      body,
      status,
    }),

  listCampaigns: (status?: PromotedCampaignStatus) =>
    apiClient.get<Page<PromotedCampaign>>('/admin/promoted-campaigns', {
      status,
    }),
  decideCampaign: (id: string, status: 'ACTIVE' | 'REJECTED') =>
    apiClient.patch<PromotedCampaign>(`/admin/promoted-campaigns/${id}`, {
      status,
    }),

  getMyPermissions: () =>
    apiClient.get<{ userId: string; permissions: AdminPermission[] }>('/admin/me/permissions'),
  listAdmins: () => apiClient.get<AdminAccount[]>('/admin/admins'),
  grantPermission: (userId: string, permission: AdminPermission) =>
    apiClient.post<{ userId: string; permissions: AdminPermission[] }>(
      `/admin/admins/${userId}/permissions`,
      { permission },
    ),
  revokePermission: (userId: string, permission: AdminPermission) =>
    apiClient.delete<{ userId: string; permissions: AdminPermission[] }>(
      `/admin/admins/${userId}/permissions/${permission}`,
    ),
};
