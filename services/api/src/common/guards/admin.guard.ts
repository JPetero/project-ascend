import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { AuthenticatedUser } from '../../modules/auth/types/jwt-payload.type';

/**
 * Gates the `admin` module — moderation and support-queue endpoints.
 * Runs after the global `JwtAuthGuard`, so `request.user` is always
 * populated by this point. Role is read fresh from the DB on every
 * request (see JwtStrategy.validate), never trusted from a JWT claim,
 * so revoking ADMIN takes effect immediately rather than waiting for
 * the token to expire.
 */
@Injectable()
export class AdminGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<{ user?: AuthenticatedUser }>();
    if (request.user?.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Admin access required.');
    }
    return true;
  }
}
