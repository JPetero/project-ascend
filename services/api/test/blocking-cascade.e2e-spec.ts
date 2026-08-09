import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

/**
 * Blocking touches three modules through one shared `CommunityBlock` table
 * (friends, community, messages), but each module's own e2e spec only
 * exercises its own slice in isolation. This journey blocks a real friend
 * mid-conversation and checks all three consumers agree on the outcome in
 * one flow, the way a real user's block action actually plays out
 * (Build Session 10 Part 30).
 */
describe('Blocking cascade across friends, community, and messages (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let tokenA: string;
  let tokenB: string;
  let userIdA: string;
  let userIdB: string;

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

    const a = await register('blocking-a@example.com', 'Ada');
    const b = await register('blocking-b@example.com', 'Bea');
    tokenA = a.token;
    tokenB = b.token;
    userIdA = a.id;
    userIdB = b.id;
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  const authA = () => ({ Authorization: `Bearer ${tokenA}` });
  const authB = () => ({ Authorization: `Bearer ${tokenB}` });

  it('a block made mid-conversation severs the friendship, hides the profile, and stops further messages in the existing thread', async () => {
    // A and B become friends.
    const sent = await request(app.getHttpServer())
      .post('/friends/requests')
      .set(authA())
      .send({ recipientId: userIdB })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/friends/requests/${sent.body.data.id}/accept`)
      .set(authB())
      .expect(201);

    // As friends, A starts a DM thread with B and B replies — an ACCEPTED,
    // ongoing conversation, not a pending request.
    const started = await request(app.getHttpServer())
      .post('/messages/conversations')
      .set(authA())
      .send({ recipientId: userIdB })
      .expect(201);
    const conversationId = started.body.data.id as string;
    expect(started.body.data.status).toBe('ACCEPTED');

    await request(app.getHttpServer())
      .post(`/messages/conversations/${conversationId}/messages`)
      .set(authA())
      .send({ body: 'Hey, still on for Saturday?' })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/messages/conversations/${conversationId}/messages`)
      .set(authB())
      .send({ body: 'Yep, see you then!' })
      .expect(201);

    // B blocks A mid-conversation.
    await request(app.getHttpServer())
      .post(`/community/block/${userIdA}`)
      .set(authB())
      .expect(204);

    // Friendship is severed on both sides.
    const friendsOfA = await request(app.getHttpServer())
      .get('/friends')
      .set(authA())
      .expect(200);
    expect(
      friendsOfA.body.data.some((f: { userId: string }) => f.userId === userIdB),
    ).toBe(false);

    // A can no longer see B's profile.
    await request(app.getHttpServer())
      .get(`/community/profile/${userIdB}`)
      .set(authA())
      .expect(404);

    // Neither side can send further messages in the now-blocked thread —
    // the existing conversation isn't grandfathered in.
    await request(app.getHttpServer())
      .post(`/messages/conversations/${conversationId}/messages`)
      .set(authA())
      .send({ body: 'Hello? Are you there?' })
      .expect(403);
    await request(app.getHttpServer())
      .post(`/messages/conversations/${conversationId}/messages`)
      .set(authB())
      .send({ body: 'Not replying to you.' })
      .expect(403);

    // And A cannot start a fresh conversation with B either.
    await request(app.getHttpServer())
      .post('/messages/conversations')
      .set(authA())
      .send({ recipientId: userIdB })
      .expect(404);

    // Unblocking restores the ability to message, proving the block (not
    // some other broken state) was what closed the thread.
    await request(app.getHttpServer())
      .delete(`/community/block/${userIdA}`)
      .set(authB())
      .expect(204);
    await request(app.getHttpServer())
      .post(`/messages/conversations/${conversationId}/messages`)
      .set(authA())
      .send({ body: 'All good now?' })
      .expect(201);
  });
});
