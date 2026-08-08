import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import {
  TRAINER_GROUP_MEMBER_LIMIT_FREE,
  TRAINER_GROUP_MEMBER_LIMIT_PREMIUM,
} from '../src/common/policy/trainer-group-policy';
import { ApplePurchaseVerifier } from '../src/modules/purchases/verifiers/apple-purchase-verifier';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

/**
 * Build Session 9 Part 22/23 — every prior spec either exercises
 * PurchasesService against real Apple/Google servers (impossible without
 * live credentials, see purchases.e2e-spec.ts) or sets `UserSubscription`
 * directly in the database and tests a single downstream module in
 * isolation (e.g. trainer-groups-expanded.e2e-spec.ts). Nothing proves the
 * actual seam: that a real verified purchase, flowing through the real
 * `POST /purchases/verify` HTTP endpoint and the real `PurchasesService`,
 * actually cascades through `CapabilityService` into a real Premium-gated
 * feature in a completely different module. This spec substitutes a fake
 * `ApplePurchaseVerifier` (the only unconfigured piece — a live receipt
 * check) via Nest's DI override, so every other layer in the chain is the
 * real, unmocked production code.
 */
describe('Purchase → Premium entitlement cascade (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

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
    })
      .overrideProvider(ApplePurchaseVerifier)
      .useValue({
        isConfigured: true,
        verify: async (receipt: string) => ({ transactionId: `fake-txn-${receipt}` }),
      })
      .compile();

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

  it('a verified purchase flips the caller to PREMIUM and unlocks Trainer Groups expanded limits', async () => {
    const owner = await register('cascade-owner@example.com', 'Cass');

    // Before purchasing: FREE tier, FREE trainer-group member limit.
    const beforeStatus = await request(app.getHttpServer())
      .get('/subscriptions/me')
      .set('Authorization', `Bearer ${owner.token}`)
      .expect(200);
    expect(beforeStatus.body.data.tier).toBe('FREE');

    const beforeGroup = await request(app.getHttpServer())
      .post('/trainer-groups')
      .set('Authorization', `Bearer ${owner.token}`)
      .send({ name: "Cass's Free Group" })
      .expect(201);
    expect(beforeGroup.body.data.isExpanded).toBe(false);
    expect(beforeGroup.body.data.memberLimit).toBe(TRAINER_GROUP_MEMBER_LIMIT_FREE);

    // Complete a real purchase-verification round-trip against the fake
    // (but DI-substituted, not stubbed-out) Apple verifier.
    const verifyRes = await request(app.getHttpServer())
      .post('/purchases/verify')
      .set('Authorization', `Bearer ${owner.token}`)
      .send({ platform: 'IOS', productId: 'premium.monthly', receipt: 'cascade-receipt-1' })
      .expect(201);
    expect(verifyRes.body.data.tier).toBe('PREMIUM');

    // The purchase alone must not retroactively expand the group created
    // before it — expansion is read fresh from the owner's live tier.
    const afterStatus = await request(app.getHttpServer())
      .get('/subscriptions/me')
      .set('Authorization', `Bearer ${owner.token}`)
      .expect(200);
    expect(afterStatus.body.data.tier).toBe('PREMIUM');

    const existingGroup = await request(app.getHttpServer())
      .get(`/trainer-groups/${beforeGroup.body.data.id}`)
      .set('Authorization', `Bearer ${owner.token}`)
      .expect(200);
    expect(existingGroup.body.data.isExpanded).toBe(true);
    expect(existingGroup.body.data.memberLimit).toBe(TRAINER_GROUP_MEMBER_LIMIT_PREMIUM);

    // A newly created group also reports the expanded tier immediately.
    const afterGroup = await request(app.getHttpServer())
      .post('/trainer-groups')
      .set('Authorization', `Bearer ${owner.token}`)
      .send({ name: "Cass's Premium Group" })
      .expect(201);
    expect(afterGroup.body.data.isExpanded).toBe(true);
    expect(afterGroup.body.data.memberLimit).toBe(TRAINER_GROUP_MEMBER_LIMIT_PREMIUM);
  });

  it('rejects a second account redeeming the same platform transaction id', async () => {
    const first = await register('cascade-first@example.com', 'Finn');
    const second = await register('cascade-second@example.com', 'Sam');

    await request(app.getHttpServer())
      .post('/purchases/verify')
      .set('Authorization', `Bearer ${first.token}`)
      .send({ platform: 'IOS', productId: 'premium.monthly', receipt: 'shared-receipt' })
      .expect(201);

    const conflict = await request(app.getHttpServer())
      .post('/purchases/verify')
      .set('Authorization', `Bearer ${second.token}`)
      .send({ platform: 'IOS', productId: 'premium.monthly', receipt: 'shared-receipt' })
      .expect(409);
    expect(conflict.body.error.message).toContain('already been redeemed');

    const secondStatus = await request(app.getHttpServer())
      .get('/subscriptions/me')
      .set('Authorization', `Bearer ${second.token}`)
      .expect(200);
    expect(secondStatus.body.data.tier).toBe('FREE');
  });
});
