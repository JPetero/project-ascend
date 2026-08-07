import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

/**
 * Build Session 9 Part 8 — no GOOGLE_OAUTH_CLIENT_ID/APPLE_CLIENT_ID
 * exists in this environment (no Google Cloud project or Apple
 * Developer account was created this session), so this e2e spec proves
 * the honest, real "not configured" rejection path over actual HTTP
 * rather than exercising a live Google/Apple-issued token, which is
 * not obtainable here. See build-session-9.md.
 */
describe('Google/Apple sign-in — not configured (e2e)', () => {
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
        firstName: 'Ada',
        email: 'social-auth@example.com',
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

  it('rejects Google sign-in honestly instead of pretending to verify', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/google')
      .send({ idToken: 'whatever' })
      .expect(401);
    expect(res.body.error.message).toContain('not configured');
  });

  it('rejects Apple sign-in honestly instead of pretending to verify', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/apple')
      .send({ idToken: 'whatever' })
      .expect(401);
    expect(res.body.error.message).toContain('not configured');
  });

  it('rejects linking a Google identity honestly instead of pretending to verify', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth-identities/link')
      .set('Authorization', `Bearer ${token}`)
      .send({ provider: 'GOOGLE', idToken: 'whatever' })
      .expect(401);
    expect(res.body.error.message).toContain('not configured');
  });

  it('rejects linking an Apple identity honestly instead of pretending to verify', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth-identities/link')
      .set('Authorization', `Bearer ${token}`)
      .send({ provider: 'APPLE', idToken: 'whatever' })
      .expect(401);
    expect(res.body.error.message).toContain('not configured');
  });
});
