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
});
