import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

describe('Admin foundation (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let tokenA: string;
  let userIdA: string;
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

    const a = await register('admin-a@example.com', 'Ada');
    tokenA = a.token;
    userIdA = a.id;

    const admin = await register('admin-staff@example.com', 'Staff');
    tokenAdmin = admin.token;
    // No self-service promotion endpoint exists this session (see
    // build-session-7.md Part 10) — an out-of-band DB write is the
    // only way to grant ADMIN, including in this test. Once ADMIN, the
    // specific permission grants below (Build Session 9 Part 19) are
    // what let this account actually use each admin surface exercised
    // in this file.
    await prisma.user.update({ where: { id: admin.id }, data: { role: 'ADMIN' } });
    await prisma.adminPermissionGrant.createMany({
      data: [
        { userId: admin.id, permission: 'MODERATE_COMMUNITY' },
        { userId: admin.id, permission: 'REVIEW_ELIGIBILITY' },
        { userId: admin.id, permission: 'MANAGE_SUPPORT' },
        { userId: admin.id, permission: 'REVIEW_TRAINER_VERIFICATION' },
      ],
    });
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  const authA = () => ({ Authorization: `Bearer ${tokenA}` });
  const authAdmin = () => ({ Authorization: `Bearer ${tokenAdmin}` });

  it('rejects a non-admin from every admin route', async () => {
    await request(app.getHttpServer()).get('/admin/community-reports').set(authA()).expect(403);
    await request(app.getHttpServer())
      .get('/admin/eligibility-applications')
      .set(authA())
      .expect(403);
    await request(app.getHttpServer()).get('/admin/support-tickets').set(authA()).expect(403);
  });

  describe('Community moderation queue', () => {
    let postId: string;
    let reportId: string;

    it('lists an OPEN report an admin can act on', async () => {
      const post = await request(app.getHttpServer())
        .post('/community/posts')
        .set(authA())
        .send({ caption: 'reported content' })
        .expect(201);
      postId = post.body.data.id as string;

      const report = await request(app.getHttpServer())
        .post('/community/reports')
        .set(authA())
        .send({ targetType: 'POST', targetId: postId, reason: 'spam' })
        .expect(201);
      reportId = report.body.data.id as string;

      const queue = await request(app.getHttpServer())
        .get('/admin/community-reports')
        .query({ status: 'OPEN' })
        .set(authAdmin())
        .expect(200);
      expect(queue.body.data.data.some((r: { id: string }) => r.id === reportId)).toBe(true);
    });

    it('rejects actioning a report back to OPEN', async () => {
      await request(app.getHttpServer())
        .patch(`/admin/community-reports/${reportId}`)
        .set(authAdmin())
        .send({ status: 'OPEN' })
        .expect(400);
    });

    it('actions the report and removes the post when removeContent is set', async () => {
      await request(app.getHttpServer())
        .patch(`/admin/community-reports/${reportId}`)
        .set(authAdmin())
        .send({ status: 'ACTIONED', removeContent: true })
        .expect(200);

      const post = await prisma.communityPost.findUnique({ where: { id: postId } });
      expect(post?.moderationStatus).toBe('REMOVED');
    });

    it('404s a made-up report id', async () => {
      await request(app.getHttpServer())
        .patch('/admin/community-reports/00000000-0000-0000-0000-000000000000')
        .set(authAdmin())
        .send({ status: 'REVIEWED' })
        .expect(404);
    });
  });

  describe('Affordability eligibility review', () => {
    it('lists a PENDING application and approves it', async () => {
      await request(app.getHttpServer())
        .post('/subscriptions/eligibility')
        .set(authA())
        .send({ program: 'STUDENT' })
        .expect(201);

      const queue = await request(app.getHttpServer())
        .get('/admin/eligibility-applications')
        .query({ status: 'PENDING' })
        .set(authAdmin())
        .expect(200);
      expect(queue.body.data.data.some((e: { userId: string }) => e.userId === userIdA)).toBe(true);

      await request(app.getHttpServer())
        .patch(`/admin/eligibility-applications/${userIdA}`)
        .set(authAdmin())
        .send({ status: 'APPROVED' })
        .expect(200);

      const status = await request(app.getHttpServer())
        .get('/subscriptions/me')
        .set(authA())
        .expect(200);
      expect(status.body.data.eligibility).toEqual({ program: 'STUDENT', status: 'APPROVED' });
    });

    it('rejects a decision of PENDING', async () => {
      await request(app.getHttpServer())
        .patch(`/admin/eligibility-applications/${userIdA}`)
        .set(authAdmin())
        .send({ status: 'PENDING' })
        .expect(400);
    });

    it('404s a user who never applied', async () => {
      await request(app.getHttpServer())
        .patch('/admin/eligibility-applications/00000000-0000-0000-0000-000000000000')
        .set(authAdmin())
        .send({ status: 'APPROVED' })
        .expect(404);
    });
  });

  describe('Trainer verification review (Build Session 12 Part 25-26)', () => {
    it('rejects an admin lacking REVIEW_TRAINER_VERIFICATION', async () => {
      await request(app.getHttpServer())
        .get('/admin/trainer-verification-applications')
        .set(authA())
        .expect(403);
    });

    it('applies, lists as PENDING, approves, and flips CommunityProfile.verifiedTrainer', async () => {
      await request(app.getHttpServer())
        .post('/community/trainer-verification')
        .set(authA())
        .send({ credentials: 'NASM-certified personal trainer, 5 years experience.' })
        .expect(201);

      const mine = await request(app.getHttpServer())
        .get('/community/trainer-verification/me')
        .set(authA())
        .expect(200);
      expect(mine.body.data.status).toBe('PENDING');

      const queue = await request(app.getHttpServer())
        .get('/admin/trainer-verification-applications')
        .query({ status: 'PENDING' })
        .set(authAdmin())
        .expect(200);
      expect(queue.body.data.data.some((a: { userId: string }) => a.userId === userIdA)).toBe(true);

      await request(app.getHttpServer())
        .post('/community/profile')
        .set(authA())
        .send({ displayName: 'Ada', isTrainer: true })
        .expect(201);

      await request(app.getHttpServer())
        .patch(`/admin/trainer-verification-applications/${userIdA}`)
        .set(authAdmin())
        .send({ status: 'APPROVED' })
        .expect(200);

      const profile = await request(app.getHttpServer())
        .get(`/community/profile/${userIdA}`)
        .set(authAdmin())
        .expect(200);
      expect(profile.body.data.verifiedTrainer).toBe(true);

      const events = await request(app.getHttpServer())
        .get('/notifications/events')
        .set(authA())
        .expect(200);
      expect(
        events.body.data.some((e: { type: string }) => e.type === 'TRAINER_VERIFICATION_UPDATE'),
      ).toBe(true);
    });

    it('rejects a decision of PENDING', async () => {
      await request(app.getHttpServer())
        .patch(`/admin/trainer-verification-applications/${userIdA}`)
        .set(authAdmin())
        .send({ status: 'PENDING' })
        .expect(400);
    });

    it('404s a user who never applied', async () => {
      await request(app.getHttpServer())
        .patch('/admin/trainer-verification-applications/00000000-0000-0000-0000-000000000000')
        .set(authAdmin())
        .send({ status: 'APPROVED' })
        .expect(404);
    });
  });

  describe('Support ticket queue', () => {
    it('lists an OPEN ticket, replies as staff, and resolves it', async () => {
      const created = await request(app.getHttpServer())
        .post('/support/tickets')
        .set(authA())
        .send({ category: 'BILLING_HELP', subject: 'Charged twice', message: 'Please help.' })
        .expect(201);
      const ticketId = created.body.data.id as string;

      const queue = await request(app.getHttpServer())
        .get('/admin/support-tickets')
        .query({ status: 'OPEN' })
        .set(authAdmin())
        .expect(200);
      expect(queue.body.data.data.some((t: { id: string }) => t.id === ticketId)).toBe(true);

      await request(app.getHttpServer())
        .patch(`/admin/support-tickets/${ticketId}/reply`)
        .set(authAdmin())
        .send({ body: "We've refunded the duplicate charge.", status: 'RESOLVED' })
        .expect(200);

      const detail = await request(app.getHttpServer())
        .get(`/support/tickets/${ticketId}`)
        .set(authA())
        .expect(200);
      expect(detail.body.data.status).toBe('RESOLVED');
      expect(detail.body.data.replies).toHaveLength(1);
      expect(detail.body.data.replies[0].isStaff).toBe(true);

      // Build Session 12 Part 2 — a status-changing reply notifies the
      // ticket owner, with no reply/subject content in the copy.
      const events = await request(app.getHttpServer())
        .get('/notifications/events')
        .set(authA())
        .expect(200);
      const ticketEvent = events.body.data.find(
        (e: { type: string; data: string | null }) =>
          e.type === 'SUPPORT_STATUS_CHANGED' && e.data === ticketId,
      );
      expect(ticketEvent).toBeDefined();
      expect(ticketEvent.body).not.toContain('refunded');
      expect(ticketEvent.body).not.toContain('Charged twice');
    });

    it('404s a made-up ticket id', async () => {
      await request(app.getHttpServer())
        .get('/admin/support-tickets/00000000-0000-0000-0000-000000000000')
        .set(authAdmin())
        .expect(404);
    });
  });
});
