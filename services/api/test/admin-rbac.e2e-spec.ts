import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

/**
 * Build Session 9 Part 19 — granular admin RBAC. Exercises the
 * permission-scoped guard and the MANAGE_ADMINS grant/revoke flow that
 * replaced the old binary AdminGuard.
 */
describe('Admin RBAC (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let memberToken: string;
  let memberId: string;
  let bareAdminToken: string;
  let bareAdminId: string;
  let managerToken: string;

  const register = async (email: string, firstName: string) => {
    const res = await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        firstName,
        email,
        password: 'Str0ngPass!',
        confirmPassword: 'Str0ngPass!',
        acceptedTerms: true,
      })
      .expect(201);
    return {
      token: res.body.data.tokens.accessToken as string,
      id: res.body.data.user.id as string,
    };
  };

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }),
    );
    app.useGlobalFilters(new AllExceptionsFilter());
    app.useGlobalInterceptors(new ResponseEnvelopeInterceptor());
    await app.init();

    prisma = app.get(PrismaService);
    await resetDatabase(prisma);

    const member = await register('rbac-member@example.com', 'Mel');
    memberToken = member.token;
    memberId = member.id;

    const bareAdmin = await register('rbac-bare-admin@example.com', 'Bea');
    bareAdminToken = bareAdmin.token;
    bareAdminId = bareAdmin.id;
    await prisma.user.update({ where: { id: bareAdmin.id }, data: { role: 'ADMIN' } });

    const manager = await register('rbac-manager@example.com', 'Max');
    managerToken = manager.token;
    await prisma.user.update({ where: { id: manager.id }, data: { role: 'ADMIN' } });
    // Out-of-band bootstrap grant, same posture as UserRole.ADMIN itself
    // (see AdminPermissionGuard's doc comment).
    await prisma.adminPermissionGrant.create({
      data: { userId: manager.id, permission: 'MANAGE_ADMINS' },
    });
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  it('rejects a non-admin from the RBAC surface itself', async () => {
    await request(app.getHttpServer())
      .get('/admin/admins')
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(403);
  });

  it('rejects an ADMIN with no permission grants from every permission-tagged route', async () => {
    await request(app.getHttpServer())
      .get('/admin/community-reports')
      .set('Authorization', `Bearer ${bareAdminToken}`)
      .expect(403);
    await request(app.getHttpServer())
      .get('/admin/admins')
      .set('Authorization', `Bearer ${bareAdminToken}`)
      .expect(403);
  });

  it('lets any ADMIN read its own permission grants without a specific permission', async () => {
    const res = await request(app.getHttpServer())
      .get('/admin/me/permissions')
      .set('Authorization', `Bearer ${bareAdminToken}`)
      .expect(200);
    expect(res.body.data.permissions).toEqual([]);
  });

  it('lists admins with their current permission grants, gated by MANAGE_ADMINS', async () => {
    const res = await request(app.getHttpServer())
      .get('/admin/admins')
      .set('Authorization', `Bearer ${managerToken}`)
      .expect(200);

    const bare = res.body.data.find((a: { id: string }) => a.id === bareAdminId);
    expect(bare).toBeDefined();
    expect(bare.permissions).toEqual([]);
  });

  it('rejects a made-up permission value in the grant body', async () => {
    await request(app.getHttpServer())
      .post(`/admin/admins/${bareAdminId}/permissions`)
      .set('Authorization', `Bearer ${managerToken}`)
      .send({ permission: 'NOT_A_REAL_PERMISSION' })
      .expect(400);
  });

  it('refuses to grant a permission to a non-ADMIN account', async () => {
    await request(app.getHttpServer())
      .post(`/admin/admins/${memberId}/permissions`)
      .set('Authorization', `Bearer ${managerToken}`)
      .send({ permission: 'MODERATE_COMMUNITY' })
      .expect(400);
  });

  it('grants a permission that immediately unlocks the matching route', async () => {
    await request(app.getHttpServer())
      .get('/admin/community-reports')
      .set('Authorization', `Bearer ${bareAdminToken}`)
      .expect(403);

    const grant = await request(app.getHttpServer())
      .post(`/admin/admins/${bareAdminId}/permissions`)
      .set('Authorization', `Bearer ${managerToken}`)
      .send({ permission: 'MODERATE_COMMUNITY' })
      .expect(201);
    expect(grant.body.data.permissions).toContain('MODERATE_COMMUNITY');

    await request(app.getHttpServer())
      .get('/admin/community-reports')
      .set('Authorization', `Bearer ${bareAdminToken}`)
      .expect(200);
  });

  it('is idempotent when the same permission is granted twice', async () => {
    await request(app.getHttpServer())
      .post(`/admin/admins/${bareAdminId}/permissions`)
      .set('Authorization', `Bearer ${managerToken}`)
      .send({ permission: 'MODERATE_COMMUNITY' })
      .expect(201);

    const res = await request(app.getHttpServer())
      .get('/admin/admins')
      .set('Authorization', `Bearer ${managerToken}`)
      .expect(200);
    const bare = res.body.data.find((a: { id: string }) => a.id === bareAdminId);
    expect(bare.permissions.filter((p: string) => p === 'MODERATE_COMMUNITY')).toHaveLength(1);
  });

  it('revokes a permission and immediately locks the matching route again', async () => {
    await request(app.getHttpServer())
      .delete(`/admin/admins/${bareAdminId}/permissions/MODERATE_COMMUNITY`)
      .set('Authorization', `Bearer ${managerToken}`)
      .expect(200);

    await request(app.getHttpServer())
      .get('/admin/community-reports')
      .set('Authorization', `Bearer ${bareAdminToken}`)
      .expect(403);
  });

  it('rejects a made-up permission value on revoke', async () => {
    await request(app.getHttpServer())
      .delete(`/admin/admins/${bareAdminId}/permissions/NOT_A_REAL_PERMISSION`)
      .set('Authorization', `Bearer ${managerToken}`)
      .expect(400);
  });

  it('refuses to let an ADMIN without MANAGE_ADMINS grant permissions to anyone, including themselves', async () => {
    await request(app.getHttpServer())
      .post(`/admin/admins/${bareAdminId}/permissions`)
      .set('Authorization', `Bearer ${bareAdminToken}`)
      .send({ permission: 'MODERATE_COMMUNITY' })
      .expect(403);
  });
});
