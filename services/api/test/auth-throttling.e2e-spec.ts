import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

/**
 * `AUTH_THROTTLE` (10 requests / 60s) guards /auth/login and friends
 * against credential-guessing, but nothing exercised it end-to-end before
 * this (Build Session 10 Part 30) — every other e2e spec only ever calls
 * these endpoints a handful of times, so a guard that silently stopped
 * being wired up (e.g. a refactor that dropped the `@Throttle` decorator
 * or the global `ThrottlerGuard`) would have nothing to fail.
 */
describe('Auth endpoint rate limiting (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

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

    await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        firstName: 'Ada',
        email: 'throttle-a@example.com',
        password: 'Str0ngPass!',
        confirmPassword: 'Str0ngPass!',
        acceptedTerms: true,
      })
      .expect(201);
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  it('answers the first 10 login attempts within a minute normally, then 429s further attempts', async () => {
    const attempt = () =>
      request(app.getHttpServer())
        .post('/auth/login')
        .send({ email: 'throttle-a@example.com', password: 'WrongPassword!' });

    const statuses: number[] = [];
    for (let i = 0; i < 10; i += 1) {
      const res = await attempt();
      statuses.push(res.status);
    }
    // All within the limit, and all rejected on their own merits (wrong
    // password), not by the throttle — proves the guard isn't blocking
    // legitimate-rate traffic.
    expect(statuses.every((status) => status === 401)).toBe(true);

    const throttled = await attempt();
    expect(throttled.status).toBe(429);
  });

  it('rate limiting is scoped per endpoint, not a single global bucket that blocks unrelated auth requests', async () => {
    // The previous test already exhausted /auth/login's throttle bucket
    // for this process, but /auth/register runs under its own
    // `@Throttle(AUTH_THROTTLE)` scope and must still work.
    const res = await request(app.getHttpServer()).post('/auth/register').send({
      firstName: 'Cid',
      email: 'throttle-c@example.com',
      password: 'Str0ngPass!',
      confirmPassword: 'Str0ngPass!',
      acceptedTerms: true,
    });
    expect(res.status).toBe(201);
  });
});
