import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

/**
 * Build Session 9 Part 17/18 — no APPLE_IAP_SHARED_SECRET or
 * GOOGLE_PLAY_SERVICE_ACCOUNT_JSON exists in this environment, so this
 * e2e spec proves the honest, real "not configured" rejection path over
 * actual HTTP rather than exercising a live Apple/Google verification,
 * which is not obtainable here. See build-session-9.md.
 */
describe('Purchases verification — not configured (e2e)', () => {
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
        firstName: 'Grace',
        email: 'purchases-e2e@example.com',
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

  it('rejects an authenticated iOS verification request honestly instead of fabricating success', async () => {
    const res = await request(app.getHttpServer())
      .post('/purchases/verify')
      .set('Authorization', `Bearer ${token}`)
      .send({ platform: 'IOS', productId: 'premium.monthly', receipt: 'base64-receipt-data' })
      .expect(503);
    expect(res.body.error.message).toContain('not configured');
  });

  it('rejects an authenticated Android verification request honestly instead of fabricating success', async () => {
    const res = await request(app.getHttpServer())
      .post('/purchases/verify')
      .set('Authorization', `Bearer ${token}`)
      .send({ platform: 'ANDROID', productId: 'premium.monthly', receipt: 'purchase-token' })
      .expect(503);
    expect(res.body.error.message).toContain('not configured');
  });

  it('rejects an unauthenticated verification request', async () => {
    await request(app.getHttpServer())
      .post('/purchases/verify')
      .send({ platform: 'IOS', productId: 'premium.monthly', receipt: 'base64-receipt-data' })
      .expect(401);
  });

  it('rejects an invalid platform value', async () => {
    await request(app.getHttpServer())
      .post('/purchases/verify')
      .set('Authorization', `Bearer ${token}`)
      .send({ platform: 'WINDOWS_PHONE', productId: 'premium.monthly', receipt: 'x' })
      .expect(400);
  });

  it('leaves the caller on the FREE tier since verification never ran', async () => {
    const res = await request(app.getHttpServer())
      .get('/subscriptions/me')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(res.body.data.tier).toBe('FREE');
  });
});
