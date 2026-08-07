import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

describe('Challenges MVP (e2e)', () => {
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
      return res.body.data.tokens.accessToken as string;
    };

    tokenA = await register('challenge-a@example.com', 'Ada');
    tokenB = await register('challenge-b@example.com', 'Bea');
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  const authA = () => ({ Authorization: `Bearer ${tokenA}` });
  const authB = () => ({ Authorization: `Bearer ${tokenB}` });

  const windowDates = () => {
    const startsAt = new Date();
    startsAt.setUTCHours(0, 0, 0, 0);
    const endsAt = new Date(startsAt.getTime() + 30 * 24 * 60 * 60 * 1000);
    return { startsAt: startsAt.toISOString(), endsAt: endsAt.toISOString() };
  };

  it('rejects an endsAt that is not after startsAt', async () => {
    await request(app.getHttpServer())
      .post('/challenges')
      .set(authA())
      .send({
        title: 'Bad window',
        startsAt: '2026-08-10T00:00:00Z',
        endsAt: '2026-08-01T00:00:00Z',
      })
      .expect(400);
  });

  it('creates a challenge with the creator auto-joined', async () => {
    const { startsAt, endsAt } = windowDates();
    const created = await request(app.getHttpServer())
      .post('/challenges')
      .set(authA())
      .send({ title: 'August step-up', description: '30 active days', startsAt, endsAt })
      .expect(201);

    expect(created.body.data.participantCount).toBe(1);

    const mine = await request(app.getHttpServer()).get('/challenges').set(authA()).expect(200);
    expect(mine.body.data).toHaveLength(1);
  });

  it('appears in the discover list for a non-participant but not for the creator', async () => {
    const discoverForB = await request(app.getHttpServer())
      .get('/challenges/discover')
      .set(authB())
      .expect(200);
    expect(discoverForB.body.data.data).toHaveLength(1);

    const discoverForA = await request(app.getHttpServer())
      .get('/challenges/discover')
      .set(authA())
      .expect(200);
    expect(discoverForA.body.data.data).toHaveLength(0);
  });

  it('hides per-participant progress from a non-participant, and 404s a made-up id', async () => {
    const mine = await request(app.getHttpServer()).get('/challenges').set(authA()).expect(200);
    const challengeId = mine.body.data[0].id as string;

    const asNonParticipant = await request(app.getHttpServer())
      .get(`/challenges/${challengeId}`)
      .set(authB())
      .expect(200);
    expect(asNonParticipant.body.data.isParticipant).toBe(false);
    expect(asNonParticipant.body.data.participants).toBeNull();

    await request(app.getHttpServer())
      .get('/challenges/00000000-0000-0000-0000-000000000000')
      .set(authA())
      .expect(404);
  });

  it('joining shows progress and moves the challenge out of discover into "mine"', async () => {
    const mine = await request(app.getHttpServer()).get('/challenges').set(authA()).expect(200);
    const challengeId = mine.body.data[0].id as string;

    await request(app.getHttpServer())
      .post(`/challenges/${challengeId}/join`)
      .set(authB())
      .expect(204);
    // Joining twice is idempotent, not an error.
    await request(app.getHttpServer())
      .post(`/challenges/${challengeId}/join`)
      .set(authB())
      .expect(204);

    const discoverForB = await request(app.getHttpServer())
      .get('/challenges/discover')
      .set(authB())
      .expect(200);
    expect(discoverForB.body.data.data).toHaveLength(0);

    const detail = await request(app.getHttpServer())
      .get(`/challenges/${challengeId}`)
      .set(authB())
      .expect(200);
    expect(detail.body.data.isParticipant).toBe(true);
    expect(detail.body.data.participants).toHaveLength(2);
    const bProgress = detail.body.data.participants.find((p: { userId: string }) => p.userId);
    expect(bProgress.totalDays).toBeGreaterThanOrEqual(1);
  });

  it('rejects joining a challenge that has already ended', async () => {
    const created = await request(app.getHttpServer())
      .post('/challenges')
      .set(authA())
      .send({
        title: 'Already over',
        startsAt: '2020-01-01T00:00:00Z',
        endsAt: '2020-01-31T00:00:00Z',
      })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/challenges/${created.body.data.id}/join`)
      .set(authB())
      .expect(400);
  });

  it('leaving removes the challenge from "mine"', async () => {
    const mine = await request(app.getHttpServer()).get('/challenges').set(authA()).expect(200);
    const stepUpChallenge = mine.body.data.find(
      (c: { title: string }) => c.title === 'August step-up',
    );

    await request(app.getHttpServer())
      .delete(`/challenges/${stepUpChallenge.id}/leave`)
      .set(authB())
      .expect(204);

    const mineAfter = await request(app.getHttpServer())
      .get('/challenges')
      .set(authB())
      .expect(200);
    expect(mineAfter.body.data.some((c: { id: string }) => c.id === stepUpChallenge.id)).toBe(
      false,
    );
  });

  it('deletes the challenge, and only the creator may delete it', async () => {
    const mine = await request(app.getHttpServer()).get('/challenges').set(authA()).expect(200);
    const stepUpChallenge = mine.body.data.find(
      (c: { title: string }) => c.title === 'August step-up',
    );

    await request(app.getHttpServer())
      .delete(`/challenges/${stepUpChallenge.id}`)
      .set(authB())
      .expect(403);
    await request(app.getHttpServer())
      .delete(`/challenges/${stepUpChallenge.id}`)
      .set(authA())
      .expect(204);
    await request(app.getHttpServer())
      .get(`/challenges/${stepUpChallenge.id}`)
      .set(authA())
      .expect(404);
  });
});
