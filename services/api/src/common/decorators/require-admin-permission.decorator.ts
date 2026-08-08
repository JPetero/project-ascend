import { SetMetadata } from '@nestjs/common';
import { AdminPermission } from '@prisma/client';

export const ADMIN_PERMISSION_KEY = 'adminPermission';

/**
 * Tags a route with the specific `AdminPermission` an ADMIN-role
 * account needs in order to call it — see AdminPermissionGuard, which
 * reads this metadata and checks it against the caller's
 * AdminPermissionGrant rows.
 */
export const RequireAdminPermission = (permission: AdminPermission) =>
  SetMetadata(ADMIN_PERMISSION_KEY, permission);
