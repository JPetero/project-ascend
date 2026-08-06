import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

describe('Health Connect/HealthKit foundation (e2e)', () => {
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

    const register = await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        firstName: 'Hana',
        email: 'health-metrics@example.com',
        password: 'Str0ngPass!',
        confirmPassword: 'Str0ngPass!',
        acceptedTerms: true,
      })
      .expect(201);
    token = register.body.data.tokens.accessToken;
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  const auth = () => ({ Authorization: `Bearer ${token}` });

  it('syncs samples, deduplicates a re-sync, and advances the sync cursor', async () => {
    const samples = [
      { metric: 'STEPS', value: 4200, unit: 'count', recordedAt: '2026-08-06T08:00:00.000Z' },
      { metric: 'STEPS', value: 5100, unit: 'count', recordedAt: '2026-08-06T12:00:00.000Z' },
      { metric: 'HEART_RATE', value: 68, unit: 'bpm', recordedAt: '2026-08-06T08:00:00.000Z' },
    ];

    const first = await request(app.getHttpServer())
      .post('/health-metrics/sync')
      .set(auth())
      .send({ provider: 'HEALTH_CONNECT', samples })
      .expect(201);

    expect(first.body.data.samplesAdded).toBe(3);
    expect(first.body.data.samplesSkipped).toBe(0);
    expect(first.body.data.nextCursor.STEPS).toBe('2026-08-06T12:00:00.000Z');

    // Re-syncing the exact same samples (an overlapping incremental
    // window, or a client retry) must not create duplicates.
    const second = await request(app.getHttpServer())
      .post('/health-metrics/sync')
      .set(auth())
      .send({ provider: 'HEALTH_CONNECT', samples })
      .expect(201);

    expect(second.body.data.samplesAdded).toBe(0);
    expect(second.body.data.samplesSkipped).toBe(3);

    const list = await request(app.getHttpServer())
      .get('/health-metrics/samples')
      .query({ metric: 'STEPS' })
      .set(auth())
      .expect(200);
    expect(list.body.data.data).toHaveLength(2);

    const status = await request(app.getHttpServer())
      .get('/health-metrics/sync-status')
      .set(auth())
      .expect(200);
    const providers = status.body.data.data.map((c: { provider: string }) => c.provider);
    expect(providers).toContain('HEALTH_CONNECT');
  });

  it('filters samples by date range', async () => {
    await request(app.getHttpServer())
      .post('/health-metrics/sync')
      .set(auth())
      .send({
        provider: 'APPLE_HEALTH',
        samples: [
          {
            metric: 'ACTIVE_CALORIES',
            value: 300,
            unit: 'kcal',
            recordedAt: '2026-08-01T08:00:00.000Z',
          },
          {
            metric: 'ACTIVE_CALORIES',
            value: 450,
            unit: 'kcal',
            recordedAt: '2026-08-05T08:00:00.000Z',
          },
        ],
      })
      .expect(201);

    const list = await request(app.getHttpServer())
      .get('/health-metrics/samples')
      .query({
        metric: 'ACTIVE_CALORIES',
        from: '2026-08-04T00:00:00.000Z',
        to: '2026-08-06T00:00:00.000Z',
      })
      .set(auth())
      .expect(200);

    expect(list.body.data.data).toHaveLength(1);
    expect(list.body.data.data[0].value).toBe(450);
  });

  it('rejects a sync payload over the sample-count limit', async () => {
    const tooMany = Array.from({ length: 5001 }, (_, i) => ({
      metric: 'STEPS',
      value: 1,
      unit: 'count',
      recordedAt: new Date(2026, 0, 1, 0, 0, i).toISOString(),
    }));

    // The batch is large enough to be rejected by the request body size
    // limit before Nest's own ArrayMaxSize(5000) validation ever runs —
    // still a client (4xx) error, not a server one.
    await request(app.getHttpServer())
      .post('/health-metrics/sync')
      .set(auth())
      .send({ provider: 'HEALTH_CONNECT', samples: tooMany })
      .expect(413);
  });

  it('disconnecting a device clears that provider’s sync cursor', async () => {
    await request(app.getHttpServer())
      .post('/health-metrics/sync')
      .set(auth())
      .send({
        provider: 'HEALTH_CONNECT',
        samples: [
          {
            metric: 'DISTANCE',
            value: 500,
            unit: 'meters',
            recordedAt: '2026-08-06T08:00:00.000Z',
          },
        ],
      })
      .expect(201);

    const device = await request(app.getHttpServer())
      .post('/devices')
      .set(auth())
      .send({
        provider: 'HEALTH_CONNECT',
        displayName: 'Pixel',
        status: 'CONNECTED',
      })
      .expect(201);

    await request(app.getHttpServer())
      .delete(`/devices/${device.body.data.id}`)
      .set(auth())
      .expect(200);

    const status = await request(app.getHttpServer())
      .get('/health-metrics/sync-status')
      .set(auth())
      .expect(200);
    const healthConnectCursors = status.body.data.data.filter(
      (c: { provider: string }) => c.provider === 'HEALTH_CONNECT',
    );
    expect(healthConnectCursors).toHaveLength(0);
  });

  it('the liveness check at GET /health is unaffected by the health-metrics module', async () => {
    const res = await request(app.getHttpServer()).get('/health').expect(200);
    expect(res.body.data.status).toBe('ok');
  });
});
