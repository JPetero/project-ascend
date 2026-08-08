import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

describe('Per-device session management (e2e)', () => {
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

  const register = async (email: string, deviceName: string, platform: string) => {
    const res = await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        firstName: 'Ada',
        email,
        password: 'Str0ngPass!',
        confirmPassword: 'Str0ngPass!',
        acceptedTerms: true,
        deviceName,
        platform,
      })
      .expect(201);
    return res.body.data.tokens as { accessToken: string; refreshToken: string };
  };

  const login = async (email: string, deviceName: string, platform: string) => {
    const res = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email, password: 'Str0ngPass!', deviceName, platform })
      .expect(200);
    return res.body.data.tokens as { accessToken: string; refreshToken: string };
  };

  it('lists every active device, marking exactly the calling session current', async () => {
    const email = 'sessions-list@example.com';
    const first = await register(email, 'iPhone 15', 'ios');
    const second = await login(email, 'Pixel 9', 'android');

    const res = await request(app.getHttpServer())
      .get('/auth/sessions')
      .set('Authorization', `Bearer ${second.accessToken}`)
      .expect(200);

    const sessions = res.body.data as Array<{
      id: string;
      deviceName: string;
      platform: string;
      current: boolean;
    }>;
    expect(sessions).toHaveLength(2);
    expect(sessions.filter((s) => s.current)).toHaveLength(1);

    const current = sessions.find((s) => s.current)!;
    expect(current.deviceName).toBe('Pixel 9');
    expect(current.platform).toBe('android');

    const other = sessions.find((s) => !s.current)!;
    expect(other.deviceName).toBe('iPhone 15');

    // Never leaks anything token-shaped.
    for (const session of sessions) {
      expect(session).not.toHaveProperty('tokenHash');
      expect(session).not.toHaveProperty('refreshToken');
    }

    // Sanity: the first device's own refresh token is unaffected.
    await request(app.getHttpServer())
      .post('/auth/refresh')
      .send({ refreshToken: first.refreshToken })
      .expect(200);
  });

  it('revoking another device signs that device out but leaves the caller signed in', async () => {
    const email = 'sessions-revoke-other@example.com';
    const first = await register(email, 'iPad', 'ios');
    const second = await login(email, 'Desktop', 'web');

    const res = await request(app.getHttpServer())
      .get('/auth/sessions')
      .set('Authorization', `Bearer ${second.accessToken}`)
      .expect(200);
    const sessions = res.body.data as Array<{ id: string; current: boolean }>;
    const otherFamilyId = sessions.find((s) => !s.current)!.id;

    await request(app.getHttpServer())
      .delete(`/auth/sessions/${otherFamilyId}`)
      .set('Authorization', `Bearer ${second.accessToken}`)
      .expect(200);

    // The revoked device's refresh token no longer works...
    await request(app.getHttpServer())
      .post('/auth/refresh')
      .send({ refreshToken: first.refreshToken })
      .expect(401);

    // ...but the caller's own session is untouched.
    await request(app.getHttpServer())
      .get('/auth/sessions')
      .set('Authorization', `Bearer ${second.accessToken}`)
      .expect(200);
  });

  it('revoking an unknown or already-signed-out session id returns 404', async () => {
    const email = 'sessions-revoke-missing@example.com';
    const tokens = await register(email, 'iPhone', 'ios');

    await request(app.getHttpServer())
      .delete('/auth/sessions/not-a-real-family-id')
      .set('Authorization', `Bearer ${tokens.accessToken}`)
      .expect(404);
  });

  it('sign-out-all-others revokes every device but the caller, and returns how many', async () => {
    const email = 'sessions-revoke-all-others@example.com';
    const first = await register(email, 'Phone', 'ios');
    const second = await login(email, 'Tablet', 'android');
    const third = await login(email, 'Laptop', 'web');

    const res = await request(app.getHttpServer())
      .delete('/auth/sessions/others')
      .set('Authorization', `Bearer ${third.accessToken}`)
      .expect(200);
    expect(res.body.data.revokedCount).toBe(2);

    await request(app.getHttpServer())
      .post('/auth/refresh')
      .send({ refreshToken: first.refreshToken })
      .expect(401);
    await request(app.getHttpServer())
      .post('/auth/refresh')
      .send({ refreshToken: second.refreshToken })
      .expect(401);

    // The caller's own session survives.
    const sessionsRes = await request(app.getHttpServer())
      .get('/auth/sessions')
      .set('Authorization', `Bearer ${third.accessToken}`)
      .expect(200);
    expect(sessionsRes.body.data).toHaveLength(1);
    expect(sessionsRes.body.data[0].current).toBe(true);
  });

  it('a session can revoke itself via the single-device endpoint (equivalent to signing that device out)', async () => {
    const email = 'sessions-revoke-self@example.com';
    const tokens = await register(email, 'Phone', 'ios');

    const listRes = await request(app.getHttpServer())
      .get('/auth/sessions')
      .set('Authorization', `Bearer ${tokens.accessToken}`)
      .expect(200);
    const ownFamilyId = listRes.body.data[0].id as string;
    expect(listRes.body.data[0].current).toBe(true);

    await request(app.getHttpServer())
      .delete(`/auth/sessions/${ownFamilyId}`)
      .set('Authorization', `Bearer ${tokens.accessToken}`)
      .expect(200);

    await request(app.getHttpServer())
      .post('/auth/refresh')
      .send({ refreshToken: tokens.refreshToken })
      .expect(401);
  });

  it('requires authentication for every sessions endpoint', async () => {
    await request(app.getHttpServer()).get('/auth/sessions').expect(401);
    await request(app.getHttpServer()).delete('/auth/sessions/some-family-id').expect(401);
    await request(app.getHttpServer()).delete('/auth/sessions/others').expect(401);
  });
});
