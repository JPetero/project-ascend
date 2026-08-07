import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

describe('Friendship system (e2e)', () => {
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

    const a = await register('friends-a@example.com', 'Ada');
    const b = await register('friends-b@example.com', 'Bea');
    const c = await register('friends-c@example.com', 'Cid');
    tokenA = a.token;
    tokenB = b.token;
    tokenC = c.token;
    userIdA = a.id;
    userIdB = b.id;
    userIdC = c.id;

    await request(app.getHttpServer())
      .post('/community/profile')
      .set(authFor(tokenA))
      .send({ displayName: 'Ada Friendly' })
      .expect(201);
    await request(app.getHttpServer())
      .post('/community/profile')
      .set(authFor(tokenB))
      .send({ displayName: 'Bea Friendly' })
      .expect(201);
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  function authFor(token: string) {
    return { Authorization: `Bearer ${token}` };
  }
  const authA = () => authFor(tokenA);
  const authB = () => authFor(tokenB);
  const authC = () => authFor(tokenC);

  it('rejects sending a friend request to yourself', async () => {
    await request(app.getHttpServer())
      .post('/friends/requests')
      .set(authA())
      .send({ recipientId: userIdA })
      .expect(400);
  });

  it('searches users by display name', async () => {
    const results = await request(app.getHttpServer())
      .get('/friends/search')
      .query({ query: 'Friendly' })
      .set(authC())
      .expect(200);

    const names = (results.body.data as Array<{ displayName: string }>).map((u) => u.displayName);
    expect(names).toContain('Ada Friendly');
    expect(names).toContain('Bea Friendly');
  });

  it('sends a request, lists it as incoming/outgoing, and accepts it into a real friendship', async () => {
    const sent = await request(app.getHttpServer())
      .post('/friends/requests')
      .set(authA())
      .send({ recipientId: userIdB })
      .expect(201);
    const requestId = sent.body.data.id as string;

    const outgoing = await request(app.getHttpServer())
      .get('/friends/requests/outgoing')
      .set(authA())
      .expect(200);
    expect(outgoing.body.data.some((r: { id: string }) => r.id === requestId)).toBe(true);

    const incoming = await request(app.getHttpServer())
      .get('/friends/requests/incoming')
      .set(authB())
      .expect(200);
    expect(incoming.body.data.some((r: { id: string }) => r.id === requestId)).toBe(true);

    await request(app.getHttpServer())
      .post(`/friends/requests/${requestId}/accept`)
      .set(authB())
      .expect(201);

    const friendsOfA = await request(app.getHttpServer()).get('/friends').set(authA()).expect(200);
    expect(friendsOfA.body.data.some((f: { userId: string }) => f.userId === userIdB)).toBe(true);

    const countA = await request(app.getHttpServer())
      .get('/friends/count')
      .set(authA())
      .expect(200);
    expect(countA.body.data).toBe(1);
  });

  it('rejects sending a request to someone already a friend', async () => {
    await request(app.getHttpServer())
      .post('/friends/requests')
      .set(authA())
      .send({ recipientId: userIdB })
      .expect(400);
  });

  it('removing a friend deletes the friendship in both directions', async () => {
    await request(app.getHttpServer()).delete(`/friends/${userIdB}`).set(authA()).expect(200);

    const friendsOfA = await request(app.getHttpServer()).get('/friends').set(authA()).expect(200);
    expect(friendsOfA.body.data).toEqual([]);

    const friendsOfB = await request(app.getHttpServer()).get('/friends').set(authB()).expect(200);
    expect(friendsOfB.body.data).toEqual([]);
  });

  it('404s removing a friendship that does not exist', async () => {
    await request(app.getHttpServer()).delete(`/friends/${userIdB}`).set(authA()).expect(404);
  });

  it('a duplicate active request is rejected, but the reciprocal direction auto-accepts', async () => {
    const first = await request(app.getHttpServer())
      .post('/friends/requests')
      .set(authA())
      .send({ recipientId: userIdC })
      .expect(201);

    await request(app.getHttpServer())
      .post('/friends/requests')
      .set(authA())
      .send({ recipientId: userIdC })
      .expect(400);

    await request(app.getHttpServer())
      .post('/friends/requests')
      .set(authC())
      .send({ recipientId: userIdA })
      .expect(201);

    const areFriends = await request(app.getHttpServer()).get('/friends').set(authA()).expect(200);
    expect(areFriends.body.data.some((f: { userId: string }) => f.userId === userIdC)).toBe(true);

    // Cleanup for later tests.
    await request(app.getHttpServer()).delete(`/friends/${userIdC}`).set(authA()).expect(200);
    void first;
  });

  it('a sender can cancel their own pending request; a recipient cannot cancel it', async () => {
    const sent = await request(app.getHttpServer())
      .post('/friends/requests')
      .set(authA())
      .send({ recipientId: userIdC })
      .expect(201);
    const requestId = sent.body.data.id as string;

    await request(app.getHttpServer())
      .post(`/friends/requests/${requestId}/cancel`)
      .set(authC())
      .expect(404);

    await request(app.getHttpServer())
      .post(`/friends/requests/${requestId}/cancel`)
      .set(authA())
      .expect(201);

    await request(app.getHttpServer())
      .post(`/friends/requests/${requestId}/cancel`)
      .set(authA())
      .expect(400);
  });

  it('a recipient can decline a request instead of accepting it', async () => {
    const sent = await request(app.getHttpServer())
      .post('/friends/requests')
      .set(authA())
      .send({ recipientId: userIdC })
      .expect(201);
    const requestId = sent.body.data.id as string;

    await request(app.getHttpServer())
      .post(`/friends/requests/${requestId}/decline`)
      .set(authC())
      .expect(201);

    const areFriends = await request(app.getHttpServer()).get('/friends').set(authA()).expect(200);
    expect(areFriends.body.data.some((f: { userId: string }) => f.userId === userIdC)).toBe(false);
  });

  it('blocking someone severs an existing friendship and cancels pending requests', async () => {
    const sent = await request(app.getHttpServer())
      .post('/friends/requests')
      .set(authA())
      .send({ recipientId: userIdB })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/friends/requests/${sent.body.data.id}/accept`)
      .set(authB())
      .expect(201);

    const friendsBefore = await request(app.getHttpServer())
      .get('/friends')
      .set(authA())
      .expect(200);
    expect(friendsBefore.body.data.some((f: { userId: string }) => f.userId === userIdB)).toBe(
      true,
    );

    await request(app.getHttpServer()).post(`/community/block/${userIdB}`).set(authA()).expect(204);

    const friendsAfter = await request(app.getHttpServer())
      .get('/friends')
      .set(authA())
      .expect(200);
    expect(friendsAfter.body.data.some((f: { userId: string }) => f.userId === userIdB)).toBe(
      false,
    );

    await request(app.getHttpServer())
      .delete(`/community/block/${userIdB}`)
      .set(authA())
      .expect(204);
  });
});
