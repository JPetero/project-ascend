import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

describe('Direct Messaging (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let tokenA: string;
  let tokenB: string;
  let tokenC: string;
  let userIdA: string;
  let userIdB: string;
  let userIdC: string;

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

    const a = await register('messages-a@example.com', 'Ada');
    const b = await register('messages-b@example.com', 'Bea');
    const c = await register('messages-c@example.com', 'Cid');
    tokenA = a.token;
    tokenB = b.token;
    tokenC = c.token;
    userIdA = a.id;
    userIdB = b.id;
    userIdC = c.id;
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  const authA = () => ({ Authorization: `Bearer ${tokenA}` });
  const authB = () => ({ Authorization: `Bearer ${tokenB}` });
  const authC = () => ({ Authorization: `Bearer ${tokenC}` });

  it('rejects starting a conversation with yourself', async () => {
    await request(app.getHttpServer())
      .post('/messages/conversations')
      .set(authA())
      .send({ recipientId: userIdA })
      .expect(400);
  });

  it('starts a PENDING message request between strangers, limits the initiator to one message, and auto-accepts on reply', async () => {
    const started = await request(app.getHttpServer())
      .post('/messages/conversations')
      .set(authA())
      .send({ recipientId: userIdB })
      .expect(201);
    const conversationId = started.body.data.id as string;
    expect(started.body.data.status).toBe('PENDING');

    await request(app.getHttpServer())
      .post(`/messages/conversations/${conversationId}/messages`)
      .set(authA())
      .send({ body: 'Hi, want to train together?' })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/messages/conversations/${conversationId}/messages`)
      .set(authA())
      .send({ body: 'Second message before a reply' })
      .expect(400);

    await request(app.getHttpServer())
      .post(`/messages/conversations/${conversationId}/messages`)
      .set(authB())
      .send({ body: 'Sure!' })
      .expect(201);

    const conversations = await request(app.getHttpServer())
      .get('/messages/conversations')
      .set(authA())
      .expect(200);
    const found = conversations.body.data.find((c: { id: string }) => c.id === conversationId);
    expect(found.status).toBe('ACCEPTED');

    // Now that they're not strangers in this thread, A can send freely.
    await request(app.getHttpServer())
      .post(`/messages/conversations/${conversationId}/messages`)
      .set(authA())
      .send({ body: 'Great, see you at 6' })
      .expect(201);
  });

  it('starts an ACCEPTED conversation immediately between friends, with no message limit', async () => {
    const sent = await request(app.getHttpServer())
      .post('/friends/requests')
      .set(authA())
      .send({ recipientId: userIdC })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/friends/requests/${sent.body.data.id}/accept`)
      .set(authC())
      .expect(201);

    const started = await request(app.getHttpServer())
      .post('/messages/conversations')
      .set(authA())
      .send({ recipientId: userIdC })
      .expect(201);
    expect(started.body.data.status).toBe('ACCEPTED');
    const conversationId = started.body.data.id as string;

    await request(app.getHttpServer())
      .post(`/messages/conversations/${conversationId}/messages`)
      .set(authA())
      .send({ body: 'One' })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/messages/conversations/${conversationId}/messages`)
      .set(authA())
      .send({ body: 'Two, no limit since we are friends' })
      .expect(201);
  });

  it('reuses the same conversation on a second start call rather than duplicating it', async () => {
    const first = await request(app.getHttpServer())
      .post('/messages/conversations')
      .set(authA())
      .send({ recipientId: userIdC })
      .expect(201);
    const second = await request(app.getHttpServer())
      .post('/messages/conversations')
      .set(authC())
      .send({ recipientId: userIdA })
      .expect(201);

    expect(second.body.data.id).toBe(first.body.data.id);
  });

  it('marks fetched messages as delivered and explicit reads as read, reducing the unread count', async () => {
    const started = await request(app.getHttpServer())
      .post('/messages/conversations')
      .set(authA())
      .send({ recipientId: userIdC })
      .expect(201);
    const conversationId = started.body.data.id as string;

    await request(app.getHttpServer())
      .post(`/messages/conversations/${conversationId}/messages`)
      .set(authA())
      .send({ body: 'Unread for Cid' })
      .expect(201);

    const before = await request(app.getHttpServer())
      .get('/messages/unread-count')
      .set(authC())
      .expect(200);
    expect(before.body.data).toBeGreaterThanOrEqual(1);

    await request(app.getHttpServer())
      .get(`/messages/conversations/${conversationId}/messages`)
      .set(authC())
      .expect(200);
    await request(app.getHttpServer())
      .post(`/messages/conversations/${conversationId}/read`)
      .set(authC())
      .expect(201);

    const after = await request(app.getHttpServer())
      .get('/messages/unread-count')
      .set(authC())
      .expect(200);
    expect(after.body.data).toBe(0);
  });

  it('deleting a conversation for self hides it, and a new message brings it back', async () => {
    const started = await request(app.getHttpServer())
      .post('/messages/conversations')
      .set(authA())
      .send({ recipientId: userIdC })
      .expect(201);
    const conversationId = started.body.data.id as string;

    await request(app.getHttpServer())
      .delete(`/messages/conversations/${conversationId}`)
      .set(authA())
      .expect(200);

    const hidden = await request(app.getHttpServer())
      .get('/messages/conversations')
      .set(authA())
      .expect(200);
    expect(hidden.body.data.some((c: { id: string }) => c.id === conversationId)).toBe(false);

    await request(app.getHttpServer())
      .post(`/messages/conversations/${conversationId}/messages`)
      .set(authC())
      .send({ body: 'Are you still there?' })
      .expect(201);

    const restored = await request(app.getHttpServer())
      .get('/messages/conversations')
      .set(authA())
      .expect(200);
    expect(restored.body.data.some((c: { id: string }) => c.id === conversationId)).toBe(true);
  });

  it('mutes a conversation', async () => {
    const started = await request(app.getHttpServer())
      .post('/messages/conversations')
      .set(authA())
      .send({ recipientId: userIdC })
      .expect(201);

    await request(app.getHttpServer())
      .patch(`/messages/conversations/${started.body.data.id}/mute`)
      .set(authA())
      .send({ muted: true })
      .expect(200);

    const conversations = await request(app.getHttpServer())
      .get('/messages/conversations')
      .set(authA())
      .expect(200);
    const found = conversations.body.data.find(
      (c: { id: string }) => c.id === started.body.data.id,
    );
    expect(found.isMuted).toBe(true);
  });

  it(
    'rejects a non-boolean muted value instead of silently treating it as ' +
      'false (Build Session 10 Parts 27-29)',
    async () => {
      const started = await request(app.getHttpServer())
        .post('/messages/conversations')
        .set(authA())
        .send({ recipientId: userIdC })
        .expect(201);

      await request(app.getHttpServer())
        .patch(`/messages/conversations/${started.body.data.id}/mute`)
        .set(authA())
        .send({ muted: 'yes' })
        .expect(400);
    },
  );

  it('a recipient can explicitly decline a pending message request', async () => {
    const started = await request(app.getHttpServer())
      .post('/messages/conversations')
      .set(authB())
      .send({ recipientId: userIdC })
      .expect(201);
    const conversationId = started.body.data.id as string;

    await request(app.getHttpServer())
      .post(`/messages/conversations/${conversationId}/decline`)
      .set(authC())
      .expect(201);

    await request(app.getHttpServer())
      .post(`/messages/conversations/${conversationId}/messages`)
      .set(authB())
      .send({ body: 'Hello?' })
      .expect(403);
  });

  it('reports a message', async () => {
    const started = await request(app.getHttpServer())
      .post('/messages/conversations')
      .set(authB())
      .send({ recipientId: userIdA })
      .expect(201);
    const sentMessage = await request(app.getHttpServer())
      .post(`/messages/conversations/${started.body.data.id}/messages`)
      .set(authB())
      .send({ body: 'reportable content' })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/messages/${sentMessage.body.data.id}/report`)
      .set(authA())
      .send({ reason: 'Inappropriate.' })
      .expect(201);
  });

  it('404s conversation actions for a real conversation id but a non-participant', async () => {
    const started = await request(app.getHttpServer())
      .post('/messages/conversations')
      .set(authA())
      .send({ recipientId: userIdB })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/messages/conversations/${started.body.data.id}/messages`)
      .set(authC())
      .send({ body: 'sneaking in' })
      .expect(404);
  });
});
