import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

/**
 * Build Session 10 Part 16 — real research retrieval pipeline. No
 * BRAVE_SEARCH_API_KEY exists in this environment, so this e2e spec
 * proves the real "not configured" rejection path over actual HTTP, and
 * the real Premium capability gate, rather than exercising a live Brave
 * Search call (covered against a mocked response in
 * brave-search-research-provider.spec.ts). See build-session-10.md.
 */
describe('Research mode (e2e)', () => {
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

    const premium = await register('research-premium@example.com', 'Rae');
    premiumToken = premium.token;
    await prisma.userSubscription.upsert({
      where: { userId: premium.id },
      update: { tier: 'PREMIUM' },
      create: { userId: premium.id, tier: 'PREMIUM' },
    });

    const free = await register('research-free@example.com', 'Fenn');
    freeToken = free.token;
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  it('rejects a FREE-tier user from querying research mode', async () => {
    await request(app.getHttpServer())
      .post('/research/query')
      .set('Authorization', `Bearer ${freeToken}`)
      .send({ query: 'shin splints' })
      .expect(403);
  });

  it('rejects an unauthenticated request', async () => {
    await request(app.getHttpServer())
      .post('/research/query')
      .send({ query: 'shin splints' })
      .expect(401);
  });

  it('rejects a Premium request honestly instead of fabricating a citation, since no key is configured', async () => {
    const res = await request(app.getHttpServer())
      .post('/research/query')
      .set('Authorization', `Bearer ${premiumToken}`)
      .send({ query: 'shin splints' })
      .expect(503);
    expect(res.body.error.message).toContain('not configured');
  });

  it('rejects an empty query', async () => {
    await request(app.getHttpServer())
      .post('/research/query')
      .set('Authorization', `Bearer ${premiumToken}`)
      .send({ query: '' })
      .expect(400);
  });
});
