import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

describe('Sports Matches (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let tokenA: string;
  let tokenB: string;
  let tokenC: string;
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

    const a = await register('sports-a@example.com', 'Ada');
    const b = await register('sports-b@example.com', 'Bea');
    const c = await register('sports-c@example.com', 'Cid');
    tokenA = a.token;
    tokenB = b.token;
    tokenC = c.token;
    userIdA = a.id;
    userIdB = b.id;
    userIdC = c.id;
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

  it('lists the seeded Badminton and Table Tennis sports (Build Session 12 Part 23-24)', async () => {
    const res = await request(app.getHttpServer()).get('/sports').set(authA()).expect(200);
    const codes = (res.body.data as Array<{ code: string }>).map((s) => s.code);
    expect(codes).toContain('BADMINTON');
    expect(codes).toContain('TABLE_TENNIS');
  });

  it('rejects challenging yourself', async () => {
    await request(app.getHttpServer())
      .post('/sports/matches')
      .set(authA())
      .send({ sportCode: 'BADMINTON', opponentId: userIdA })
      .expect(400);
  });

  it('runs a full challenge → accept → ready → start → propose → confirm lifecycle and updates ratings', async () => {
    const created = await request(app.getHttpServer())
      .post('/sports/matches')
      .set(authA())
      .send({ sportCode: 'BADMINTON', opponentId: userIdB })
      .expect(201);
    const matchId = created.body.data.id as string;
    expect(created.body.data.status).toBe('INVITED');

    await request(app.getHttpServer())
      .post(`/sports/matches/${matchId}/accept`)
      .set(authB())
      .expect(201);

    await request(app.getHttpServer())
      .post(`/sports/matches/${matchId}/ready`)
      .set(authA())
      .expect(201);
    // Starting before both are ready fails.
    await request(app.getHttpServer())
      .post(`/sports/matches/${matchId}/start`)
      .set(authA())
      .expect(400);
    const bothReady = await request(app.getHttpServer())
      .post(`/sports/matches/${matchId}/ready`)
      .set(authB())
      .expect(201);
    expect(bothReady.body.data.status).toBe('READY');

    const started = await request(app.getHttpServer())
      .post(`/sports/matches/${matchId}/start`)
      .set(authA())
      .expect(201);
    expect(started.body.data.status).toBe('IN_PROGRESS');

    const proposed = await request(app.getHttpServer())
      .post(`/sports/matches/${matchId}/score`)
      .set(authA())
      .send({ proposerScore: 21, opponentScore: 15 })
      .expect(201);
    expect(proposed.body.data.status).toBe('SCORE_PENDING');

    // The proposer cannot confirm their own score.
    await request(app.getHttpServer())
      .post(`/sports/matches/${matchId}/score/confirm`)
      .set(authA())
      .expect(400);

    const confirmed = await request(app.getHttpServer())
      .post(`/sports/matches/${matchId}/score/confirm`)
      .set(authB())
      .expect(201);
    expect(confirmed.body.data.status).toBe('CONFIRMED');

    const winnerRating = await request(app.getHttpServer())
      .get('/sports/BADMINTON/rating')
      .set(authA())
      .expect(200);
    expect(winnerRating.body.data.rating).toBeGreaterThan(1500);
    expect(winnerRating.body.data.matchesPlayed).toBe(1);

    const loserRating = await request(app.getHttpServer())
      .get('/sports/BADMINTON/rating')
      .set(authB())
      .expect(200);
    expect(loserRating.body.data.rating).toBeLessThan(1500);

    const leaderboard = await request(app.getHttpServer())
      .get('/sports/BADMINTON/leaderboard')
      .set(authA())
      .expect(200);
    expect((leaderboard.body.data as unknown[]).length).toBeGreaterThanOrEqual(2);
  });

  it('runs a full Table Tennis lifecycle with a rating tracked independently of Badminton (Build Session 12 Part 23-24)', async () => {
    // A already won a BADMINTON match against B in the previous test, so
    // A's BADMINTON rating is above 1500 — this proves TABLE_TENNIS
    // starts fresh at 1500 rather than sharing that rating.
    const created = await request(app.getHttpServer())
      .post('/sports/matches')
      .set(authA())
      .send({ sportCode: 'TABLE_TENNIS', opponentId: userIdC })
      .expect(201);
    const matchId = created.body.data.id as string;

    await request(app.getHttpServer())
      .post(`/sports/matches/${matchId}/accept`)
      .set(authC())
      .expect(201);
    await request(app.getHttpServer())
      .post(`/sports/matches/${matchId}/ready`)
      .set(authA())
      .expect(201);
    await request(app.getHttpServer())
      .post(`/sports/matches/${matchId}/ready`)
      .set(authC())
      .expect(201);
    await request(app.getHttpServer())
      .post(`/sports/matches/${matchId}/start`)
      .set(authA())
      .expect(201);
    await request(app.getHttpServer())
      .post(`/sports/matches/${matchId}/score`)
      .set(authA())
      .send({ proposerScore: 11, opponentScore: 7 })
      .expect(201);
    const confirmed = await request(app.getHttpServer())
      .post(`/sports/matches/${matchId}/score/confirm`)
      .set(authC())
      .expect(201);
    expect(confirmed.body.data.status).toBe('CONFIRMED');
    expect(confirmed.body.data.sport.code).toBe('TABLE_TENNIS');

    const tableTennisRating = await request(app.getHttpServer())
      .get('/sports/TABLE_TENNIS/rating')
      .set(authA())
      .expect(200);
    expect(tableTennisRating.body.data.matchesPlayed).toBe(1);
    expect(tableTennisRating.body.data.rating).toBeGreaterThan(1500);

    const badmintonRating = await request(app.getHttpServer())
      .get('/sports/BADMINTON/rating')
      .set(authA())
      .expect(200);
    // Unaffected by the Table Tennis match — still exactly the single
    // Badminton match's worth of rating movement from the earlier test.
    expect(badmintonRating.body.data.matchesPlayed).toBe(1);
  });

  it('raises a dispute on disagreement and allows voiding it', async () => {
    const created = await request(app.getHttpServer())
      .post('/sports/matches')
      .set(authA())
      .send({ sportCode: 'BADMINTON', opponentId: userIdC })
      .expect(201);
    const matchId = created.body.data.id as string;

    await request(app.getHttpServer())
      .post(`/sports/matches/${matchId}/accept`)
      .set(authC())
      .expect(201);
    await request(app.getHttpServer())
      .post(`/sports/matches/${matchId}/ready`)
      .set(authA())
      .expect(201);
    await request(app.getHttpServer())
      .post(`/sports/matches/${matchId}/ready`)
      .set(authC())
      .expect(201);
    await request(app.getHttpServer())
      .post(`/sports/matches/${matchId}/start`)
      .set(authA())
      .expect(201);
    await request(app.getHttpServer())
      .post(`/sports/matches/${matchId}/score`)
      .set(authA())
      .send({ proposerScore: 21, opponentScore: 10 })
      .expect(201);

    const disputed = await request(app.getHttpServer())
      .post(`/sports/matches/${matchId}/score/dispute`)
      .set(authC())
      .send({ reason: "That's not what happened." })
      .expect(201);
    expect(disputed.body.data.status).toBe('DISPUTED');

    const voided = await request(app.getHttpServer())
      .post(`/sports/matches/${matchId}/void`)
      .set(authC())
      .expect(201);
    expect(voided.body.data.status).toBe('VOID');
  });

  it('declining a challenge cancels the match', async () => {
    const created = await request(app.getHttpServer())
      .post('/sports/matches')
      .set(authA())
      .send({ sportCode: 'BADMINTON', opponentId: userIdB })
      .expect(201);
    const matchId = created.body.data.id as string;

    const declined = await request(app.getHttpServer())
      .post(`/sports/matches/${matchId}/decline`)
      .set(authB())
      .expect(201);
    expect(declined.body.data.status).toBe('CANCELED');
  });

  it('404s a real match id for a non-participant', async () => {
    const created = await request(app.getHttpServer())
      .post('/sports/matches')
      .set(authA())
      .send({ sportCode: 'BADMINTON', opponentId: userIdB })
      .expect(201);

    await request(app.getHttpServer())
      .get(`/sports/matches/${created.body.data.id}`)
      .set(authC())
      .expect(404);
  });
});
