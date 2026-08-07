import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

describe('Joint Workout Sessions (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let tokenA: string;
  let tokenB: string;
  let tokenC: string;
  let userIdB: string;
  let userIdC: string;

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

    const a = await register('joint-a@example.com', 'Ada');
    const b = await register('joint-b@example.com', 'Bea');
    const c = await register('joint-c@example.com', 'Cid');
    tokenA = a.token;
    tokenB = b.token;
    tokenC = c.token;
    userIdB = b.id;
    userIdC = c.id;

    // Make Ada and Bea friends; Cid stays a stranger to Ada.
    const sent = await request(app.getHttpServer())
      .post('/friends/requests')
      .set(authFor(tokenA))
      .send({ recipientId: userIdB })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/friends/requests/${sent.body.data.id}/accept`)
      .set(authFor(tokenB))
      .expect(201);
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  function authFor(token: string) {
    return { Authorization: `Bearer ${token}` };
  }
  const authA = () => authFor(tokenA);
  const authB = () => authFor(tokenB);
  const authC = () => authFor(tokenC);

  it('rejects inviting someone who is not a friend', async () => {
    const created = await request(app.getHttpServer())
      .post('/joint-workouts')
      .set(authA())
      .send({ title: 'Leg day' })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/joint-workouts/${created.body.data.id}/invite`)
      .set(authA())
      .send({ inviteeId: userIdC })
      .expect(404);
  });

  it('runs a full invite → accept → ready → start → progress → finish lifecycle', async () => {
    const created = await request(app.getHttpServer())
      .post('/joint-workouts')
      .set(authA())
      .send({ title: 'Push day', inviteeIds: [userIdB] })
      .expect(201);
    const sessionId = created.body.data.id as string;
    expect(created.body.data.status).toBe('CREATED');

    // Bea accepts and both mark ready.
    await request(app.getHttpServer())
      .post(`/joint-workouts/${sessionId}/accept`)
      .set(authB())
      .expect(201);
    await request(app.getHttpServer())
      .post(`/joint-workouts/${sessionId}/ready`)
      .set(authA())
      .expect(201);

    // Starting before Bea is ready fails.
    await request(app.getHttpServer())
      .post(`/joint-workouts/${sessionId}/start`)
      .set(authA())
      .expect(400);

    await request(app.getHttpServer())
      .post(`/joint-workouts/${sessionId}/ready`)
      .set(authB())
      .expect(201);

    const started = await request(app.getHttpServer())
      .post(`/joint-workouts/${sessionId}/start`)
      .set(authA())
      .expect(201);
    expect(started.body.data.status).toBe('IN_PROGRESS');

    await request(app.getHttpServer())
      .post(`/joint-workouts/${sessionId}/progress`)
      .set(authB())
      .send({ exerciseName: 'Bench Press', setsCompleted: 3, isPersonalRecord: true })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/joint-workouts/${sessionId}/finish`)
      .set(authB())
      .expect(201);

    const midway = await request(app.getHttpServer())
      .get(`/joint-workouts/${sessionId}`)
      .set(authA())
      .expect(200);
    expect(midway.body.data.status).toBe('IN_PROGRESS');

    const finished = await request(app.getHttpServer())
      .post(`/joint-workouts/${sessionId}/finish`)
      .set(authA())
      .expect(201);
    expect(finished.body.data.status).toBe('FINISHED');

    const detail = await request(app.getHttpServer())
      .get(`/joint-workouts/${sessionId}`)
      .set(authB())
      .expect(200);
    const bea = (
      detail.body.data.participants as Array<{ userId: string; results: unknown[] }>
    ).find((p) => p.userId === userIdB)!;
    expect(bea.results).toHaveLength(1);

    // A stranger cannot read the session at all.
    await request(app.getHttpServer()).get(`/joint-workouts/${sessionId}`).set(authC()).expect(404);
  });

  it('cancels the session for everyone when the host leaves', async () => {
    const created = await request(app.getHttpServer())
      .post('/joint-workouts')
      .set(authA())
      .send({ title: 'Cardio', inviteeIds: [userIdB] })
      .expect(201);
    const sessionId = created.body.data.id as string;

    await request(app.getHttpServer())
      .post(`/joint-workouts/${sessionId}/leave`)
      .set(authA())
      .expect(201);

    const detail = await request(app.getHttpServer())
      .get(`/joint-workouts/${sessionId}`)
      .set(authB())
      .expect(200);
    expect(detail.body.data.status).toBe('CANCELED');
  });

  it('lets the host cancel a session outright', async () => {
    const created = await request(app.getHttpServer())
      .post('/joint-workouts')
      .set(authA())
      .send({ title: 'Mobility' })
      .expect(201);
    const sessionId = created.body.data.id as string;

    await request(app.getHttpServer())
      .post(`/joint-workouts/${sessionId}/cancel`)
      .set(authA())
      .expect(201);

    await request(app.getHttpServer())
      .post(`/joint-workouts/${sessionId}/cancel`)
      .set(authA())
      .expect(400);
  });

  it('lists sessions the caller participates in', async () => {
    const list = await request(app.getHttpServer()).get('/joint-workouts').set(authA()).expect(200);
    expect(Array.isArray(list.body.data)).toBe(true);
    expect((list.body.data as unknown[]).length).toBeGreaterThan(0);
  });
});
