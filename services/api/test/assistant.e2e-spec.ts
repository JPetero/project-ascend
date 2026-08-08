import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

/**
 * Build Session 9 Part 15/16 — no ANTHROPIC_API_KEY exists in this
 * environment, so this e2e spec proves the honest, real "not configured"
 * rejection path over actual HTTP rather than exercising a live
 * Anthropic call, which is not obtainable here. See build-session-9.md.
 */
describe('Assistant live reply — not configured (e2e)', () => {
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
        email: 'assistant-e2e@example.com',
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

  it('rejects an authenticated reply request honestly instead of fabricating a reply', async () => {
    const res = await request(app.getHttpServer())
      .post('/assistant/reply')
      .set('Authorization', `Bearer ${token}`)
      .send({ input: 'plan my workout', companion: 'ATLAS', style: 'BALANCED' })
      .expect(503);
    expect(res.body.error.message).toContain('not configured');
  });

  it('rejects an unauthenticated reply request', async () => {
    await request(app.getHttpServer())
      .post('/assistant/reply')
      .send({ input: 'plan my workout', companion: 'ATLAS', style: 'BALANCED' })
      .expect(401);
  });

  it('rejects an invalid companion/style value', async () => {
    await request(app.getHttpServer())
      .post('/assistant/reply')
      .set('Authorization', `Bearer ${token}`)
      .send({ input: 'plan my workout', companion: 'ZEUS', style: 'BALANCED' })
      .expect(400);
  });
});
