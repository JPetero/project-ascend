import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

describe('Project Ascend API (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  const registerPayload = {
    firstName: 'Jordan',
    email: 'jordan@example.com',
    password: 'Str0ngPass!',
    confirmPassword: 'Str0ngPass!',
    acceptedTerms: true,
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
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  it('GET /health is public and returns ok', async () => {
    const res = await request(app.getHttpServer()).get('/health').expect(200);
    expect(res.body.data.status).toBe('ok');
  });

  it('rejects registration when passwords do not match', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/register')
      .send({ ...registerPayload, confirmPassword: 'Different1!' })
      .expect(409);
    expect(res.body.error.code).toBe('CONFLICT');
  });

  let accessToken: string;
  let refreshToken: string;

  it('registers a new user', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/register')
      .send(registerPayload)
      .expect(201);

    expect(res.body.error).toBeNull();
    expect(res.body.data.user.email).toBe('jordan@example.com');
    expect(res.body.data.tokens.accessToken).toBeDefined();
    expect(res.body.data.tokens.refreshToken).toBeDefined();

    accessToken = res.body.data.tokens.accessToken;
    refreshToken = res.body.data.tokens.refreshToken;
  });

  it('rejects duplicate registration', async () => {
    await request(app.getHttpServer()).post('/auth/register').send(registerPayload).expect(409);
  });

  it('rejects login with wrong password', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: registerPayload.email, password: 'WrongPassword1' })
      .expect(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });

  it('logs in with correct credentials', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: registerPayload.email, password: registerPayload.password })
      .expect(200);
    expect(res.body.data.tokens.accessToken).toBeDefined();
  });

  it('rejects /auth/me without a token', async () => {
    await request(app.getHttpServer()).get('/auth/me').expect(401);
  });

  it('returns the current user on /auth/me with a valid token', async () => {
    const res = await request(app.getHttpServer())
      .get('/auth/me')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);
    expect(res.body.data.email).toBe(registerPayload.email);
  });

  it('returns the profile created at registration', async () => {
    const res = await request(app.getHttpServer())
      .get('/profile')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);
    expect(res.body.data.firstName).toBe('Jordan');
    expect(res.body.data.onboardingCompleted).toBe(false);
  });

  it('saves onboarding progress via PATCH /profile/onboarding', async () => {
    const res = await request(app.getHttpServer())
      .patch('/profile/onboarding')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        onboardingStep: 3,
        sexForCalculations: 'FEMALE',
        heightCm: 168,
        weightKg: 62,
        equipment: [{ type: 'dumbbells' }, { type: 'resistance_bands' }],
        workoutSchedule: { durationMinutes: 30, daysOfWeek: ['MON', 'WED', 'FRI'] },
      })
      .expect(200);

    expect(res.body.data.onboardingStep).toBe(3);
    expect(res.body.data.sexForCalculations).toBe('FEMALE');
    expect(res.body.data.equipment).toHaveLength(2);
    expect(res.body.data.workoutSchedule.durationMinutes).toBe(30);
  });

  it('rotates the refresh token and invalidates the old one', async () => {
    const res = await request(app.getHttpServer())
      .post('/auth/refresh')
      .send({ refreshToken })
      .expect(200);

    const newRefreshToken = res.body.data.refreshToken;
    expect(newRefreshToken).toBeDefined();
    expect(newRefreshToken).not.toBe(refreshToken);

    // Reusing the rotated-out token must now fail.
    await request(app.getHttpServer()).post('/auth/refresh').send({ refreshToken }).expect(401);

    refreshToken = newRefreshToken;
    accessToken = res.body.data.accessToken;
  });

  it('rejects a malformed refresh token', async () => {
    await request(app.getHttpServer())
      .post('/auth/refresh')
      .send({ refreshToken: 'not-a-real-token' })
      .expect(401);
  });

  it('reusing a rotated-out token revokes the entire token family', async () => {
    const server = app.getHttpServer();

    const registerRes = await request(server)
      .post('/auth/register')
      .send({
        firstName: 'Riley',
        email: 'riley@example.com',
        password: 'Str0ngPass!',
        confirmPassword: 'Str0ngPass!',
        acceptedTerms: true,
      })
      .expect(201);

    const refreshGen1: string = registerRes.body.data.tokens.refreshToken;

    const rotate1 = await request(server)
      .post('/auth/refresh')
      .send({ refreshToken: refreshGen1 })
      .expect(200);
    const refreshGen2: string = rotate1.body.data.refreshToken;

    const rotate2 = await request(server)
      .post('/auth/refresh')
      .send({ refreshToken: refreshGen2 })
      .expect(200);
    const refreshGen3: string = rotate2.body.data.refreshToken;

    // Replaying the very first (long-since rotated-out) token is reuse of
    // a dead token — the whole lineage must be treated as compromised.
    await request(server).post('/auth/refresh').send({ refreshToken: refreshGen1 }).expect(401);

    // Proof of family-wide revocation: refreshGen3, which was still valid
    // and unused a moment ago, must now be rejected too.
    await request(server).post('/auth/refresh').send({ refreshToken: refreshGen3 }).expect(401);
  });

  let deviceId: string;

  it('creates a device connection', async () => {
    const res = await request(app.getHttpServer())
      .post('/devices')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ provider: 'APPLE_HEALTH', displayName: 'Apple Health' })
      .expect(201);
    expect(res.body.data.status).toBe('PENDING');
    deviceId = res.body.data.id;
  });

  it('lists device connections', async () => {
    const res = await request(app.getHttpServer())
      .get('/devices')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);
    expect(res.body.data).toHaveLength(1);
  });

  it('reconnecting the same provider upserts instead of duplicating', async () => {
    const reconnectRes = await request(app.getHttpServer())
      .post('/devices')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ provider: 'APPLE_HEALTH', displayName: 'Apple Health (reconnected)' })
      .expect(201);
    expect(reconnectRes.body.data.id).toBe(deviceId);
    expect(reconnectRes.body.data.displayName).toBe('Apple Health (reconnected)');

    const listRes = await request(app.getHttpServer())
      .get('/devices')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);
    expect(listRes.body.data).toHaveLength(1);
  });

  it('updates a device connection', async () => {
    const res = await request(app.getHttpServer())
      .patch(`/devices/${deviceId}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ status: 'CONNECTED' })
      .expect(200);
    expect(res.body.data.status).toBe('CONNECTED');
    expect(res.body.data.lastSyncedAt).toBeDefined();
  });

  it('deletes a device connection', async () => {
    await request(app.getHttpServer())
      .delete(`/devices/${deviceId}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    const res = await request(app.getHttpServer())
      .get('/devices')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);
    expect(res.body.data).toHaveLength(0);
  });

  it('logs out and revokes the refresh token', async () => {
    await request(app.getHttpServer()).post('/auth/logout').send({ refreshToken }).expect(200);
    await request(app.getHttpServer()).post('/auth/refresh').send({ refreshToken }).expect(401);
  });
});
