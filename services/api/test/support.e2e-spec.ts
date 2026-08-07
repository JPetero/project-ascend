import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

describe('Support tickets (e2e)', () => {
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

    tokenA = await register('support-a@example.com', 'Ada');
    tokenB = await register('support-b@example.com', 'Bea');
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  const authA = () => ({ Authorization: `Bearer ${tokenA}` });
  const authB = () => ({ Authorization: `Bearer ${tokenB}` });

  it('creates a ticket and lists it for the owner', async () => {
    const created = await request(app.getHttpServer())
      .post('/support/tickets')
      .set(authA())
      .send({
        category: 'BUG_REPORT',
        subject: 'App crashes on save',
        message: 'Steps to repro...',
      })
      .expect(201);
    expect(created.body.data.status).toBe('OPEN');

    const mine = await request(app.getHttpServer())
      .get('/support/tickets')
      .set(authA())
      .expect(200);
    expect(mine.body.data).toHaveLength(1);
  });

  it('every support category is free — no capability check ever blocks creation', async () => {
    const categories = [
      'GENERAL',
      'SAFETY_REPORT',
      'ACCESSIBILITY_FEEDBACK',
      'ACCOUNT_RECOVERY',
      'BILLING_HELP',
      'MODERATION_APPEAL',
    ];
    for (const category of categories) {
      await request(app.getHttpServer())
        .post('/support/tickets')
        .set(authA())
        .send({ category, subject: `${category} ticket`, message: 'Details.' })
        .expect(201);
    }
  });

  it('adds a reply and returns it with the ticket', async () => {
    const mine = await request(app.getHttpServer())
      .get('/support/tickets')
      .set(authA())
      .expect(200);
    const ticketId = mine.body.data[0].id as string;

    await request(app.getHttpServer())
      .post(`/support/tickets/${ticketId}/replies`)
      .set(authA())
      .send({ body: 'Any update?' })
      .expect(201);

    const detail = await request(app.getHttpServer())
      .get(`/support/tickets/${ticketId}`)
      .set(authA())
      .expect(200);
    expect(detail.body.data.replies).toHaveLength(1);
    expect(detail.body.data.replies[0].isStaff).toBe(false);
  });

  it('404s a ticket that belongs to someone else, never revealing it exists', async () => {
    const mine = await request(app.getHttpServer())
      .get('/support/tickets')
      .set(authA())
      .expect(200);
    const ticketId = mine.body.data[0].id as string;

    await request(app.getHttpServer()).get(`/support/tickets/${ticketId}`).set(authB()).expect(404);
    await request(app.getHttpServer())
      .post(`/support/tickets/${ticketId}/replies`)
      .set(authB())
      .send({ body: 'not mine' })
      .expect(404);
  });

  it('404s a made-up ticket id', async () => {
    await request(app.getHttpServer())
      .get('/support/tickets/00000000-0000-0000-0000-000000000000')
      .set(authA())
      .expect(404);
  });
});
