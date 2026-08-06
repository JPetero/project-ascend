import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

describe('GPS Cardio (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let tokenA: string;
  let tokenB: string;

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

    const registerA = await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        firstName: 'Cal',
        email: 'cardio-a@example.com',
        password: 'Str0ngPass!',
        confirmPassword: 'Str0ngPass!',
        acceptedTerms: true,
      })
      .expect(201);
    tokenA = registerA.body.data.tokens.accessToken;

    const registerB = await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        firstName: 'Bea',
        email: 'cardio-b@example.com',
        password: 'Str0ngPass!',
        confirmPassword: 'Str0ngPass!',
        acceptedTerms: true,
      })
      .expect(201);
    tokenB = registerB.body.data.tokens.accessToken;
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  const authA = () => ({ Authorization: `Bearer ${tokenA}` });
  const authB = () => ({ Authorization: `Bearer ${tokenB}` });

  it('logs a manual cardio session, defaulting privacy to hidden, and earns first_cardio_session', async () => {
    const created = await request(app.getHttpServer())
      .post('/cardio-sessions')
      .set(authA())
      .send({
        activityType: 'RUN',
        startedAt: '2026-08-06T08:00:00.000Z',
        durationSeconds: 1800,
        distanceMeters: 5000,
        regionLabel: 'Quezon City',
      })
      .expect(201);

    expect(created.body.data.activityType).toBe('RUN');
    expect(created.body.data.hideRoute).toBe(true);
    expect(created.body.data.hideStartLocation).toBe(true);
    expect(created.body.data.hideEndLocation).toBe(true);
    // No distance was fabricated beyond what was entered — the region tag
    // never implies a measured route.
    expect(created.body.data.distanceMeters).toBe(5000);

    const achievements = await request(app.getHttpServer())
      .get('/achievements')
      .set(authA())
      .expect(200);
    const firstCardio = achievements.body.data.find(
      (a: { key: string }) => a.key === 'first_cardio_session',
    );
    expect(firstCardio.earnedAt).not.toBeNull();
  });

  it('rejects reading, editing, or deleting a session owned by another user', async () => {
    const created = await request(app.getHttpServer())
      .post('/cardio-sessions')
      .set(authA())
      .send({
        activityType: 'WALK',
        startedAt: '2026-08-06T09:00:00.000Z',
        durationSeconds: 900,
      })
      .expect(201);
    const sessionId = created.body.data.id;

    await request(app.getHttpServer())
      .get(`/cardio-sessions/${sessionId}`)
      .set(authB())
      .expect(404);
    await request(app.getHttpServer())
      .patch(`/cardio-sessions/${sessionId}`)
      .set(authB())
      .send({ hideRoute: false })
      .expect(404);
    await request(app.getHttpServer())
      .delete(`/cardio-sessions/${sessionId}`)
      .set(authB())
      .expect(404);
  });

  it('lets the owner update only the privacy flags and notes after logging', async () => {
    const created = await request(app.getHttpServer())
      .post('/cardio-sessions')
      .set(authA())
      .send({
        activityType: 'CYCLE',
        startedAt: '2026-08-06T10:00:00.000Z',
        durationSeconds: 3600,
        distanceMeters: 20000,
      })
      .expect(201);
    const sessionId = created.body.data.id;

    const updated = await request(app.getHttpServer())
      .patch(`/cardio-sessions/${sessionId}`)
      .set(authA())
      .send({ hideRoute: false, notes: 'Great tailwind' })
      .expect(200);

    expect(updated.body.data.hideRoute).toBe(false);
    expect(updated.body.data.notes).toBe('Great tailwind');
    // Unchanged from what was originally logged.
    expect(updated.body.data.distanceMeters).toBe(20000);
  });

  it('paginates a user’s cardio history, most recent first, isolated per user', async () => {
    for (const startedAt of [
      '2026-08-01T08:00:00.000Z',
      '2026-08-02T08:00:00.000Z',
      '2026-08-03T08:00:00.000Z',
    ]) {
      await request(app.getHttpServer())
        .post('/cardio-sessions')
        .set(authB())
        .send({ activityType: 'WALK', startedAt, durationSeconds: 600 })
        .expect(201);
    }

    const list = await request(app.getHttpServer())
      .get('/cardio-sessions')
      .query({ page: 1, limit: 2 })
      .set(authB())
      .expect(200);

    expect(list.body.data.data).toHaveLength(2);
    expect(list.body.data.meta.total).toBeGreaterThanOrEqual(3);
    expect(new Date(list.body.data.data[0].startedAt).getTime()).toBeGreaterThan(
      new Date(list.body.data.data[1].startedAt).getTime(),
    );
  });

  it('deletes a cardio session', async () => {
    const created = await request(app.getHttpServer())
      .post('/cardio-sessions')
      .set(authA())
      .send({
        activityType: 'RUN',
        startedAt: '2026-08-06T11:00:00.000Z',
        durationSeconds: 1200,
      })
      .expect(201);

    await request(app.getHttpServer())
      .delete(`/cardio-sessions/${created.body.data.id}`)
      .set(authA())
      .expect(204);

    await request(app.getHttpServer())
      .get(`/cardio-sessions/${created.body.data.id}`)
      .set(authA())
      .expect(404);
  });

  it("surfaces a newly earned achievement in the response meta on a fresh user's first session", async () => {
    const register = await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        firstName: 'Fresh',
        email: 'cardio-fresh@example.com',
        password: 'Str0ngPass!',
        confirmPassword: 'Str0ngPass!',
        acceptedTerms: true,
      })
      .expect(201);
    const freshToken = register.body.data.tokens.accessToken;

    const created = await request(app.getHttpServer())
      .post('/cardio-sessions')
      .set({ Authorization: `Bearer ${freshToken}` })
      .send({
        activityType: 'WALK',
        startedAt: '2026-08-06T09:00:00.000Z',
        durationSeconds: 600,
      })
      .expect(201);

    expect(created.body.meta.newAchievements).toBeDefined();
    expect(
      created.body.meta.newAchievements.some(
        (a: { key: string }) => a.key === 'first_cardio_session',
      ),
    ).toBe(true);
  });
});
