import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

/**
 * Build Session 12 Part 9-11 — trainer workout assignments, scheduled
 * (date/time-based) group sessions, and the trainer dashboard. The
 * expanded (Premium) tier gate on scheduling mirrors
 * trainer-groups-expanded.e2e-spec.ts's pattern for announcements.
 */
describe('Trainer workout assignments, scheduled sessions, dashboard (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let ownerToken: string;
  let ownerId: string;
  let memberToken: string;
  let memberId: string;
  let outsiderToken: string;
  let groupId: string;
  let planId: string;

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

    const owner = await register('assign-owner@example.com', 'Tia');
    ownerToken = owner.token;
    ownerId = owner.id;
    await prisma.userSubscription.upsert({
      where: { userId: ownerId },
      update: { tier: 'PREMIUM' },
      create: { userId: ownerId, tier: 'PREMIUM' },
    });

    const member = await register('assign-member@example.com', 'Milo');
    memberToken = member.token;
    memberId = member.id;

    const outsider = await register('assign-outsider@example.com', 'Ozzy');
    outsiderToken = outsider.token;

    const group = await request(app.getHttpServer())
      .post('/trainer-groups')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ name: 'Assignment Squad' })
      .expect(201);
    groupId = group.body.data.id as string;

    const invite = await request(app.getHttpServer())
      .post(`/trainer-groups/${groupId}/invitations`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ inviteeUserId: memberId })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/trainer-groups/invitations/${invite.body.data.id}/accept`)
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(201);

    const exercises = await request(app.getHttpServer())
      .get('/exercises')
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    const pushUp = exercises.body.data.find((e: { slug: string }) => e.slug === 'push-up');

    const plan = await request(app.getHttpServer())
      .post('/workout-plans')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        name: 'Push Day',
        exercises: [{ exerciseId: pushUp.id, order: 1, targetSets: 3, targetReps: 12 }],
      })
      .expect(201);
    planId = plan.body.data.id as string;
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  let assignmentId: string;

  it('rejects a plain member creating an assignment', async () => {
    await request(app.getHttpServer())
      .post(`/trainer-groups/${groupId}/assignments`)
      .set('Authorization', `Bearer ${memberToken}`)
      .send({ workoutPlanId: planId, assigneeUserIds: [memberId] })
      .expect(403);
  });

  it('the owner assigns the plan to the member', async () => {
    const res = await request(app.getHttpServer())
      .post(`/trainer-groups/${groupId}/assignments`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ workoutPlanId: planId, assigneeUserIds: [memberId], note: 'Try this on Monday' })
      .expect(201);

    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].status).toBe('PENDING');
    expect(res.body.data[0].sourcePlanName).toBe('Push Day');
    assignmentId = res.body.data[0].id as string;
  });

  it('the member sees it in their own assignment list', async () => {
    const res = await request(app.getHttpServer())
      .get('/trainer-groups/assignments/mine')
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(200);
    expect(res.body.data.some((a: { id: string }) => a.id === assignmentId)).toBe(true);
  });

  it('rejects an outsider accepting the assignment', async () => {
    await request(app.getHttpServer())
      .post(`/trainer-groups/assignments/${assignmentId}/accept`)
      .set('Authorization', `Bearer ${outsiderToken}`)
      .expect(404);
  });

  let clonedPlanId: string;

  it('the member accepts, cloning the plan into their own workout plans', async () => {
    const res = await request(app.getHttpServer())
      .post(`/trainer-groups/assignments/${assignmentId}/accept`)
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(201);
    clonedPlanId = res.body.data.workoutPlanId as string;

    const plan = await request(app.getHttpServer())
      .get(`/workout-plans/${clonedPlanId}`)
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(200);
    expect(plan.body.data.name).toBe('Push Day');
    expect(plan.body.data.exercises).toHaveLength(1);
  });

  it('rejects accepting the same assignment twice', async () => {
    await request(app.getHttpServer())
      .post(`/trainer-groups/assignments/${assignmentId}/accept`)
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(409);
  });

  it('completing a session against the cloned plan auto-completes the assignment', async () => {
    const started = await request(app.getHttpServer())
      .post('/workout-sessions')
      .set('Authorization', `Bearer ${memberToken}`)
      .send({ workoutPlanId: clonedPlanId })
      .expect(201);
    const sessionId = started.body.data.id as string;

    await request(app.getHttpServer())
      .post(`/workout-sessions/${sessionId}/finish`)
      .set('Authorization', `Bearer ${memberToken}`)
      .send({})
      .expect(200);

    const mine = await request(app.getHttpServer())
      .get('/trainer-groups/assignments/mine')
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(200);
    const completed = mine.body.data.find((a: { id: string }) => a.id === assignmentId);
    expect(completed.status).toBe('COMPLETED');
  });

  it('the owner sees the same assignment in the group view', async () => {
    const res = await request(app.getHttpServer())
      .get(`/trainer-groups/${groupId}/assignments`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    expect(res.body.data.some((a: { id: string }) => a.id === assignmentId)).toBe(true);
  });

  // --- Scheduled sessions --------------------------------------------------

  let sessionScheduleId: string;

  it('rejects a free-tier owner scheduling a session', async () => {
    const freeOwner = await register('assign-free-owner@example.com', 'Finn');
    const freeGroup = await request(app.getHttpServer())
      .post('/trainer-groups')
      .set('Authorization', `Bearer ${freeOwner.token}`)
      .send({ name: 'Free Squad' })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/trainer-groups/${freeGroup.body.data.id}/scheduled-sessions`)
      .set('Authorization', `Bearer ${freeOwner.token}`)
      .send({ scheduledAt: new Date(Date.now() + 86_400_000).toISOString() })
      .expect(403);
  });

  it('the Premium owner schedules a session for the group', async () => {
    const res = await request(app.getHttpServer())
      .post(`/trainer-groups/${groupId}/scheduled-sessions`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({
        scheduledAt: new Date(Date.now() + 86_400_000).toISOString(),
        title: 'Group HIIT',
        durationMinutes: 45,
        videoLink: 'https://example.com/meet',
      })
      .expect(201);
    expect(res.body.data.title).toBe('Group HIIT');
    sessionScheduleId = res.body.data.id as string;
  });

  it('the member can see the scheduled session', async () => {
    const res = await request(app.getHttpServer())
      .get(`/trainer-groups/${groupId}/scheduled-sessions`)
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(200);
    expect(res.body.data.some((s: { id: string }) => s.id === sessionScheduleId)).toBe(true);
  });

  it('rejects an outsider canceling the scheduled session', async () => {
    await request(app.getHttpServer())
      .delete(`/trainer-groups/scheduled-sessions/${sessionScheduleId}`)
      .set('Authorization', `Bearer ${outsiderToken}`)
      .expect(403);
  });

  it('the owner cancels the scheduled session', async () => {
    await request(app.getHttpServer())
      .delete(`/trainer-groups/scheduled-sessions/${sessionScheduleId}`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(204);

    const res = await request(app.getHttpServer())
      .get(`/trainer-groups/${groupId}/scheduled-sessions`)
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(200);
    expect(res.body.data.some((s: { id: string }) => s.id === sessionScheduleId)).toBe(false);
  });

  // --- Trainer dashboard -----------------------------------------------

  it("the owner's dashboard reflects the group's member count", async () => {
    const res = await request(app.getHttpServer())
      .get('/trainer-groups/dashboard')
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    const entry = res.body.data.groups.find((g: { id: string }) => g.id === groupId);
    expect(entry).toBeDefined();
    expect(entry.memberCount).toBe(2);
  });

  it("a plain member's dashboard has no owned/moderated groups", async () => {
    const res = await request(app.getHttpServer())
      .get('/trainer-groups/dashboard')
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(200);
    expect(res.body.data.groups).toEqual([]);
  });
});
