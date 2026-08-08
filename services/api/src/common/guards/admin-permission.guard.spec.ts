import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AdminPermissionGuard } from './admin-permission.guard';

describe('AdminPermissionGuard', () => {
  const buildContext = (user: { role: string; id: string } | undefined): ExecutionContext =>
    ({
      switchToHttp: () => ({ getRequest: () => ({ user }) }),
      getHandler: () => jest.fn(),
    }) as unknown as ExecutionContext;

  it('rejects a non-ADMIN account before even checking the required permission', async () => {
    const prisma = { adminPermissionGrant: { findUnique: jest.fn() } };
    const reflector = { get: jest.fn().mockReturnValue('MODERATE_COMMUNITY') };
    const guard = new AdminPermissionGuard(reflector as unknown as Reflector, prisma as never);

    await expect(
      guard.canActivate(buildContext({ role: 'MEMBER', id: 'user-1' })),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(prisma.adminPermissionGrant.findUnique).not.toHaveBeenCalled();
  });

  it('allows an ADMIN through when the route requires no specific permission', async () => {
    const prisma = { adminPermissionGrant: { findUnique: jest.fn() } };
    const reflector = { get: jest.fn().mockReturnValue(undefined) };
    const guard = new AdminPermissionGuard(reflector as unknown as Reflector, prisma as never);

    await expect(guard.canActivate(buildContext({ role: 'ADMIN', id: 'admin-1' }))).resolves.toBe(
      true,
    );
    expect(prisma.adminPermissionGrant.findUnique).not.toHaveBeenCalled();
  });

  it('rejects an ADMIN who lacks the specific required permission grant', async () => {
    const prisma = { adminPermissionGrant: { findUnique: jest.fn().mockResolvedValue(null) } };
    const reflector = { get: jest.fn().mockReturnValue('MANAGE_ADMINS') };
    const guard = new AdminPermissionGuard(reflector as unknown as Reflector, prisma as never);

    await expect(
      guard.canActivate(buildContext({ role: 'ADMIN', id: 'admin-1' })),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('allows an ADMIN who holds the specific required permission grant', async () => {
    const prisma = {
      adminPermissionGrant: {
        findUnique: jest.fn().mockResolvedValue({ id: 'grant-1' }),
      },
    };
    const reflector = { get: jest.fn().mockReturnValue('MANAGE_ADMINS') };
    const guard = new AdminPermissionGuard(reflector as unknown as Reflector, prisma as never);

    await expect(guard.canActivate(buildContext({ role: 'ADMIN', id: 'admin-1' }))).resolves.toBe(
      true,
    );
    expect(prisma.adminPermissionGrant.findUnique).toHaveBeenCalledWith({
      where: { userId_permission: { userId: 'admin-1', permission: 'MANAGE_ADMINS' } },
    });
  });
});
