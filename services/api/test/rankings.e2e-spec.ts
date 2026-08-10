import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

describe('Rankings seasons MVP (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let tokenA: string;
  let tokenB: string;
  let userIdA: string;
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

    const [a, b, c] = await Promise.all([
      register('rank-a@example.com', 'Ada'),
      register('rank-b@example.com', 'Bea'),
      register('rank-c@example.com', 'Cid'),
    ]);
    tokenA = a.token;
    tokenB = b.token;
    userIdA = a.id;
    userIdB = b.id;
    userIdC = c.id;
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  const authA = () => ({ Authorization: `Bearer ${tokenA}` });
  const authB = () => ({ Authorization: `Bearer ${tokenB}` });

  it('reports opted out by default, off by default per Scenario 16a', async () => {
    const status = await request(app.getHttpServer()).get('/rankings/me').set(authA()).expect(200);

    expect(status.body.data.optedIn).toBe(false);
  });

  it('rejects viewing any leaderboard before opting in', async () => {
    await request(app.getHttpServer())
      .get('/rankings/leaderboard')
      .query({ scope: 'GLOBAL' })
      .set(authA())
      .expect(403);
  });

  it('requires a locality chain when opting in with REGION scope', async () => {
    await request(app.getHttpServer())
      .put('/rankings/opt-in')
      .set(authA())
      .send({ scope: 'REGION' })
      .expect(400);

    // Country alone is not enough for REGION — the whole chain up to
    // and including the requested tier is required.
    await request(app.getHttpServer())
      .put('/rankings/opt-in')
      .set(authA())
      .send({ scope: 'REGION', localityCountry: 'Philippines' })
      .expect(400);
  });

  it('opts in with GLOBAL scope, and /me reflects it with a season and score', async () => {
    await request(app.getHttpServer())
      .put('/rankings/opt-in')
      .set(authA())
      .send({ scope: 'GLOBAL' })
      .expect(200);

    const status = await request(app.getHttpServer()).get('/rankings/me').set(authA()).expect(200);
    expect(status.body.data.optedIn).toBe(true);
    expect(status.body.data.scope).toBe('GLOBAL');
    expect(status.body.data.season).toBeDefined();
    expect(status.body.data.points).toBe(0);
  });

  it('a real logged cardio session today contributes exactly one activity-day point', async () => {
    await request(app.getHttpServer())
      .post('/cardio-sessions')
      .set(authA())
      .send({
        activityType: 'RUN',
        startedAt: new Date().toISOString(),
        durationSeconds: 1800,
      })
      .expect(201);

    const status = await request(app.getHttpServer()).get('/rankings/me').set(authA()).expect(200);
    expect(status.body.data.points).toBe(1);
    expect(status.body.data.activeDays).toBe(1);
  });

  it('the GLOBAL leaderboard lists opted-in users only, and never an exact coordinate', async () => {
    await request(app.getHttpServer())
      .put('/rankings/opt-in')
      .set(authB())
      .send({ scope: 'GLOBAL' })
      .expect(200);

    const leaderboard = await request(app.getHttpServer())
      .get('/rankings/leaderboard')
      .query({ scope: 'GLOBAL' })
      .set(authA())
      .expect(200);

    const userIds = leaderboard.body.data.data.map((e: { userId: string }) => e.userId);
    expect(userIds).toEqual(expect.arrayContaining([userIdA, userIdB]));
    // C never opted in, so C must never appear on any leaderboard.
    expect(userIds).not.toContain(userIdC);
    const raw = JSON.stringify(leaderboard.body);
    expect(raw).not.toMatch(/lat|lng|latitude|longitude/i);
  });

  it('rejects REGION requests from a viewer opted in at a broader (non-locality) scope', async () => {
    await request(app.getHttpServer())
      .get('/rankings/leaderboard')
      .query({ scope: 'REGION' })
      .set(authA())
      .expect(400);
  });

  it('opts A into LOCAL with the full locality chain, and /me reflects every tier', async () => {
    await request(app.getHttpServer())
      .put('/rankings/opt-in')
      .set(authA())
      .send({
        scope: 'LOCAL',
        localityCountry: 'Philippines',
        localityRegion: 'Metro Manila',
        localityCity: 'Quezon City',
        localityArea: 'Diliman',
      })
      .expect(200);

    const status = await request(app.getHttpServer()).get('/rankings/me').set(authA()).expect(200);
    expect(status.body.data.scope).toBe('LOCAL');
    expect(status.body.data.localityCountry).toBe('Philippines');
    expect(status.body.data.localityRegion).toBe('Metro Manila');
    expect(status.body.data.localityCity).toBe('Quezon City');
    expect(status.body.data.localityArea).toBe('Diliman');
  });

  it('a LOCAL opt-in can also view the broader CITY leaderboard, matching case-insensitively', async () => {
    await request(app.getHttpServer())
      .put('/rankings/opt-in')
      .set(authB())
      .send({
        scope: 'CITY',
        localityCountry: 'philippines',
        localityRegion: 'metro manila',
        localityCity: 'quezon city',
      })
      .expect(200);

    const leaderboard = await request(app.getHttpServer())
      .get('/rankings/leaderboard')
      .query({ scope: 'CITY' })
      .set(authA())
      .expect(200);

    const userIds = leaderboard.body.data.data.map((e: { userId: string }) => e.userId);
    expect(userIds).toContain(userIdB);
    // A opted in at LOCAL, not CITY, so A's own row is not a CITY entry.
    expect(userIds).not.toContain(userIdA);
  });

  it('rejects viewing a narrower locality tier than the viewer opted into', async () => {
    // B is opted in at CITY; LOCAL is narrower than CITY.
    await request(app.getHttpServer())
      .get('/rankings/leaderboard')
      .query({ scope: 'LOCAL' })
      .set(authB())
      .expect(400);
  });

  it('a REGION leaderboard for a different place never includes a user opted in elsewhere', async () => {
    await request(app.getHttpServer())
      .put('/rankings/opt-in')
      .set(authA())
      .send({ scope: 'REGION', localityCountry: 'Philippines', localityRegion: 'Cebu' })
      .expect(200);

    const leaderboard = await request(app.getHttpServer())
      .get('/rankings/leaderboard')
      .query({ scope: 'REGION' })
      .set(authA())
      .expect(200);

    const userIds = leaderboard.body.data.data.map((e: { userId: string }) => e.userId);
    expect(userIds).toContain(userIdA);
    expect(userIds).not.toContain(userIdB);
    const raw = JSON.stringify(leaderboard.body);
    expect(raw).not.toMatch(/lat|lng|latitude|longitude/i);
  });

  it('the FRIENDS leaderboard only includes people the viewer follows who also opted in', async () => {
    await request(app.getHttpServer())
      .post(`/community/follow/${userIdB}`)
      .set(authA())
      .expect(204);

    const leaderboard = await request(app.getHttpServer())
      .get('/rankings/leaderboard')
      .query({ scope: 'FRIENDS' })
      .set(authA())
      .expect(200);

    const userIds = leaderboard.body.data.data.map((e: { userId: string }) => e.userId);
    expect(userIds).toEqual(expect.arrayContaining([userIdA, userIdB]));
  });

  it('opting out removes access to the leaderboard again', async () => {
    await request(app.getHttpServer()).delete('/rankings/opt-in').set(authA()).expect(204);

    const status = await request(app.getHttpServer()).get('/rankings/me').set(authA()).expect(200);
    expect(status.body.data.optedIn).toBe(false);

    await request(app.getHttpServer())
      .get('/rankings/leaderboard')
      .query({ scope: 'GLOBAL' })
      .set(authA())
      .expect(403);
  });
});
