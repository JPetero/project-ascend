import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

/**
 * Build Session 10 Part 6 — private Vision analysis-session history.
 * "Premium" here is a real out-of-band UserSubscription write, the same
 * pattern as promote.e2e-spec.ts/trainer-groups-expanded.e2e-spec.ts —
 * no live billing exists in this environment.
 */
describe('Vision analysis sessions (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let premiumToken: string;
  let freeToken: string;

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

  const sampleSession = (overrides: Record<string, unknown> = {}) => ({
    exercise: 'BODYWEIGHT_SQUAT',
    startedAt: '2026-01-01T00:00:00.000Z',
    completedAt: '2026-01-01T00:05:00.000Z',
    autoRepCount: 8,
    correctedRepCount: 9,
    analysisVersion: 'pose-v1',
    observations: [
      {
        type: 'squat_depth',
        message: 'Your depth appears limited on that rep.',
        severity: 'COACHING_CUE',
        confidence: 0.6,
        occurredAt: '2026-01-01T00:02:00.000Z',
      },
    ],
    ...overrides,
  });

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

    const premium = await register('vision-premium@example.com', 'Vera');
    premiumToken = premium.token;
    await prisma.userSubscription.upsert({
      where: { userId: premium.id },
      update: { tier: 'PREMIUM' },
      create: { userId: premium.id, tier: 'PREMIUM' },
    });

    const free = await register('vision-free@example.com', 'Frankie');
    freeToken = free.token;
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  it('rejects a FREE-tier user from saving a session', async () => {
    await request(app.getHttpServer())
      .post('/vision/analysis-sessions')
      .set('Authorization', `Bearer ${freeToken}`)
      .send(sampleSession())
      .expect(403);
  });

  it('rejects an unauthenticated request', async () => {
    await request(app.getHttpServer())
      .post('/vision/analysis-sessions')
      .send(sampleSession())
      .expect(401);
  });

  it('lets a Premium user save, list, fetch, and delete their own session', async () => {
    const created = await request(app.getHttpServer())
      .post('/vision/analysis-sessions')
      .set('Authorization', `Bearer ${premiumToken}`)
      .send(sampleSession())
      .expect(201);

    expect(created.body.data.exercise).toBe('BODYWEIGHT_SQUAT');
    expect(created.body.data.observations).toHaveLength(1);
    const sessionId = created.body.data.id as string;

    const listed = await request(app.getHttpServer())
      .get('/vision/analysis-sessions')
      .set('Authorization', `Bearer ${premiumToken}`)
      .expect(200);
    expect(listed.body.data.data.some((s: { id: string }) => s.id === sessionId)).toBe(true);

    const fetched = await request(app.getHttpServer())
      .get(`/vision/analysis-sessions/${sessionId}`)
      .set('Authorization', `Bearer ${premiumToken}`)
      .expect(200);
    expect(fetched.body.data.correctedRepCount).toBe(9);

    await request(app.getHttpServer())
      .delete(`/vision/analysis-sessions/${sessionId}`)
      .set('Authorization', `Bearer ${premiumToken}`)
      .expect(204);

    await request(app.getHttpServer())
      .get(`/vision/analysis-sessions/${sessionId}`)
      .set('Authorization', `Bearer ${premiumToken}`)
      .expect(404);
  });

  it("rejects one user reading or deleting another user's session", async () => {
    const created = await request(app.getHttpServer())
      .post('/vision/analysis-sessions')
      .set('Authorization', `Bearer ${premiumToken}`)
      .send(sampleSession())
      .expect(201);
    const sessionId = created.body.data.id as string;

    const intruder = await register('vision-intruder@example.com', 'Ivy');
    await prisma.userSubscription.upsert({
      where: { userId: intruder.id },
      update: { tier: 'PREMIUM' },
      create: { userId: intruder.id, tier: 'PREMIUM' },
    });

    await request(app.getHttpServer())
      .get(`/vision/analysis-sessions/${sessionId}`)
      .set('Authorization', `Bearer ${intruder.token}`)
      .expect(404);

    await request(app.getHttpServer())
      .delete(`/vision/analysis-sessions/${sessionId}`)
      .set('Authorization', `Bearer ${intruder.token}`)
      .expect(404);
  });

  it('rejects an invalid exercise value', async () => {
    await request(app.getHttpServer())
      .post('/vision/analysis-sessions')
      .set('Authorization', `Bearer ${premiumToken}`)
      .send(sampleSession({ exercise: 'DEADLIFT' }))
      .expect(400);
  });
});
