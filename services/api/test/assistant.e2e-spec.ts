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

  // Build Session 12 Part 7 — companion context minimization. The global
  // ValidationPipe's forbidNonWhitelisted rejects any field the DTO
  // doesn't declare, which is the endpoint-contract half of "the request
  // body itself has no way to carry DM/gallery/support-ticket/location/
  // wearable data" — AssistantService.reply also never queries the
  // database for any of those (see assistant.service.spec.ts's
  // "context minimization" describe block for that half).
  it('rejects a request body carrying fields outside the declared DTO shape, instead of silently ignoring them', async () => {
    await request(app.getHttpServer())
      .post('/assistant/reply')
      .set('Authorization', `Bearer ${token}`)
      .send({
        input: 'plan my workout',
        companion: 'ATLAS',
        style: 'BALANCED',
        directMessages: ['secret DM content'],
        exactGpsRoute: [{ lat: 1, lng: 2 }],
        healthConditions: ['asthma'],
      })
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

  // Build Session 12 Part 4 — sensitive-memory confirmation. The
  // pending-candidate half of this flow only happens inside
  // AssistantService.reply(), which needs a live provider this
  // environment doesn't have (see the file-level comment above), but
  // /assistant/memory/confirm itself has no such dependency — it writes
  // straight through CompanionMemoryService.remember(), same as the
  // structured-note test above.
  it('confirming a memory candidate persists it, visible via GET /assistant/memory', async () => {
    const before = await request(app.getHttpServer())
      .get('/assistant/memory')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(
      before.body.data.notes.some(
        (n: { category: string }) => n.category === 'DIETARY_RESTRICTION',
      ),
    ).toBe(false);

    await request(app.getHttpServer())
      .post('/assistant/memory/confirm')
      .set('Authorization', `Bearer ${token}`)
      .send({ category: 'DIETARY_RESTRICTION', value: 'Allergic to peanuts.' })
      .expect(204);

    const after = await request(app.getHttpServer())
      .get('/assistant/memory')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    const saved = after.body.data.notes.find(
      (n: { category: string }) => n.category === 'DIETARY_RESTRICTION',
    );
    expect(saved).toMatchObject({ category: 'DIETARY_RESTRICTION', value: 'Allergic to peanuts.' });
  });

  it('rejects confirming a memory candidate with an invalid category', async () => {
    await request(app.getHttpServer())
      .post('/assistant/memory/confirm')
      .set('Authorization', `Bearer ${token}`)
      .send({ category: 'NOT_A_REAL_CATEGORY', value: 'Something.' })
      .expect(400);
  });

  it('rejects an unauthenticated request to confirm a memory candidate', async () => {
    await request(app.getHttpServer())
      .post('/assistant/memory/confirm')
      .send({ category: 'GOAL', value: 'Goal: build strength.' })
      .expect(401);
  });
});

/**
 * Build Session 12 Part 8 — "Conversation history" as a real, separate
 * surface from "what Ascend remembers" above. Like the memory endpoints,
 * "a reply appends to a conversation" can't be exercised over real HTTP
 * here (no live provider) — see assistant.service.spec.ts's "conversation
 * history" describe block for that behavior against a mocked provider.
 * This covers the CRUD endpoints themselves against conversations seeded
 * directly via Prisma, plus the explicit cross-feature isolation the
 * directive requires: deleting a conversation must not touch memory
 * notes/preferences, and clearing memory must not touch conversations.
 */
