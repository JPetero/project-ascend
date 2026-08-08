import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AdminPermission, UserRole } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthenticatedUser } from '../../modules/auth/types/jwt-payload.type';
import { ADMIN_PERMISSION_KEY } from '../decorators/require-admin-permission.decorator';

/**
 * Gates the `admin` module — replaces the old binary AdminGuard (Build
 * Session 9 Part 19). Still requires `UserRole.ADMIN` as a floor (being
 * staff at all remains an out-of-band DB operation — see
 * build-session-7.md Part 10), then additionally checks the specific
 * `AdminPermission` a route is tagged with via `@RequireAdminPermission`
 * against the caller's `AdminPermissionGrant` rows. A route with no tag
 * only requires plain ADMIN, same as before. Permission is read fresh
 * from the DB on every request, matching AuthenticatedUser.role's own
 * "never trust a cached/JWT claim" posture — revoking a specific
 * permission takes effect on the caller's very next request.
 */
@Injectable()
export class AdminPermissionGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<{ user?: AuthenticatedUser }>();
    if (request.user?.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Admin access required.');
    }

    const requiredPermission = this.reflector.get<AdminPermission | undefined>(
      ADMIN_PERMISSION_KEY,
      context.getHandler(),
    );
    if (!requiredPermission) return true;

    const grant = await this.prisma.adminPermissionGrant.findUnique({
      where: {
        userId_permission: {
          userId: request.user.id,
          permission: requiredPermission,
        },
      },
    });
    if (!grant) {
      throw new ForbiddenException(`Missing admin permission: ${requiredPermission}.`);
    }
    return true;
  }
}
