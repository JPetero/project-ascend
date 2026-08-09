import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

describe('Notifications (e2e)', () => {
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

    const a = await register('notifications-a@example.com', 'Ada');
    const b = await register('notifications-b@example.com', 'Bea');
    tokenA = a.token;
    tokenB = b.token;
    userIdA = a.id;
    userIdB = b.id;
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

  it('returns default preferences with everything enabled', async () => {
    const res = await request(app.getHttpServer())
      .get('/notifications/preferences')
      .set(authA())
      .expect(200);

    expect(res.body.data.workoutReminders).toBe(true);
    expect(res.body.data.socialNotifications).toBe(true);
  });

  it('updates a single preference without affecting the others', async () => {
    const res = await request(app.getHttpServer())
      .patch('/notifications/preferences')
      .set(authA())
      .send({ workoutReminders: false })
      .expect(200);

    expect(res.body.data.workoutReminders).toBe(false);
    expect(res.body.data.waterReminders).toBe(true);
  });

  it('a friend request creates a notification event for the recipient', async () => {
    await request(app.getHttpServer())
      .post('/friends/requests')
      .set(authA())
      .send({ recipientId: userIdB })
      .expect(201);

    const events = await request(app.getHttpServer())
      .get('/notifications/events')
      .set(authB())
      .expect(200);
    const friendRequestEvent = (
      events.body.data as Array<{ type: string; readAt: string | null }>
    ).find((e) => e.type === 'FRIEND_REQUEST');
    expect(friendRequestEvent).toBeDefined();
    expect(friendRequestEvent!.readAt).toBeNull();
  });

  it('marks an event read and reduces the unread count', async () => {
    const events = await request(app.getHttpServer())
      .get('/notifications/events')
      .set(authB())
      .expect(200);
    const eventId = (events.body.data as Array<{ id: string }>)[0].id;

    const before = await request(app.getHttpServer())
      .get('/notifications/events/unread-count')
      .set(authB())
      .expect(200);
    expect(before.body.data).toBeGreaterThanOrEqual(1);

    await request(app.getHttpServer())
      .post(`/notifications/events/${eventId}/read`)
      .set(authB())
      .expect(201);

    const after = await request(app.getHttpServer())
      .get('/notifications/events/unread-count')
      .set(authB())
      .expect(200);
    expect(after.body.data).toBe(before.body.data - 1);
  });

  it('a direct message creates a notification event for the recipient, the same as a friend request does (Build Session 10 Part 30)', async () => {
    const conversation = await request(app.getHttpServer())
      .post('/messages/conversations')
      .set(authB())
      .send({ recipientId: userIdA })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/messages/conversations/${conversation.body.data.id}/messages`)
      .set(authB())
      .send({ body: 'Hey Ada, got a minute?' })
      .expect(201);

    const events = await request(app.getHttpServer())
      .get('/notifications/events')
      .set(authA())
      .expect(200);
    const dmEvent = (events.body.data as Array<{ type: string; readAt: string | null }>).find(
      (e) => e.type === 'DIRECT_MESSAGE',
    );
    expect(dmEvent).toBeDefined();
    expect(dmEvent!.readAt).toBeNull();
  });

  it('disabling social notifications suppresses future friend-request events', async () => {
    await request(app.getHttpServer())
      .patch('/notifications/preferences')
      .set(authB())
      .send({ socialNotifications: false })
      .expect(200);

    const register = await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        firstName: 'Cid',
        email: 'notifications-c@example.com',
        password: 'Str0ngPass!',
        confirmPassword: 'Str0ngPass!',
        acceptedTerms: true,
      })
      .expect(201);
    const tokenC = register.body.data.tokens.accessToken as string;

    const before = await request(app.getHttpServer())
      .get('/notifications/events')
      .set(authB())
      .expect(200);
    const beforeCount = (before.body.data as unknown[]).length;

    await request(app.getHttpServer())
      .post('/friends/requests')
      .set({ Authorization: `Bearer ${tokenC}` })
      .send({ recipientId: userIdB })
      .expect(201);

    const after = await request(app.getHttpServer())
      .get('/notifications/events')
      .set(authB())
      .expect(200);
    expect((after.body.data as unknown[]).length).toBe(beforeCount);
  });

  it('registers a device token, then unregisters it', async () => {
    await request(app.getHttpServer())
      .post('/notifications/device-tokens')
      .set(authA())
      .send({ token: 'fcm-test-token-1', platform: 'ios' })
      .expect(200);

    const stored = await prisma.pushDeviceToken.findUnique({
      where: { token: 'fcm-test-token-1' },
    });
    expect(stored).not.toBeNull();
    expect(stored!.platform).toBe('ios');

    await request(app.getHttpServer())
      .delete('/notifications/device-tokens/fcm-test-token-1')
      .set(authA())
      .expect(200);

    const afterDelete = await prisma.pushDeviceToken.findUnique({
      where: { token: 'fcm-test-token-1' },
    });
    expect(afterDelete).toBeNull();
  });

  it('re-registering the same token moves it to the new registering user', async () => {
    await request(app.getHttpServer())
      .post('/notifications/device-tokens')
      .set(authA())
      .send({ token: 'fcm-shared-token', platform: 'android' })
      .expect(200);

    await request(app.getHttpServer())
      .post('/notifications/device-tokens')
      .set(authB())
      .send({ token: 'fcm-shared-token', platform: 'android' })
      .expect(200);

    const stored = await prisma.pushDeviceToken.findUnique({
      where: { token: 'fcm-shared-token' },
    });
    expect(stored!.userId).toBe(userIdB);
  });

  it('cannot unregister a token belonging to another user', async () => {
    await request(app.getHttpServer())
      .post('/notifications/device-tokens')
      .set(authB())
      .send({ token: 'fcm-owned-by-b' })
      .expect(200);

    await request(app.getHttpServer())
      .delete('/notifications/device-tokens/fcm-owned-by-b')
      .set(authA())
      .expect(200);

    const stillThere = await prisma.pushDeviceToken.findUnique({
      where: { token: 'fcm-owned-by-b' },
    });
    expect(stillThere).not.toBeNull();
  });

  it('requires authentication for device-token endpoints', async () => {
    await request(app.getHttpServer())
      .post('/notifications/device-tokens')
      .send({ token: 'unauthenticated-token' })
      .expect(401);
    await request(app.getHttpServer())
      .delete('/notifications/device-tokens/unauthenticated-token')
      .expect(401);
  });
});