describe('Assistant conversation history (e2e)', () => {
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
        firstName: 'Rae',
        email: 'assistant-conversations-e2e@example.com',
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

  it('reports no conversations for a fresh account', async () => {
    const res = await request(app.getHttpServer())
      .get('/assistant/conversations')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(res.body.data.conversations).toEqual([]);
  });

  it('rejects an unauthenticated request to list conversations', async () => {
    await request(app.getHttpServer()).get('/assistant/conversations').expect(401);
  });

  it('lists, opens, renames, and deletes a seeded conversation', async () => {
    const conversation = await prisma.companionConversation.create({
      data: { userId, companion: 'ATLAS' },
    });
    // Sequential creates, not createMany — see companion-conversations
    // .service.ts's appendTurn comment: createMany ties createdAt across
    // rows in one INSERT, which made this seed's "last message" order
    // nondeterministic.
    await prisma.companionChatMessage.create({
      data: { conversationId: conversation.id, isFromUser: true, text: 'Plan my week' },
    });
    await prisma.companionChatMessage.create({
      data: { conversationId: conversation.id, isFromUser: false, text: 'Sure — how many days?' },
    });

    const listed = await request(app.getHttpServer())
      .get('/assistant/conversations')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(listed.body.data.conversations).toHaveLength(1);
    expect(listed.body.data.conversations[0]).toMatchObject({
      id: conversation.id,
      companion: 'ATLAS',
      title: null,
      lastMessagePreview: 'Sure — how many days?',
    });

    const opened = await request(app.getHttpServer())
      .get(`/assistant/conversations/${conversation.id}`)
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(opened.body.data.messages.map((m: { text: string }) => m.text)).toEqual([
      'Plan my week',
      'Sure — how many days?',
    ]);

    await request(app.getHttpServer())
      .patch(`/assistant/conversations/${conversation.id}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ title: 'Weekly plan' })
      .expect(204);
    const renamed = await request(app.getHttpServer())
      .get(`/assistant/conversations/${conversation.id}`)
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(renamed.body.data.title).toBe('Weekly plan');

    await request(app.getHttpServer())
      .delete(`/assistant/conversations/${conversation.id}`)
      .set('Authorization', `Bearer ${token}`)
      .expect(204);
    await request(app.getHttpServer())
      .get(`/assistant/conversations/${conversation.id}`)
      .set('Authorization', `Bearer ${token}`)
      .expect(404);
  });

  it('404s opening, renaming, or deleting a conversation belonging to someone else', async () => {
    const stranger = await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        firstName: 'Stranger',
        email: 'assistant-conversations-stranger@example.com',
        password: 'Str0ngPass!',
        confirmPassword: 'Str0ngPass!',
        acceptedTerms: true,
      })
      .expect(201);
    const strangersConversation = await prisma.companionConversation.create({
      data: { userId: stranger.body.data.user.id, companion: 'NOVA' },
    });

    await request(app.getHttpServer())
      .get(`/assistant/conversations/${strangersConversation.id}`)
      .set('Authorization', `Bearer ${token}`)
      .expect(404);
    await request(app.getHttpServer())
      .patch(`/assistant/conversations/${strangersConversation.id}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ title: 'Hijacked' })
      .expect(404);
    await request(app.getHttpServer())
      .delete(`/assistant/conversations/${strangersConversation.id}`)
      .set('Authorization', `Bearer ${token}`)
      .expect(404);
  });

  it("clearing all conversations removes every one of this user's conversations but never touches memory notes or preferences", async () => {
    await prisma.companionConversation.create({ data: { userId, companion: 'ATLAS' } });
    await prisma.companionConversation.create({ data: { userId, companion: 'NOVA' } });
    const memoryNote = await prisma.companionMemoryNote.create({
      data: { userId, category: 'GOAL', value: 'Goal: build strength.' },
    });
    await prisma.preference.upsert({
      where: { userId },
      create: { userId, aiMemoryEnabled: true },
      update: { aiMemoryEnabled: true },
    });

    await request(app.getHttpServer())
      .delete('/assistant/conversations')
      .set('Authorization', `Bearer ${token}`)
      .expect(204);

    const afterClear = await request(app.getHttpServer())
      .get('/assistant/conversations')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    expect(afterClear.body.data.conversations).toEqual([]);

    // Clearing conversation history never touches memory or preferences.
    const memoryAfterClear = await prisma.companionMemoryNote.findUnique({
      where: { id: memoryNote.id },
    });
    expect(memoryAfterClear).not.toBeNull();
    const preferenceAfterClear = await prisma.preference.findUnique({ where: { userId } });
    expect(preferenceAfterClear?.aiMemoryEnabled).toBe(true);
  });

  it('deleting a single conversation never touches memory notes or preferences', async () => {
    const conversation = await prisma.companionConversation.create({
      data: { userId, companion: 'ATLAS' },
    });
    const memoryNote = await prisma.companionMemoryNote.create({
      data: { userId, category: 'EQUIPMENT', value: 'Has access to: dumbbells.' },
    });

    await request(app.getHttpServer())
      .delete(`/assistant/conversations/${conversation.id}`)
      .set('Authorization', `Bearer ${token}`)
      .expect(204);

    const memoryAfterDelete = await prisma.companionMemoryNote.findUnique({
      where: { id: memoryNote.id },
    });
    expect(memoryAfterDelete).not.toBeNull();
  });

  it('clearing memory never touches conversation history', async () => {
    const conversation = await prisma.companionConversation.create({
      data: { userId, companion: 'ATLAS' },
    });
    await prisma.companionChatMessage.create({
      data: { conversationId: conversation.id, isFromUser: true, text: 'Still here?' },
    });

    await request(app.getHttpServer())
      .delete('/assistant/memory')
      .set('Authorization', `Bearer ${token}`)
      .expect(204);

    const conversationAfterMemoryClear = await prisma.companionConversation.findUnique({
      where: { id: conversation.id },
    });
    expect(conversationAfterMemoryClear).not.toBeNull();
  });

  it('rejects renaming a conversation with an empty title', async () => {
    const conversation = await prisma.companionConversation.create({
      data: { userId, companion: 'ATLAS' },
    });
    await request(app.getHttpServer())
      .patch(`/assistant/conversations/${conversation.id}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ title: '' })
      .expect(400);
  });

  it('rejects unauthenticated requests to open, rename, delete, or clear conversations', async () => {
    const conversation = await prisma.companionConversation.create({
      data: { userId, companion: 'ATLAS' },
    });

    await request(app.getHttpServer())
      .get(`/assistant/conversations/${conversation.id}`)
      .expect(401);
    await request(app.getHttpServer())
      .patch(`/assistant/conversations/${conversation.id}`)
      .send({ title: 'x' })
      .expect(401);
    await request(app.getHttpServer())
      .delete(`/assistant/conversations/${conversation.id}`)
      .expect(401);
    await request(app.getHttpServer()).delete('/assistant/conversations').expect(401);
  });
});
