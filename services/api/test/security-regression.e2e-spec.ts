import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

/**
 * Build Session 12 Part 27-32 — a security regression suite, distinct
 * in purpose from the per-module e2e specs elsewhere in this directory.
 * Those cover module-level correctness (an owner-only 404, a blocked
 * user's profile disappearing, and so on) and already do so thoroughly.
 * This file exists for cross-module *chains*: invariants that only hold
 * because two independently-correct pieces compose correctly together,
 * which is exactly the kind of thing a future, well-intentioned change
 * to either piece in isolation could silently break. Each test below
 * cites the specific fix/session it pins so a failure here points
 * straight at the regression, not just "something broke."
 */
describe('Security regression suite (e2e)', () => {
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
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

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

  it(
    'a lapsed store subscription is downgraded to FREE (Build Session 12 Part 22) in time to be ' +
      "enforced by the very next Premium-gated request — not just reflected in the account's own " +
      'status screen (Build Session 11 Part 1, AI entitlement gate)',
    async () => {
      const { token, id: userId } = await register('regression-lapsed-premium@example.com', 'Lee');

      // A PREMIUM row whose stated period ended yesterday — exactly the
      // "store said it lapsed, nothing has re-verified it yet" gap Part
      // 22 closed by making every capability read reconcile lazily.
      await prisma.userSubscription.upsert({
        where: { userId },
        update: { tier: 'PREMIUM', expiresAt: new Date(Date.now() - 24 * 60 * 60 * 1000) },
        create: {
          userId,
          tier: 'PREMIUM',
          expiresAt: new Date(Date.now() - 24 * 60 * 60 * 1000),
        },
      });

      // If reconciliation didn't run (or a future change made the
      // entitlement gate read a stale/cached tier instead of going
      // through CapabilityService.getPlanTier), this would 503
      // ("not configured") instead of 403 — the same distinction
      // assistant.e2e-spec.ts's entitlement-gate tests use to prove the
      // gate, not the provider, produced the rejection.
      const res = await request(app.getHttpServer())
        .post('/assistant/reply')
        .set('Authorization', `Bearer ${token}`)
        .send({ input: 'plan my workout', companion: 'ATLAS', style: 'BALANCED' })
        .expect(403);
      expect(res.body.error.message).not.toContain('not configured');

      // And the downgrade was persisted, not just applied in-memory for
      // this one request — a second, independent read agrees.
      const status = await request(app.getHttpServer())
        .get('/subscriptions/me')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      expect(status.body.data.tier).toBe('FREE');
    },
  );
});
