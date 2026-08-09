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

    await prisma.userSubscription.upsert({
      where: { userId: res.body.data.user.id },
      update: { tier: 'PREMIUM' },
      create: { userId: res.body.data.user.id, tier: 'PREMIUM' },
    });
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  it('rejects a Premium reply request honestly instead of fabricating a reply', async () => {
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

/**
 * Build Session 11 Parts 1-2 — server-side AI entitlement enforcement +
 * safety gate. Before this, `POST /assistant/reply` had no entitlement
 * check at all (any authenticated account, Free or Premium, reached the
 * live-provider code path) and no safety classification of its own (the
 * only gate was the Flutter client, entirely bypassable with a direct
 * HTTP call). These tests hit the real endpoint directly — the way a
 * scripted bypass attempt would — to prove both gates are actually
 * enforced server-side, not just present in the client.
 */
describe('Assistant entitlement + safety gate (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let freeToken: string;
  let premiumToken: string;

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

    const free = await register('assistant-gate-free@example.com', 'Fenn');
    freeToken = free.token;

    const premium = await register('assistant-gate-premium@example.com', 'Rae');
    premiumToken = premium.token;
    await prisma.userSubscription.upsert({
      where: { userId: premium.id },
      update: { tier: 'PREMIUM' },
      create: { userId: premium.id, tier: 'PREMIUM' },
    });
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  it('rejects a Free account calling the live-provider path directly with 403, never reaching the (unconfigured) provider', async () => {
    const res = await request(app.getHttpServer())
      .post('/assistant/reply')
      .set('Authorization', `Bearer ${freeToken}`)
      .send({ input: 'plan my workout', companion: 'ATLAS', style: 'BALANCED' })
      .expect(403);
    // Not the provider's "not configured" 503 — the entitlement gate
    // rejected this before the provider was ever consulted.
    expect(res.body.error.message).not.toContain('not configured');
  });

  it('a Premium account passes the entitlement gate and reaches the (unconfigured) provider instead', async () => {
    const res = await request(app.getHttpServer())
      .post('/assistant/reply')
      .set('Authorization', `Bearer ${premiumToken}`)
      .send({ input: 'plan my workout', companion: 'ATLAS', style: 'BALANCED' })
      .expect(503);
    expect(res.body.error.message).toContain('not configured');
  });

  it('a medical red-flag message gets a real deterministic reply for a Free account, even though no provider is configured — essential safety is never blocked by subscription or provider availability', async () => {
    const res = await request(app.getHttpServer())
      .post('/assistant/reply')
      .set('Authorization', `Bearer ${freeToken}`)
      .send({ input: 'I have chest pain after my workout', companion: 'ATLAS', style: 'BALANCED' })
      .expect(201);
    expect(res.body.data.reply).toContain('seek medical attention');
  });

  it('an eating-disorder-risk message gets the same safe deterministic reply for a Premium account too — the safety gate applies to every tier identically', async () => {
    const res = await request(app.getHttpServer())
      .post('/assistant/reply')
      .set('Authorization', `Bearer ${premiumToken}`)
      .send({ input: 'How do I purge after eating?', companion: 'NOVA', style: 'GENTLE' })
      .expect(201);
    expect(res.body.data.reply).toBeDefined();
    expect(res.body.data.reply).not.toContain('not configured');
  });
});

/**
 * Build Session 10 Part 15 — real Atlas/Nova memory. This only covers
 * the memory endpoints themselves (empty by default, real clear);
 * "a reply gets remembered" can't be exercised over real HTTP in this
 * environment since AssistantService only calls
 * CompanionMemoryService.remember() after a successful reply, and no
 * live ANTHROPIC_API_KEY exists here — see
 * companion-memory.service.spec.ts and assistant.service.spec.ts for
 * that behavior against a mocked provider.
 */
describe('Assistant memory (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let token: string;
  let userId: string;

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
        firstName: 'Mia',
        email: 'assistant-memory-e2e@example.com',
        password: 'Str0ngPass!',
        confirmPassword: 'Str0ngPass!',
        acceptedTerms: true,
      })
      .expect(201);
    token = res.body.data.tokens.accessToken as string;
    userId = res.body.data.user.id as string;
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  it('reports no remembered notes for a fresh account', async () => {
    const res = await request(app.getHttpServer())
      .get('/assistant/memory')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(res.body.data.notes).toEqual([]);
  });

  it('rejects an unauthenticated request to read memory', async () => {
    await request(app.getHttpServer()).get('/assistant/memory').expect(401);
  });

  it('clearing memory is real and idempotent, even with nothing to clear', async () => {
    await request(app.getHttpServer())
      .delete('/assistant/memory')
      .set('Authorization', `Bearer ${token}`)
      .expect(204);
    await request(app.getHttpServer())
      .delete('/assistant/memory')
      .set('Authorization', `Bearer ${token}`)
      .expect(204);
  });

  it('rejects an unauthenticated request to clear memory', async () => {
    await request(app.getHttpServer()).delete('/assistant/memory').expect(401);
  });

  // Build Session 11 Part 4 — memory is now structured (category/value/
  // createdAt per fact, one row per fact) instead of a raw string list.
  it('lists a structured note with its category and creation date, and deleting it removes only that one', async () => {
    const created = await prisma.companionMemoryNote.create({
      data: { userId: userId, category: 'GOAL', value: 'Goal: build strength.' },
    });
    const other = await prisma.companionMemoryNote.create({
      data: { userId: userId, category: 'EQUIPMENT', value: 'Has access to: dumbbells.' },
    });

    const listed = await request(app.getHttpServer())
      .get('/assistant/memory')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(listed.body.data.notes).toHaveLength(2);
    const first = listed.body.data.notes.find((n: { id: string }) => n.id === created.id);
    expect(first).toMatchObject({ category: 'GOAL', value: 'Goal: build strength.' });
    expect(first.createdAt).toBeDefined();

    await request(app.getHttpServer())
      .delete(`/assistant/memory/${created.id}`)
      .set('Authorization', `Bearer ${token}`)
      .expect(204);

    const afterDelete = await request(app.getHttpServer())
      .get('/assistant/memory')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(afterDelete.body.data.notes.map((n: { id: string }) => n.id)).toEqual([other.id]);
  });

  it('404s deleting a memory note that does not exist or belongs to someone else', async () => {
    const stranger = await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        firstName: 'Stranger',
        email: 'assistant-memory-stranger@example.com',
        password: 'Str0ngPass!',
        confirmPassword: 'Str0ngPass!',
        acceptedTerms: true,
      })
      .expect(201);
    const strangersNote = await prisma.companionMemoryNote.create({
      data: {
        userId: stranger.body.data.user.id,
        category: 'GOAL',
        value: "Stranger's private goal.",
      },
    });

    await request(app.getHttpServer())
      .delete(`/assistant/memory/${strangersNote.id}`)
      .set('Authorization', `Bearer ${token}`)
      .expect(404);
    await request(app.getHttpServer())
      .delete('/assistant/memory/00000000-0000-0000-0000-000000000000')
      .set('Authorization', `Bearer ${token}`)
      .expect(404);
  });

  it('rejects an unauthenticated request to delete a single memory note', async () => {
    await request(app.getHttpServer())
      .delete('/assistant/memory/00000000-0000-0000-0000-000000000000')
      .expect(401);
  });
});
