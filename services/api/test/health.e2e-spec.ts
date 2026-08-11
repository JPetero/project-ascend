import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

/**
 * S14 Part 6 — liveness/readiness split. No auth required (both are
 * `@Public()`); this suite only proves the happy path against a real,
 * reachable database — simulating a real outage isn't practical in
 * this harness, and is covered by health.controller.spec.ts's mocked
 * unit tests instead.
 */
describe('Health endpoints (e2e)', () => {
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

  it('GET /livez reports ok without requiring authentication', async () => {
    const res = await request(app.getHttpServer()).get('/livez').expect(200);

    expect(res.body.data).toMatchObject({ status: 'ok' });
  });

  it('GET /readyz reports ok against a real reachable database', async () => {
    const res = await request(app.getHttpServer()).get('/readyz').expect(200);

    expect(res.body.data).toMatchObject({ status: 'ok' });
  });

  it('GET /health (legacy alias) still reports ok, unchanged behavior', async () => {
    const res = await request(app.getHttpServer()).get('/health').expect(200);

    expect(res.body.data).toMatchObject({ status: 'ok' });
  });
});
