import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

/**
 * Build Session 9 Part 20 — Trainer Groups expanded (Premium) tier:
 * larger limits, the MODERATOR role, and announcements, all gated on
 * the group owner's TRAINER_GROUPS_EXPANDED capability. "Premium" here
 * is a real out-of-band UserSubscription write, same pattern as
 * promote.e2e-spec.ts — no live billing exists in this environment
 * (see build-session-9.md).
 */
describe('Trainer groups — expanded tier (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let ownerToken: string;
  let ownerId: string;
  let memberToken: string;
  let memberId: string;
  let groupId: string;

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

    const owner = await register('expanded-owner@example.com', 'Owen');
    ownerToken = owner.token;
    ownerId = owner.id;
    await prisma.userSubscription.upsert({
      where: { userId: ownerId },
      update: { tier: 'PREMIUM' },
      create: { userId: ownerId, tier: 'PREMIUM' },
    });

    const member = await register('expanded-member@example.com', 'Mo');
    memberToken = member.token;
    memberId = member.id;

    const group = await request(app.getHttpServer())
      .post('/trainer-groups')
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ name: 'Premium Squad' })
      .expect(201);
    groupId = group.body.data.id as string;
    expect(group.body.data.isExpanded).toBe(true);

    const invite = await request(app.getHttpServer())
      .post(`/trainer-groups/${groupId}/invitations`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ inviteeUserId: memberId })
      .expect(201);
    const invitationId = invite.body.data.id as string;
    await request(app.getHttpServer())
      .post(`/trainer-groups/invitations/${invitationId}/accept`)
      .set('Authorization', `Bearer ${memberToken}`)
      .expect(201);
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  it("reports a higher member limit on a Premium owner's group", async () => {
    const res = await request(app.getHttpServer())
      .get(`/trainer-groups/${groupId}`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    expect(res.body.data.memberLimit).toBeGreaterThan(5);
  });

  it('rejects a non-owner promoting a member to moderator', async () => {
    await request(app.getHttpServer())
      .patch(`/trainer-groups/${groupId}/members/${memberId}/role`)
      .set('Authorization', `Bearer ${memberToken}`)
      .send({ role: 'MODERATOR' })
      .expect(403);
  });

  it('rejects an announcement before the member is a moderator', async () => {
    await request(app.getHttpServer())
      .post(`/trainer-groups/${groupId}/announcements`)
      .set('Authorization', `Bearer ${memberToken}`)
      .send({ body: 'Not allowed yet' })
      .expect(403);
  });

  it('the owner promotes the member to MODERATOR', async () => {
    const res = await request(app.getHttpServer())
      .patch(`/trainer-groups/${groupId}/members/${memberId}/role`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .send({ role: 'MODERATOR' })
      .expect(200);
    expect(res.body.data.role).toBe('MODERATOR');
  });

  it('the new moderator can invite a member and post an announcement', async () => {
    const another = await register('expanded-invitee@example.com', 'Ivy');

    await request(app.getHttpServer())
      .post(`/trainer-groups/${groupId}/invitations`)
      .set('Authorization', `Bearer ${memberToken}`)
      .send({ inviteeUserId: another.id })
      .expect(201);

    const announcement = await request(app.getHttpServer())
      .post(`/trainer-groups/${groupId}/announcements`)
      .set('Authorization', `Bearer ${memberToken}`)
      .send({ body: 'Squad meetup Saturday!' })
      .expect(201);
    expect(announcement.body.data.body).toBe('Squad meetup Saturday!');

    const list = await request(app.getHttpServer())
      .get(`/trainer-groups/${groupId}/announcements`)
      .set('Authorization', `Bearer ${ownerToken}`)
      .expect(200);
    expect(list.body.data.some((a: { id: string }) => a.id === announcement.body.data.id)).toBe(
      true,
    );
  });

  it('rejects announcements and expanded roles on a free-tier owner’s group', async () => {
    const freeOwner = await register('free-owner@example.com', 'Fran');
    const group = await request(app.getHttpServer())
      .post('/trainer-groups')
      .set('Authorization', `Bearer ${freeOwner.token}`)
      .send({ name: 'Free Squad' })
      .expect(201);
    expect(group.body.data.isExpanded).toBe(false);
    expect(group.body.data.memberLimit).toBe(5);

    await request(app.getHttpServer())
      .post(`/trainer-groups/${group.body.data.id}/announcements`)
      .set('Authorization', `Bearer ${freeOwner.token}`)
      .send({ body: 'Should fail' })
      .expect(403);
  });

  describe('scheduled sessions (Build Session 10 Part 24)', () => {
    it(
      'the owner schedules a joint workout session for the whole group, ' +
        'without either party needing to already be Friends',
      async () => {
        const created = await request(app.getHttpServer())
          .post('/joint-workouts')
          .set('Authorization', `Bearer ${ownerToken}`)
          .send({ title: 'Saturday squad session', trainerGroupId: groupId })
          .expect(201);

        expect(created.body.data.hostId).toBe(ownerId);
        const participantIds = (created.body.data.participants as { userId: string }[]).map(
          (p) => p.userId,
        );
        expect(participantIds).toContain(ownerId);
        expect(participantIds).toContain(memberId);

        // The invited member can see and accept it despite never having
        // gone through the Friends flow with the owner.
        const seenByMember = await request(app.getHttpServer())
          .get(`/joint-workouts/${created.body.data.id}`)
          .set('Authorization', `Bearer ${memberToken}`)
          .expect(200);
        expect(seenByMember.body.data.id).toBe(created.body.data.id);

        await request(app.getHttpServer())
          .post(`/joint-workouts/${created.body.data.id}/accept`)
          .set('Authorization', `Bearer ${memberToken}`)
          .expect(201);
      },
    );

    it('rejects a regular member scheduling a session for the group', async () => {
      const another = await register('expanded-nonmod@example.com', 'Nia');
      const invite = await request(app.getHttpServer())
        .post(`/trainer-groups/${groupId}/invitations`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({ inviteeUserId: another.id })
        .expect(201);
      await request(app.getHttpServer())
        .post(`/trainer-groups/invitations/${invite.body.data.id}/accept`)
        .set('Authorization', `Bearer ${another.token}`)
        .expect(201);

      await request(app.getHttpServer())
        .post('/joint-workouts')
        .set('Authorization', `Bearer ${another.token}`)
        .send({ trainerGroupId: groupId })
        .expect(403);
    });

    it('rejects scheduling for a free-tier owner’s group', async () => {
      const freeOwner = await register('free-owner-sessions@example.com', 'Faye');
      const group = await request(app.getHttpServer())
        .post('/trainer-groups')
        .set('Authorization', `Bearer ${freeOwner.token}`)
        .send({ name: 'Free Squad Sessions' })
        .expect(201);

      await request(app.getHttpServer())
        .post('/joint-workouts')
        .set('Authorization', `Bearer ${freeOwner.token}`)
        .send({ trainerGroupId: group.body.data.id })
        .expect(403);
    });

    it('rejects passing both inviteeIds and trainerGroupId', async () => {
      await request(app.getHttpServer())
        .post('/joint-workouts')
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({ trainerGroupId: groupId, inviteeIds: [memberId] })
        .expect(400);
    });
  });

  describe('scheduled session RSVP (Build Session 13 Part 3)', () => {
    let sessionId: string;
    let workoutPlanId: string;

    beforeAll(async () => {
      const plan = await request(app.getHttpServer())
        .post('/workout-plans')
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({ name: "Owen's Squad Plan" })
        .expect(201);
      workoutPlanId = plan.body.data.id as string;

      const created = await request(app.getHttpServer())
        .post(`/trainer-groups/${groupId}/scheduled-sessions`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({
          title: 'Saturday session',
          scheduledAt: new Date(Date.now() + 86_400_000).toISOString(),
          workoutPlanId,
        })
        .expect(201);
      sessionId = created.body.data.id as string;
      expect(created.body.data.workoutPlanName).toBe("Owen's Squad Plan");
      expect(created.body.data.status).toBe('UPCOMING');
      expect(created.body.data.goingCount).toBe(0);
    });

    it('a member RSVPs Going and the count is reflected for both viewers', async () => {
      const rsvp = await request(app.getHttpServer())
        .post(`/trainer-groups/scheduled-sessions/${sessionId}/rsvp`)
        .set('Authorization', `Bearer ${memberToken}`)
        .send({ status: 'GOING' })
        .expect(201);
      expect(rsvp.body.data.goingCount).toBe(1);
      expect(rsvp.body.data.viewerRsvpStatus).toBe('GOING');

      const listedForOwner = await request(app.getHttpServer())
        .get(`/trainer-groups/${groupId}/scheduled-sessions`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .expect(200);
      const seenByOwner = (
        listedForOwner.body.data as { id: string; goingCount: number; viewerRsvpStatus: null }[]
      ).find((s) => s.id === sessionId)!;
      expect(seenByOwner.goingCount).toBe(1);
      expect(seenByOwner.viewerRsvpStatus).toBeNull();
    });

    it('changes the RSVP to Maybe and moves the count between buckets', async () => {
      const rsvp = await request(app.getHttpServer())
        .post(`/trainer-groups/scheduled-sessions/${sessionId}/rsvp`)
        .set('Authorization', `Bearer ${memberToken}`)
        .send({ status: 'MAYBE' })
        .expect(201);
      expect(rsvp.body.data.goingCount).toBe(0);
      expect(rsvp.body.data.maybeCount).toBe(1);
      expect(rsvp.body.data.viewerRsvpStatus).toBe('MAYBE');
    });

    it('canceling the RSVP returns to the unresponded state', async () => {
      const canceled = await request(app.getHttpServer())
        .delete(`/trainer-groups/scheduled-sessions/${sessionId}/rsvp`)
        .set('Authorization', `Bearer ${memberToken}`)
        .expect(200);
      expect(canceled.body.data.maybeCount).toBe(0);
      expect(canceled.body.data.viewerRsvpStatus).toBeNull();
    });

    it('rejects a non-member RSVPing', async () => {
      const outsider = await register('rsvp-outsider@example.com', 'Ola');
      await request(app.getHttpServer())
        .post(`/trainer-groups/scheduled-sessions/${sessionId}/rsvp`)
        .set('Authorization', `Bearer ${outsider.token}`)
        .send({ status: 'GOING' })
        .expect(404);
    });

    it('canceling the session notifies members and further RSVPs are rejected', async () => {
      const secondSession = await request(app.getHttpServer())
        .post(`/trainer-groups/${groupId}/scheduled-sessions`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .send({ scheduledAt: new Date(Date.now() + 172_800_000).toISOString() })
        .expect(201);
      const secondSessionId = secondSession.body.data.id as string;

      await request(app.getHttpServer())
        .delete(`/trainer-groups/scheduled-sessions/${secondSessionId}`)
        .set('Authorization', `Bearer ${ownerToken}`)
        .expect(204);

      await request(app.getHttpServer())
        .post(`/trainer-groups/scheduled-sessions/${secondSessionId}/rsvp`)
        .set('Authorization', `Bearer ${memberToken}`)
        .send({ status: 'GOING' })
        .expect(409);

      const notifications = await request(app.getHttpServer())
        .get('/notifications/events')
        .set('Authorization', `Bearer ${memberToken}`)
        .expect(200);
      const types = (notifications.body.data as { type: string }[]).map((n) => n.type);
      expect(types).toContain('GROUP_SESSION_CANCELED');
    });
  });
});
