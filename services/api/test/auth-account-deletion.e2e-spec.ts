import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

/**
 * DELETE /auth/account is a deliberate *soft* delete: it revokes every
 * session and anonymizes the email so the account can never log in again,
 * but by design it does NOT cascade to the user's messages, friendships,
 * or posts — a hard-delete sweep is a separate, deferred piece of work
 * (see auth.service.ts::deleteAccount). Nothing exercised that contract
 * end-to-end before this (Build Session 10 Part 30): a regression here
 * would either leave a "deleted" account still usable, or silently start
 * cascading in a way the rest of the product isn't built to expect.
 */
describe('Account deletion (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let tokenA: string;
  let refreshTokenA: string;
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
        refreshToken: res.body.data.tokens.refreshToken as string,
        id: res.body.data.user.id as string,
      };
    };

    const a = await register('deletion-a@example.com', 'Ada');
    const b = await register('deletion-b@example.com', 'Bea');
    tokenA = a.token;
    refreshTokenA = a.refreshToken;
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

  it('requires the correct password, then revokes every session and blocks future login without touching unrelated data', async () => {
    // A and B become friends and exchange a message, and A posts, so we
    // have real cross-module state to check is (or isn't) affected.
    const sent = await request(app.getHttpServer())
      .post('/friends/requests')
      .set(authA())
      .send({ recipientId: userIdB })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/friends/requests/${sent.body.data.id}/accept`)
      .set(authB())
      .expect(201);

    const conversation = await request(app.getHttpServer())
      .post('/messages/conversations')
      .set(authA())
      .send({ recipientId: userIdB })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/messages/conversations/${conversation.body.data.id}/messages`)
      .set(authA())
      .send({ body: 'Message from an account about to be deleted' })
      .expect(201);

    const post = await request(app.getHttpServer())
      .post('/community/posts')
      .set(authA())
      .send({ caption: 'A post from before deletion' })
      .expect(201);

    // Wrong password is rejected and does not delete anything.
    await request(app.getHttpServer())
      .delete('/auth/account')
      .set(authA())
      .send({ password: 'TotallyWrongPassword!' })
      .expect(401);
    await request(app.getHttpServer()).get('/auth/me').set(authA()).expect(200);

    // Correct password deletes the account.
    await request(app.getHttpServer())
      .delete('/auth/account')
      .set(authA())
      .send({ password: 'Str0ngPass!' })
      .expect(200);

    // Every existing session for A is dead — the access token this test
    // was using no longer works, and neither does the refresh token.
    await request(app.getHttpServer()).get('/auth/me').set(authA()).expect(401);
    await request(app.getHttpServer())
      .post('/auth/refresh')
      .send({ refreshToken: refreshTokenA })
      .expect(401);

    // The original email can never log in again (it was anonymized).
    await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'deletion-a@example.com', password: 'Str0ngPass!' })
      .expect(401);

    // This is a soft delete: it does not cascade. B still sees the
    // friendship, the DM thread, and A's post exactly as before — a
    // future hard-delete sweep is a deliberately separate piece of work,
    // and this pins the current contract so that isn't changed silently.
    const friendsOfB = await request(app.getHttpServer())
      .get('/friends')
      .set(authB())
      .expect(200);
    expect(
      friendsOfB.body.data.some((f: { userId: string }) => f.userId === userIdA),
    ).toBe(true);

    const messagesForB = await request(app.getHttpServer())
      .get(`/messages/conversations/${conversation.body.data.id}/messages`)
      .set(authB())
      .expect(200);
    expect(
      messagesForB.body.data.some(
        (m: { body: string }) => m.body === 'Message from an account about to be deleted',
      ),
    ).toBe(true);

    await request(app.getHttpServer())
      .get(`/community/posts/${post.body.data.id}`)
      .set(authB())
      .expect(200);
  });
});
