import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

describe('Data Export (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let tokenA: string;
  let tokenB: string;

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
      return res.body.data.tokens.accessToken as string;
    };

    tokenA = await register('export-a@example.com', 'Ada');
    tokenB = await register('export-b@example.com', 'Bea');
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  function authFor(token: string) {
    return { Authorization: `Bearer ${token}` };
  }

  it("includes the caller's own account and nutrition data", async () => {
    await request(app.getHttpServer())
      .post('/water')
      .set(authFor(tokenA))
      .send({ date: '2026-01-01', amountMl: 500 })
      .expect(201);

    const res = await request(app.getHttpServer())
      .get('/account/data-export')
      .set(authFor(tokenA))
      .expect(200);

    expect(res.body.data.account.email).toBe('export-a@example.com');
    expect(res.body.data.account).not.toHaveProperty('passwordHash');
    expect(res.body.data.nutrition.waterEntries).toHaveLength(1);
    expect(res.body.data.nutrition.waterEntries[0].amountMl).toBe(500);
    expect(res.body.data.exportedAt).toBeDefined();
  });

  it("never includes another user's data", async () => {
    await request(app.getHttpServer())
      .post('/water')
      .set(authFor(tokenB))
      .send({ date: '2026-01-01', amountMl: 750 })
      .expect(201);

    const resA = await request(app.getHttpServer())
      .get('/account/data-export')
      .set(authFor(tokenA))
      .expect(200);

    const amounts = (resA.body.data.nutrition.waterEntries as Array<{ amountMl: number }>).map(
      (e) => e.amountMl,
    );
    expect(amounts).not.toContain(750);
  });

  it('rejects an unauthenticated request', async () => {
    await request(app.getHttpServer()).get('/account/data-export').expect(401);
  });
});
