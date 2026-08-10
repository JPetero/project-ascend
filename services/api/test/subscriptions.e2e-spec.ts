import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

describe('Subscriptions and affordability foundation (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let token: string;

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

    const res = await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        firstName: 'Sam',
        email: 'subscriptions@example.com',
        password: 'Str0ngPass!',
        confirmPassword: 'Str0ngPass!',
        acceptedTerms: true,
      })
      .expect(201);
    token = res.body.data.tokens.accessToken as string;
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  const auth = () => ({ Authorization: `Bearer ${token}` });

  it('returns centralized USD and PHP pricing, each with a lower eligible amount', async () => {
    const res = await request(app.getHttpServer())
      .get('/subscriptions/pricing')
      .set(auth())
      .expect(200);

    const points = res.body.data as {
      currency: string;
      standardAmount: number;
      eligibleAmount: number;
    }[];
    const usd = points.find((p) => p.currency === 'USD')!;
    expect(usd).toBeDefined();
    expect(usd.eligibleAmount).toBeLessThan(usd.standardAmount);
    const php = points.find((p) => p.currency === 'PHP')!;
    expect(php).toBeDefined();
    expect(php.eligibleAmount).toBeLessThan(php.standardAmount);
  });

  it('defaults to FREE with no eligibility application, and no expiresAt/willRenew', async () => {
    const res = await request(app.getHttpServer()).get('/subscriptions/me').set(auth()).expect(200);

    expect(res.body.data).toEqual({
      tier: 'FREE',
      expiresAt: null,
      willRenew: null,
      eligibility: null,
    });
  });

  it(
    "surfaces the store's stated expiration and auto-renew intent for a real " +
      'PREMIUM subscription (Build Session 10 Part 26)',
    async () => {
      const premium = await request(app.getHttpServer())
        .post('/auth/register')
        .send({
          firstName: 'Pia',
          email: 'subscriptions-premium@example.com',
          password: 'Str0ngPass!',
          confirmPassword: 'Str0ngPass!',
          acceptedTerms: true,
        })
        .expect(201);
      const premiumToken = premium.body.data.tokens.accessToken as string;
      const premiumUserId = premium.body.data.user.id as string;
      const expiresAt = new Date('2026-09-09T00:00:00.000Z');

      await prisma.userSubscription.upsert({
        where: { userId: premiumUserId },
        update: { tier: 'PREMIUM', expiresAt, willRenew: true },
        create: { userId: premiumUserId, tier: 'PREMIUM', expiresAt, willRenew: true },
      });

      const res = await request(app.getHttpServer())
        .get('/subscriptions/me')
        .set({ Authorization: `Bearer ${premiumToken}` })
        .expect(200);

      expect(res.body.data.tier).toBe('PREMIUM');
      expect(new Date(res.body.data.expiresAt as string)).toEqual(expiresAt);
      expect(res.body.data.willRenew).toBe(true);
    },
  );

  it('purchase reconciliation (Build Session 12 Part 22) — a PREMIUM row past its store expiresAt reads and persists as FREE', async () => {
    const lapsed = await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        firstName: 'Lex',
        email: 'subscriptions-lapsed@example.com',
        password: 'Str0ngPass!',
        confirmPassword: 'Str0ngPass!',
        acceptedTerms: true,
      })
      .expect(201);
    const lapsedToken = lapsed.body.data.tokens.accessToken as string;
    const lapsedUserId = lapsed.body.data.user.id as string;
    const pastExpiresAt = new Date(Date.now() - 24 * 60 * 60 * 1000);

    await prisma.userSubscription.upsert({
      where: { userId: lapsedUserId },
      update: { tier: 'PREMIUM', expiresAt: pastExpiresAt, willRenew: false },
      create: {
        userId: lapsedUserId,
        tier: 'PREMIUM',
        expiresAt: pastExpiresAt,
        willRenew: false,
      },
    });

    const res = await request(app.getHttpServer())
      .get('/subscriptions/me')
      .set({ Authorization: `Bearer ${lapsedToken}` })
      .expect(200);
    expect(res.body.data.tier).toBe('FREE');

    // Not just the derived read — the row itself was downgraded, so a
    // raw DB read agrees too (no cron needed; see CapabilityService.getPlanTier).
    const row = await prisma.userSubscription.findUnique({ where: { userId: lapsedUserId } });
    expect(row?.tier).toBe('FREE');
  });

  it('records an affordability application and reflects it on /me', async () => {
    const applied = await request(app.getHttpServer())
      .post('/subscriptions/eligibility')
      .set(auth())
      .send({ program: 'STUDENT', notes: 'Enrolled full-time' })
      .expect(201);
    expect(applied.body.data).toEqual({ program: 'STUDENT', status: 'PENDING' });

    const status = await request(app.getHttpServer())
      .get('/subscriptions/me')
      .set(auth())
      .expect(200);
    expect(status.body.data.eligibility).toEqual({ program: 'STUDENT', status: 'PENDING' });

    const eligibility = await request(app.getHttpServer())
      .get('/subscriptions/eligibility')
      .set(auth())
      .expect(200);
    expect(eligibility.body.data).toEqual({ program: 'STUDENT', status: 'PENDING' });
  });

  it('re-applying with a different program replaces the pending application', async () => {
    await request(app.getHttpServer())
      .post('/subscriptions/eligibility')
      .set(auth())
      .send({ program: 'ACCESSIBILITY' })
      .expect(201);

    const eligibility = await request(app.getHttpServer())
      .get('/subscriptions/eligibility')
      .set(auth())
      .expect(200);
    expect(eligibility.body.data).toEqual({ program: 'ACCESSIBILITY', status: 'PENDING' });
  });

  it('rejects an unauthenticated request', async () => {
    await request(app.getHttpServer()).get('/subscriptions/me').expect(401);
  });
});
