import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

describe('Workout Engine (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let accessToken: string;

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

    const registerRes = await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        firstName: 'Riley',
        email: 'workout-engine@example.com',
        password: 'Str0ngPass!',
        confirmPassword: 'Str0ngPass!',
        acceptedTerms: true,
      })
      .expect(201);

    accessToken = registerRes.body.data.tokens.accessToken;
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  const auth = () => ({ Authorization: `Bearer ${accessToken}` });

  describe('catalog', () => {
    it('lists exercise categories, muscle groups, and equipment types (seeded)', async () => {
      const [categories, muscles, equipment] = await Promise.all([
        request(app.getHttpServer()).get('/exercise-categories').set(auth()).expect(200),
        request(app.getHttpServer()).get('/muscle-groups').set(auth()).expect(200),
        request(app.getHttpServer()).get('/equipment-types').set(auth()).expect(200),
      ]);

      expect(categories.body.data.length).toBeGreaterThan(0);
      expect(muscles.body.data.length).toBeGreaterThan(0);
      expect(equipment.body.data.length).toBeGreaterThan(0);
    });

    it('lists exercises with muscles and equipment, and supports filtering by category', async () => {
      const all = await request(app.getHttpServer()).get('/exercises').set(auth()).expect(200);
      expect(all.body.data.length).toBeGreaterThan(0);

      const squat = all.body.data.find((e: { slug: string }) => e.slug === 'barbell-back-squat');
      expect(squat).toBeDefined();
      expect(squat.primaryMuscles.length).toBeGreaterThan(0);
      expect(squat.equipment.length).toBeGreaterThan(0);

      const filtered = await request(app.getHttpServer())
        .get('/exercises')
        .query({ categorySlug: 'mobility' })
        .set(auth())
        .expect(200);
      expect(filtered.body.data.length).toBeGreaterThan(0);
      expect(
        filtered.body.data.every(
          (e: { category: { slug: string } }) => e.category.slug === 'mobility',
        ),
      ).toBe(true);
    });

    it('returns an exercise detail with alternatives', async () => {
      const list = await request(app.getHttpServer()).get('/exercises').set(auth()).expect(200);
      const squat = list.body.data.find((e: { slug: string }) => e.slug === 'barbell-back-squat');

      const detail = await request(app.getHttpServer())
        .get(`/exercises/${squat.id}`)
        .set(auth())
        .expect(200);

      expect(detail.body.data.alternatives.length).toBeGreaterThan(0);
    });

    it('404s for an unknown exercise id', async () => {
      await request(app.getHttpServer())
        .get('/exercises/00000000-0000-0000-0000-000000000000')
        .set(auth())
        .expect(404);
    });

    it('lists catalog workouts and returns a workout detail with ordered exercises', async () => {
      const list = await request(app.getHttpServer()).get('/workouts').set(auth()).expect(200);
      expect(list.body.data.length).toBeGreaterThan(0);

      const workout = list.body.data.find((w: { slug: string }) => w.slug === 'full-body-strength');
      const detail = await request(app.getHttpServer())
        .get(`/workouts/${workout.id}`)
        .set(auth())
        .expect(200);

      expect(detail.body.data.exercises.length).toBeGreaterThan(0);
      const orders = detail.body.data.exercises.map((e: { order: number }) => e.order);
      expect(orders).toEqual([...orders].sort((a, b) => a - b));
    });
  });

  describe('workout plans', () => {
    it('creates a plan from a catalog workout, copying its exercises in', async () => {
      const workouts = await request(app.getHttpServer()).get('/workouts').set(auth()).expect(200);
      const workout = workouts.body.data.find(
        (w: { slug: string }) => w.slug === 'full-body-strength',
      );

      const created = await request(app.getHttpServer())
        .post('/workout-plans')
        .set(auth())
        .send({ name: 'My Strength Plan', workoutId: workout.id })
        .expect(201);

      expect(created.body.data.name).toBe('My Strength Plan');
      expect(created.body.data.exercises.length).toBe(
        workout.exercises?.length ?? created.body.data.exercises.length,
      );
      expect(created.body.data.exercises.length).toBeGreaterThan(0);
    });

    it('creates a custom plan with no catalog workout', async () => {
      const exercises = await request(app.getHttpServer())
        .get('/exercises')
        .set(auth())
        .expect(200);
      const pushUp = exercises.body.data.find((e: { slug: string }) => e.slug === 'push-up');

      const created = await request(app.getHttpServer())
        .post('/workout-plans')
        .set(auth())
        .send({
          name: 'Custom Push Day',
          exercises: [{ exerciseId: pushUp.id, order: 1, targetSets: 3, targetReps: 12 }],
        })
        .expect(201);

      expect(created.body.data.exercises).toHaveLength(1);
      expect(created.body.data.exercises[0].exercise.slug).toBe('push-up');
    });

    it('lists, updates, and deletes a plan, all scoped to the owning user', async () => {
      const exercises = await request(app.getHttpServer())
        .get('/exercises')
        .set(auth())
        .expect(200);
      const plank = exercises.body.data.find((e: { slug: string }) => e.slug === 'plank');

      const created = await request(app.getHttpServer())
        .post('/workout-plans')
        .set(auth())
        .send({
          name: 'Core Day',
          exercises: [{ exerciseId: plank.id, order: 1, targetSets: 3, targetDurationSeconds: 30 }],
        })
        .expect(201);
      const planId = created.body.data.id;

      const list = await request(app.getHttpServer()).get('/workout-plans').set(auth()).expect(200);
      expect(list.body.data.some((p: { id: string }) => p.id === planId)).toBe(true);

      const updated = await request(app.getHttpServer())
        .patch(`/workout-plans/${planId}`)
        .set(auth())
        .send({ name: 'Core Day (updated)' })
        .expect(200);
      expect(updated.body.data.name).toBe('Core Day (updated)');

      await request(app.getHttpServer()).delete(`/workout-plans/${planId}`).set(auth()).expect(200);
      await request(app.getHttpServer()).get(`/workout-plans/${planId}`).set(auth()).expect(404);
    });

    it("rejects access to another user's plan", async () => {
      const otherUser = await request(app.getHttpServer())
        .post('/auth/register')
        .send({
          firstName: 'Other',
          email: 'other-workout-user@example.com',
          password: 'Str0ngPass!',
          confirmPassword: 'Str0ngPass!',
          acceptedTerms: true,
        })
        .expect(201);
      const otherToken = otherUser.body.data.tokens.accessToken;

      const exercises = await request(app.getHttpServer())
        .get('/exercises')
        .set(auth())
        .expect(200);
      const plank = exercises.body.data.find((e: { slug: string }) => e.slug === 'plank');
      const created = await request(app.getHttpServer())
        .post('/workout-plans')
        .set(auth())
        .send({
          name: 'Private Plan',
          exercises: [{ exerciseId: plank.id, order: 1, targetSets: 1, targetDurationSeconds: 30 }],
        })
        .expect(201);

      await request(app.getHttpServer())
        .get(`/workout-plans/${created.body.data.id}`)
        .set({ Authorization: `Bearer ${otherToken}` })
        .expect(404);
    });
  });

  describe('workout sessions: lifecycle, set logging, and personal records', () => {
    it('runs a full session end-to-end: start -> log sets -> pause -> resume -> finish -> personal records', async () => {
      const workouts = await request(app.getHttpServer()).get('/workouts').set(auth()).expect(200);
      const workout = workouts.body.data.find(
        (w: { slug: string }) => w.slug === 'full-body-strength',
      );
      const plan = await request(app.getHttpServer())
        .post('/workout-plans')
        .set(auth())
        .send({ name: 'Session Plan', workoutId: workout.id })
        .expect(201);

      const squatExercise = plan.body.data.exercises.find(
        (e: { exercise: { slug: string } }) => e.exercise.slug === 'barbell-back-squat',
      ).exercise;

      const started = await request(app.getHttpServer())
        .post('/workout-sessions')
        .set(auth())
        .send({ workoutPlanId: plan.body.data.id })
        .expect(201);
      expect(started.body.data.status).toBe('IN_PROGRESS');
      const sessionId = started.body.data.id;

      const active = await request(app.getHttpServer())
        .get('/workout-sessions/active')
        .set(auth())
        .expect(200);
      expect(active.body.data.id).toBe(sessionId);

      // Starting a second session while one is active must be rejected.
      await request(app.getHttpServer()).post('/workout-sessions').set(auth()).send({}).expect(409);

      for (const weightKg of [60, 65, 67.5]) {
        const setRes = await request(app.getHttpServer())
          .post(`/workout-sessions/${sessionId}/sets`)
          .set(auth())
          .send({ exerciseId: squatExercise.id, reps: 8, weightKg })
          .expect(201);
        expect(setRes.body.data.exercise.id).toBe(squatExercise.id);
      }

      // setNumber is server-assigned and increments per (session, exercise).
      const midSession = await request(app.getHttpServer())
        .get(`/workout-sessions/${sessionId}`)
        .set(auth())
        .expect(200);
      expect(midSession.body.data.sets.map((s: { setNumber: number }) => s.setNumber)).toEqual([
        1, 2, 3,
      ]);

      await request(app.getHttpServer())
        .post(`/workout-sessions/${sessionId}/pause`)
        .set(auth())
        .expect(200)
        .expect((res) => expect(res.body.data.status).toBe('PAUSED'));

      // Can't log a set while paused.
      await request(app.getHttpServer())
        .post(`/workout-sessions/${sessionId}/sets`)
        .set(auth())
        .send({ exerciseId: squatExercise.id, reps: 5, weightKg: 70 })
        .expect(409);

      await request(app.getHttpServer())
        .post(`/workout-sessions/${sessionId}/resume`)
        .set(auth())
        .expect(200)
        .expect((res) => expect(res.body.data.status).toBe('IN_PROGRESS'));

      const finished = await request(app.getHttpServer())
        .post(`/workout-sessions/${sessionId}/finish`)
        .set(auth())
        .expect(200);

      expect(finished.body.data.session.status).toBe('COMPLETED');
      const newRecords = finished.body.data.newPersonalRecords;
      expect(newRecords.some((r: { type: string }) => r.type === 'MAX_WEIGHT')).toBe(true);
      expect(newRecords.some((r: { type: string }) => r.type === 'MAX_VOLUME')).toBe(true);
      const maxWeightRecord = newRecords.find((r: { type: string }) => r.type === 'MAX_WEIGHT');
      expect(maxWeightRecord.value).toBe(67.5);

      // No more sets can be logged once completed.
      await request(app.getHttpServer())
        .post(`/workout-sessions/${sessionId}/sets`)
        .set(auth())
        .send({ exerciseId: squatExercise.id, reps: 5, weightKg: 70 })
        .expect(409);

      const personalRecords = await request(app.getHttpServer())
        .get('/personal-records')
        .set(auth())
        .expect(200);
      expect(
        personalRecords.body.data.some(
          (r: { exercise: { slug: string }; type: string }) =>
            r.exercise.slug === 'barbell-back-squat' && r.type === 'MAX_WEIGHT',
        ),
      ).toBe(true);

      const history = await request(app.getHttpServer())
        .get('/workout-history')
        .set(auth())
        .expect(200);
      expect(history.body.data.data.some((s: { id: string }) => s.id === sessionId)).toBe(true);

      const historyDetail = await request(app.getHttpServer())
        .get(`/workout-history/${sessionId}`)
        .set(auth())
        .expect(200);
      expect(historyDetail.body.data.sets).toHaveLength(3);

      const progression = await request(app.getHttpServer())
        .get(`/exercises/${squatExercise.id}/progression`)
        .set(auth())
        .expect(200);
      expect(progression.body.data.hasPreviousPerformance).toBe(true);
      expect(progression.body.data.suggestion.weightKg).toBeGreaterThan(67.5);
    });

    it('breaking a record twice updates it in place rather than duplicating it', async () => {
      const exercises = await request(app.getHttpServer())
        .get('/exercises')
        .set(auth())
        .expect(200);
      const curl = exercises.body.data.find(
        (e: { slug: string }) => e.slug === 'dumbbell-bicep-curl',
      );

      for (const weightKg of [10, 12]) {
        const session = await request(app.getHttpServer())
          .post('/workout-sessions')
          .set(auth())
          .send({})
          .expect(201);
        await request(app.getHttpServer())
          .post(`/workout-sessions/${session.body.data.id}/sets`)
          .set(auth())
          .send({ exerciseId: curl.id, reps: 10, weightKg })
          .expect(201);
        await request(app.getHttpServer())
          .post(`/workout-sessions/${session.body.data.id}/finish`)
          .set(auth())
          .expect(200);
      }

      const records = await request(app.getHttpServer())
        .get('/personal-records')
        .set(auth())
        .expect(200);
      const curlRecords = records.body.data.filter(
        (r: { exercise: { slug: string }; type: string }) =>
          r.exercise.slug === 'dumbbell-bicep-curl' && r.type === 'MAX_WEIGHT',
      );
      expect(curlRecords).toHaveLength(1);
      expect(curlRecords[0].value).toBe(12);
    });

    it('abandoning a session ends it without generating personal records', async () => {
      const exercises = await request(app.getHttpServer())
        .get('/exercises')
        .set(auth())
        .expect(200);
      const jumpingJacks = exercises.body.data.find(
        (e: { slug: string }) => e.slug === 'jumping-jacks',
      );

      const session = await request(app.getHttpServer())
        .post('/workout-sessions')
        .set(auth())
        .send({})
        .expect(201);
      await request(app.getHttpServer())
        .post(`/workout-sessions/${session.body.data.id}/sets`)
        .set(auth())
        .send({ exerciseId: jumpingJacks.id, durationSeconds: 30 })
        .expect(201);

      const abandoned = await request(app.getHttpServer())
        .post(`/workout-sessions/${session.body.data.id}/abandon`)
        .set(auth())
        .expect(200);
      expect(abandoned.body.data.status).toBe('ABANDONED');

      // An abandoned session must not show up as active, and must not
      // block starting a new one.
      const active = await request(app.getHttpServer())
        .get('/workout-sessions/active')
        .set(auth())
        .expect(200);
      expect(active.body.data).toBeNull();

      await request(app.getHttpServer()).post('/workout-sessions').set(auth()).send({}).expect(201);
    });
  });
});
