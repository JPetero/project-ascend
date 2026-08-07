import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

describe('Ascend Promote (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let tokenCreator: string;
  let tokenViewer: string;
  let tokenAdmin: string;

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

    const creator = await register('promote-creator@example.com', 'Cara');
    tokenCreator = creator.token;

    const viewer = await register('promote-viewer@example.com', 'Vic');
    tokenViewer = viewer.token;

    const admin = await register('promote-admin@example.com', 'Staff');
    tokenAdmin = admin.token;
    await prisma.user.update({ where: { id: admin.id }, data: { role: 'ADMIN' } });

    // No live billing exists this session — promoting to PREMIUM is an
    // out-of-band DB write, same pattern as admin.e2e-spec.ts's role
    // promotion.
    await prisma.userSubscription.upsert({
      where: { userId: creator.id },
      update: { tier: 'PREMIUM' },
      create: { userId: creator.id, tier: 'PREMIUM' },
    });
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  const authCreator = () => ({ Authorization: `Bearer ${tokenCreator}` });
  const authViewer = () => ({ Authorization: `Bearer ${tokenViewer}` });
  const authAdmin = () => ({ Authorization: `Bearer ${tokenAdmin}` });

  let postId: string;
  let campaignId: string;

  it('rejects creating a campaign without Ascend Promote (Premium) entitlement', async () => {
    const post = await request(app.getHttpServer())
      .post('/community/posts')
      .set(authViewer())
      .send({ caption: 'not premium yet' })
      .expect(201);

    await request(app.getHttpServer())
      .post('/promote/campaigns')
      .set(authViewer())
      .send({ postId: post.body.data.id, budgetAmount: 50, budgetCurrency: 'usd' })
      .expect(403);
  });

  it('creates a PENDING_REVIEW campaign for a Premium post owner', async () => {
    const post = await request(app.getHttpServer())
      .post('/community/posts')
      .set(authCreator())
      .send({ caption: 'Check out my new program' })
      .expect(201);
    postId = post.body.data.id as string;

    const created = await request(app.getHttpServer())
      .post('/promote/campaigns')
      .set(authCreator())
      .send({ postId, budgetAmount: 50, budgetCurrency: 'usd' })
      .expect(201);
    campaignId = created.body.data.id as string;

    expect(created.body.data.status).toBe('PENDING_REVIEW');
    expect(created.body.data.budgetCurrency).toBe('USD');
  });

  it('rejects promoting a post the caller does not own', async () => {
    await request(app.getHttpServer())
      .post('/promote/campaigns')
      .set(authViewer())
      .send({ postId, budgetAmount: 10, budgetCurrency: 'usd' })
      .expect(403);
  });

  it('never serves an impression for a PENDING_REVIEW campaign', async () => {
    const res = await request(app.getHttpServer())
      .post(`/promote/campaigns/${campaignId}/impression`)
      .set(authViewer())
      .expect(200);
    expect(res.body.data).toEqual({ recorded: false });
  });

  it('lists the PENDING_REVIEW campaign in the admin queue', async () => {
    const queue = await request(app.getHttpServer())
      .get('/admin/promoted-campaigns')
      .query({ status: 'PENDING_REVIEW' })
      .set(authAdmin())
      .expect(200);
    expect(queue.body.data.data.some((c: { id: string }) => c.id === campaignId)).toBe(true);
  });

  it('rejects a review decision that is not ACTIVE or REJECTED', async () => {
    await request(app.getHttpServer())
      .patch(`/admin/promoted-campaigns/${campaignId}`)
      .set(authAdmin())
      .send({ status: 'PENDING_REVIEW' })
      .expect(400);
  });

  it('activates the campaign', async () => {
    const decided = await request(app.getHttpServer())
      .patch(`/admin/promoted-campaigns/${campaignId}`)
      .set(authAdmin())
      .send({ status: 'ACTIVE' })
      .expect(200);
    expect(decided.body.data.status).toBe('ACTIVE');
  });

  it('rejects re-reviewing a campaign that already left PENDING_REVIEW', async () => {
    await request(app.getHttpServer())
      .patch(`/admin/promoted-campaigns/${campaignId}`)
      .set(authAdmin())
      .send({ status: 'REJECTED' })
      .expect(400);
  });

  it('records impressions up to the daily frequency cap, then suppresses further ones', async () => {
    for (let i = 0; i < 3; i++) {
      const res = await request(app.getHttpServer())
        .post(`/promote/campaigns/${campaignId}/impression`)
        .set(authViewer())
        .expect(200);
      expect(res.body.data).toEqual({ recorded: true });
    }

    const capped = await request(app.getHttpServer())
      .post(`/promote/campaigns/${campaignId}/impression`)
      .set(authViewer())
      .expect(200);
    expect(capped.body.data).toEqual({ recorded: false });
  });

  it('records a click on an ACTIVE campaign', async () => {
    const res = await request(app.getHttpServer())
      .post(`/promote/campaigns/${campaignId}/click`)
      .set(authViewer())
      .expect(200);
    expect(res.body.data).toEqual({ recorded: true });
  });

  it('reports organic and promoted metrics as two separate, never-blended objects', async () => {
    await request(app.getHttpServer())
      .post(`/community/posts/${postId}/like`)
      .set(authViewer())
      .expect(204);

    const metrics = await request(app.getHttpServer())
      .get(`/promote/campaigns/${campaignId}/metrics`)
      .set(authCreator())
      .expect(200);

    expect(metrics.body.data.organic).toEqual({ likes: 1, comments: 0 });
    expect(metrics.body.data.promoted).toEqual({ impressions: 3, clicks: 1 });
  });

  it("a promoted post's paid impressions and clicks never contribute to Rankings", async () => {
    await request(app.getHttpServer())
      .put('/rankings/opt-in')
      .set(authViewer())
      .send({ scope: 'GLOBAL' })
      .expect(200);

    const status = await request(app.getHttpServer())
      .get('/rankings/me')
      .set(authViewer())
      .expect(200);

    // The viewer generated three impressions and a click above but
    // logged zero workouts/cardio/meals — if promoted engagement ever
    // leaked into Ranking scoring this would be nonzero.
    expect(status.body.data.points).toBe(0);
    expect(status.body.data.activeDays).toBe(0);
  });

  it("404s a campaign's metrics for someone who isn't its creator", async () => {
    await request(app.getHttpServer())
      .get(`/promote/campaigns/${campaignId}/metrics`)
      .set(authViewer())
      .expect(404);
  });

  it('404s reviewing a made-up campaign id', async () => {
    await request(app.getHttpServer())
      .patch('/admin/promoted-campaigns/00000000-0000-0000-0000-000000000000')
      .set(authAdmin())
      .send({ status: 'ACTIVE' })
      .expect(404);
  });

  it('ends the campaign, after which it never serves another impression', async () => {
    await request(app.getHttpServer())
      .delete(`/promote/campaigns/${campaignId}`)
      .set(authCreator())
      .expect(204);

    const res = await request(app.getHttpServer())
      .post(`/promote/campaigns/${campaignId}/impression`)
      .set(authViewer())
      .expect(200);
    expect(res.body.data).toEqual({ recorded: false });
  });

  it("404s ending someone else's campaign, and rejects a non-admin from the review queue", async () => {
    await request(app.getHttpServer())
      .delete(`/promote/campaigns/${campaignId}`)
      .set(authViewer())
      .expect(404);
    await request(app.getHttpServer())
      .get('/admin/promoted-campaigns')
      .set(authViewer())
      .expect(403);
  });
});
