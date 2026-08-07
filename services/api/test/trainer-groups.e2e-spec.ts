import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

describe('Trainer groups messaging MVP (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let tokenA: string;
  let tokenB: string;
  let tokenC: string;
  let tokenD: string;
  let tokenE: string;
  let tokenF: string;
  let userIdA: string;
  let userIdB: string;
  let userIdC: string;
  let userIdD: string;
  let userIdE: string;
  let userIdF: string;

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

    const [a, b, c, d, e, f] = await Promise.all([
      register('tg-a@example.com', 'Ada'),
      register('tg-b@example.com', 'Bea'),
      register('tg-c@example.com', 'Cid'),
      register('tg-d@example.com', 'Dee'),
      register('tg-e@example.com', 'Eli'),
      register('tg-f@example.com', 'Fay'),
    ]);
    tokenA = a.token;
    tokenB = b.token;
    tokenC = c.token;
    tokenD = d.token;
    tokenE = e.token;
    tokenF = f.token;
    userIdA = a.id;
    userIdB = b.id;
    userIdC = c.id;
    userIdD = d.id;
    userIdE = e.id;
    userIdF = f.id;
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  const authA = () => ({ Authorization: `Bearer ${tokenA}` });
  const authB = () => ({ Authorization: `Bearer ${tokenB}` });
  const authC = () => ({ Authorization: `Bearer ${tokenC}` });
  const authF = () => ({ Authorization: `Bearer ${tokenF}` });

  it('creates a group with the owner auto-added as OWNER', async () => {
    const created = await request(app.getHttpServer())
      .post('/trainer-groups')
      .set(authA())
      .send({ name: 'Morning Crew', description: 'We lift at 6am' })
      .expect(201);

    expect(created.body.data.name).toBe('Morning Crew');
    expect(created.body.data.isOwnGroup).toBe(true);
    expect(created.body.data.members).toHaveLength(1);
    expect(created.body.data.members[0]).toMatchObject({ userId: userIdA, role: 'OWNER' });
  });

  it('rejects creating a second owned group on the free tier', async () => {
    await request(app.getHttpServer())
      .post('/trainer-groups')
      .set(authA())
      .send({ name: 'Second group' })
      .expect(403);
  });

  it('invites, lists, accepts, and reflects the new membership', async () => {
    const groups = await request(app.getHttpServer())
      .get('/trainer-groups')
      .set(authA())
      .expect(200);
    const groupId = groups.body.data[0].id as string;

    await request(app.getHttpServer())
      .post(`/trainer-groups/${groupId}/invitations`)
      .set(authA())
      .send({ inviteeUserId: userIdB })
      .expect(201);

    const invitations = await request(app.getHttpServer())
      .get('/trainer-groups/invitations')
      .set(authB())
      .expect(200);
    expect(invitations.body.data).toHaveLength(1);
    const invitationId = invitations.body.data[0].id as string;

    await request(app.getHttpServer())
      .post(`/trainer-groups/invitations/${invitationId}/accept`)
      .set(authB())
      .expect(201);

    const group = await request(app.getHttpServer())
      .get(`/trainer-groups/${groupId}`)
      .set(authB())
      .expect(200);
    expect(group.body.data.members.map((m: { userId: string }) => m.userId)).toContain(userIdB);
  });

  it('rejects a non-owner inviting a member', async () => {
    const groups = await request(app.getHttpServer())
      .get('/trainer-groups')
      .set(authA())
      .expect(200);
    const groupId = groups.body.data[0].id as string;

    await request(app.getHttpServer())
      .post(`/trainer-groups/${groupId}/invitations`)
      .set(authB())
      .send({ inviteeUserId: userIdC })
      .expect(403);
  });

  it('a decline leaves no membership and the invitation reusable afterward', async () => {
    const groups = await request(app.getHttpServer())
      .get('/trainer-groups')
      .set(authA())
      .expect(200);
    const groupId = groups.body.data[0].id as string;

    await request(app.getHttpServer())
      .post(`/trainer-groups/${groupId}/invitations`)
      .set(authA())
      .send({ inviteeUserId: userIdC })
      .expect(201);
    const invitations = await request(app.getHttpServer())
      .get('/trainer-groups/invitations')
      .set(authC())
      .expect(200);
    const invitationId = invitations.body.data[0].id as string;

    await request(app.getHttpServer())
      .post(`/trainer-groups/invitations/${invitationId}/decline`)
      .set(authC())
      .expect(201);

    const group = await request(app.getHttpServer())
      .get(`/trainer-groups/${groupId}`)
      .set(authA())
      .expect(200);
    expect(group.body.data.members.map((m: { userId: string }) => m.userId)).not.toContain(userIdC);

    // Re-inviting after a decline works — the same (groupId, inviteeId)
    // row flips back to PENDING rather than erroring on the unique
    // constraint.
    await request(app.getHttpServer())
      .post(`/trainer-groups/${groupId}/invitations`)
      .set(authA())
      .send({ inviteeUserId: userIdC })
      .expect(201);
  });

  it('fills the group to its free-tier member limit and then rejects further invites', async () => {
    const groups = await request(app.getHttpServer())
      .get('/trainer-groups')
      .set(authA())
      .expect(200);
    const groupId = groups.body.data[0].id as string;

    // A(owner) + B are already in. Fill with C, D, E to reach 5.
    for (const [token, userId] of [
      [tokenC, userIdC],
      [tokenD, userIdD],
      [tokenE, userIdE],
    ] as const) {
      await request(app.getHttpServer())
        .post(`/trainer-groups/${groupId}/invitations`)
        .set(authA())
        .send({ inviteeUserId: userId })
        .expect(201);
      const invitations = await request(app.getHttpServer())
        .get('/trainer-groups/invitations')
        .set({ Authorization: `Bearer ${token}` })
        .expect(200);
      const invitationId = invitations.body.data[0].id as string;
      await request(app.getHttpServer())
        .post(`/trainer-groups/invitations/${invitationId}/accept`)
        .set({ Authorization: `Bearer ${token}` })
        .expect(201);
    }

    const group = await request(app.getHttpServer())
      .get(`/trainer-groups/${groupId}`)
      .set(authA())
      .expect(200);
    expect(group.body.data.members).toHaveLength(5);

    await request(app.getHttpServer())
      .post(`/trainer-groups/${groupId}/invitations`)
      .set(authA())
      .send({ inviteeUserId: userIdF })
      .expect(403);
  });

  it('sends and lists text/image messages, and rejects an empty one', async () => {
    const groups = await request(app.getHttpServer())
      .get('/trainer-groups')
      .set(authA())
      .expect(200);
    const groupId = groups.body.data[0].id as string;

    await request(app.getHttpServer())
      .post(`/trainer-groups/${groupId}/messages`)
      .set(authA())
      .send({ body: 'See everyone at 6am!' })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/trainer-groups/${groupId}/messages`)
      .set(authB())
      .send({ imageUrl: 'https://cdn.example.com/form-check.png' })
      .expect(201);
    await request(app.getHttpServer())
      .post(`/trainer-groups/${groupId}/messages`)
      .set(authA())
      .send({})
      .expect(400);

    const messages = await request(app.getHttpServer())
      .get(`/trainer-groups/${groupId}/messages`)
      .set(authA())
      .expect(200);
    expect(messages.body.data.data).toHaveLength(2);
  });

  it('rejects a non-member sending or reading messages', async () => {
    const groups = await request(app.getHttpServer())
      .get('/trainer-groups')
      .set(authA())
      .expect(200);
    const groupId = groups.body.data[0].id as string;

    // F was never invited to this group at this point in the suite.
    await request(app.getHttpServer())
      .post(`/trainer-groups/${groupId}/messages`)
      .set({ Authorization: `Bearer ${tokenF}` })
      .send({ body: 'hi' })
      .expect(404);
    await request(app.getHttpServer())
      .get(`/trainer-groups/${groupId}/messages`)
      .set({ Authorization: `Bearer ${tokenF}` })
      .expect(404);
  });

  it('shares a workout plan into the group and only the owning member can share it', async () => {
    const groups = await request(app.getHttpServer())
      .get('/trainer-groups')
      .set(authA())
      .expect(200);
    const groupId = groups.body.data[0].id as string;

    const plan = await request(app.getHttpServer())
      .post('/workout-plans')
      .set(authA())
      .send({ name: "Ada's Push Day" })
      .expect(201);
    const planId = plan.body.data.id as string;

    await request(app.getHttpServer())
      .post(`/trainer-groups/${groupId}/shared-plans`)
      .set(authB())
      .send({ workoutPlanId: planId })
      .expect(404);

    const shared = await request(app.getHttpServer())
      .post(`/trainer-groups/${groupId}/shared-plans`)
      .set(authA())
      .send({ workoutPlanId: planId })
      .expect(201);

    const list = await request(app.getHttpServer())
      .get(`/trainer-groups/${groupId}/shared-plans`)
      .set(authB())
      .expect(200);
    expect(list.body.data).toHaveLength(1);
    expect(list.body.data[0].workoutPlan.name).toBe("Ada's Push Day");

    await request(app.getHttpServer())
      .delete(`/trainer-groups/${groupId}/shared-plans/${shared.body.data.id}`)
      .set(authB())
      .expect(403);
    await request(app.getHttpServer())
      .delete(`/trainer-groups/${groupId}/shared-plans/${shared.body.data.id}`)
      .set(authA())
      .expect(204);
  });

  it('the owner cannot be removed, and a member can remove themselves (leave)', async () => {
    const groups = await request(app.getHttpServer())
      .get('/trainer-groups')
      .set(authA())
      .expect(200);
    const groupId = groups.body.data[0].id as string;

    await request(app.getHttpServer())
      .delete(`/trainer-groups/${groupId}/members/${userIdA}`)
      .set(authA())
      .expect(400);

    await request(app.getHttpServer())
      .delete(`/trainer-groups/${groupId}/members/${userIdB}`)
      .set(authB())
      .expect(204);

    const group = await request(app.getHttpServer())
      .get(`/trainer-groups/${groupId}`)
      .set(authA())
      .expect(200);
    expect(group.body.data.members.map((m: { userId: string }) => m.userId)).not.toContain(userIdB);
  });

  it('deletes the group, and only the owner may delete it', async () => {
    const created = await request(app.getHttpServer())
      .post('/trainer-groups')
      .set(authF())
      .send({ name: 'Temp group' })
      .expect(201);
    const groupId = created.body.data.id as string;

    await request(app.getHttpServer())
      .delete(`/trainer-groups/${groupId}`)
      .set(authA())
      .expect(403);
    await request(app.getHttpServer())
      .delete(`/trainer-groups/${groupId}`)
      .set(authF())
      .expect(204);
    await request(app.getHttpServer()).get(`/trainer-groups/${groupId}`).set(authF()).expect(404);
  });
});
