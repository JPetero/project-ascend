import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { requestLoggingMiddleware } from '../src/common/middleware/request-logging.middleware';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

/**
 * Build Session 12 Part 15-17 — Feature Flags platform + Release
 * Readiness diagnostic. Covers the admin CRUD surface (gated by
 * MANAGE_PLATFORM), the client-facing resolve endpoint's fail-open
 * contract, and that the readiness diagnostic never leaks a real secret
 * value.
 */
describe('Feature Flags and Release Readiness (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let memberToken: string;
  let platformAdminToken: string;
  let bareAdminToken: string;

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
    app.use(requestLoggingMiddleware);
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }),
    );
    app.useGlobalFilters(new AllExceptionsFilter());
    app.useGlobalInterceptors(new ResponseEnvelopeInterceptor());
    await app.init();

    prisma = app.get(PrismaService);
    await resetDatabase(prisma);

    const member = await register('flags-member@example.com', 'Fara');
    memberToken = member.token;

    const platformAdmin = await register('flags-platform-admin@example.com', 'Pia');
    platformAdminToken = platformAdmin.token;
    await prisma.user.update({ where: { id: platformAdmin.id }, data: { role: 'ADMIN' } });
    await prisma.adminPermissionGrant.create({
      data: { userId: platformAdmin.id, permission: 'MANAGE_PLATFORM' },
    });

    const bareAdmin = await register('flags-bare-admin@example.com', 'Bo');
    bareAdminToken = bareAdmin.token;
    await prisma.user.update({ where: { id: bareAdmin.id }, data: { role: 'ADMIN' } });
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  it('rejects a plain member and an ADMIN without MANAGE_PLATFORM from the admin flag routes', async () => {
    await request(app.getHttpServer())
      .get('/admin/feature-flags')
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(403);
    await request(app.getHttpServer())
      .get('/admin/feature-flags')
      .set('Authorization', `Bearer ${bareAdminToken}`)
      .expect(403);
  });

  it('a key absent from the resolved map is fail-open (never present as false) for an ordinary member', async () => {
    const res = await request(app.getHttpServer())
      .get('/feature-flags')
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(200);
    expect(res.body.data).toEqual({});
  });

  it('creates a flag via the admin route and it appears in the listing', async () => {
    const created = await request(app.getHttpServer())
      .post('/admin/feature-flags/trainer_dashboard')
      .set('Authorization', `Bearer ${platformAdminToken}`)
      .send({ description: 'Trainer dashboard icon', enabled: true, rolloutPercentage: 100 })
      .expect(201);
    expect(created.body.data.key).toBe('trainer_dashboard');
    expect(created.body.data.enabled).toBe(true);

    const listed = await request(app.getHttpServer())
      .get('/admin/feature-flags')
      .set('Authorization', `Bearer ${platformAdminToken}`)
      .expect(200);
    expect(listed.body.data.map((f: { key: string }) => f.key)).toContain('trainer_dashboard');
  });

  it('resolves an enabled 100%-rollout flag to true for a signed-in member', async () => {
    const res = await request(app.getHttpServer())
      .get('/feature-flags')
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(200);
    expect(res.body.data.trainer_dashboard).toBe(true);
  });

  it('disabling the flag resolves it to false, not absent, for the member', async () => {
    await request(app.getHttpServer())
      .post('/admin/feature-flags/trainer_dashboard')
      .set('Authorization', `Bearer ${platformAdminToken}`)
      .send({ enabled: false })
      .expect(201);

    const res = await request(app.getHttpServer())
      .get('/feature-flags')
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(200);
    expect(res.body.data.trainer_dashboard).toBe(false);
  });

  it('deletes a flag, after which it is absent (fail-open) from resolution again', async () => {
    await request(app.getHttpServer())
      .delete('/admin/feature-flags/trainer_dashboard')
      .set('Authorization', `Bearer ${platformAdminToken}`)
      .expect(200);

    const res = await request(app.getHttpServer())
      .get('/feature-flags')
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(200);
    expect(res.body.data.trainer_dashboard).toBeUndefined();
  });

  it('404s deleting a flag that does not exist', async () => {
    await request(app.getHttpServer())
      .delete('/admin/feature-flags/does_not_exist')
      .set('Authorization', `Bearer ${platformAdminToken}`)
      .expect(404);
  });

  it('rejects a non-MANAGE_PLATFORM caller from the release readiness diagnostic', async () => {
    await request(app.getHttpServer())
      .get('/admin/release-readiness')
      .set('Authorization', `Bearer ${bareAdminToken}`)
      .expect(403);
  });

  it('returns the readiness diagnostic with configured/not-configured booleans, never a raw secret', async () => {
    const res = await request(app.getHttpServer())
      .get('/admin/release-readiness')
      .set('Authorization', `Bearer ${platformAdminToken}`)
      .expect(200);

    expect(res.body.data).toHaveProperty('environment');
    expect(res.body.data).toHaveProperty('security.usingDevJwtSecrets');
    expect(res.body.data).toHaveProperty('integrations.aiProvider');
    expect(res.body.data).toHaveProperty('featureFlags.total');
    expect(JSON.stringify(res.body.data)).not.toMatch(/sk-|AIza|-----BEGIN/);
  });

  it('echoes a correlation id header on every response', async () => {
    const res = await request(app.getHttpServer())
      .get('/feature-flags')
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(200);
    expect(res.headers['x-request-id']).toBeDefined();
  });
});
