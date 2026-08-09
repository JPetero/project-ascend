import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

/**
 * The workout/cardio/nutrition e2e specs each already check that a
 * fresh user's very first action earns that domain's "first_*"
 * achievement. What none of them check is what happens once one account
 * has real, ongoing activity across *multiple* domains: does progress
 * toward a multi-step achievement (e.g. `ten_workouts`) accumulate
 * correctly before it's earned, and does `AchievementsService.evaluate`
 * keep workout/cardio/nutrition progress isolated instead of one
 * domain's count leaking into another's `AchievementAward` row (Build
 * Session 10 Part 30).
 */
describe('Achievement progress across domains (e2e)', () => {
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

    const registered = await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        firstName: 'Sam',
        email: 'achievements-a@example.com',
        password: 'Str0ngPass!',
        confirmPassword: 'Str0ngPass!',
        acceptedTerms: true,
      })
      .expect(201);
    accessToken = registered.body.data.tokens.accessToken;
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  const auth = () => ({ Authorization: `Bearer ${accessToken}` });

  it('accumulates progress per-domain, in step, without one domain leaking into another', async () => {
    const workouts = await request(app.getHttpServer()).get('/workouts').set(auth()).expect(200);
    const workout = workouts.body.data.find(
      (w: { slug: string }) => w.slug === 'full-body-strength',
    );
    const plan = await request(app.getHttpServer())
      .post('/workout-plans')
      .set(auth())
      .send({ name: 'Achievements Test Plan', workoutId: workout.id })
      .expect(201);
    const squatExercise = plan.body.data.exercises.find(
      (e: { exercise: { slug: string } }) => e.exercise.slug === 'barbell-back-squat',
    ).exercise;

    // Complete 3 full workout sessions — under the ten_workouts target of
    // 10, so it should show real partial progress, not "earned".
    for (let i = 0; i < 3; i += 1) {
      const started = await request(app.getHttpServer())
        .post('/workout-sessions')
        .set(auth())
        .send({ workoutPlanId: plan.body.data.id })
        .expect(201);
      await request(app.getHttpServer())
        .post(`/workout-sessions/${started.body.data.id}/sets`)
        .set(auth())
        .send({ exerciseId: squatExercise.id, reps: 8, weightKg: 40 })
        .expect(201);
      await request(app.getHttpServer())
        .post(`/workout-sessions/${started.body.data.id}/finish`)
        .set(auth())
        .expect(200);
    }

    // Log 3 cardio sessions — same story, under the ten_cardio_sessions
    // target of 10.
    for (let i = 0; i < 3; i += 1) {
      await request(app.getHttpServer())
        .post('/cardio-sessions')
        .set(auth())
        .send({
          activityType: 'RUN',
          startedAt: `2026-08-0${i + 1}T08:00:00.000Z`,
          durationSeconds: 1200,
          distanceMeters: 3000,
        })
        .expect(201);
    }

    // Log exactly one meal — first_meal_logged should be earned, but
    // hundred_meals_logged should be nowhere close.
    const foods = await request(app.getHttpServer())
      .get('/foods')
      .query({ search: 'Cooked White Rice' })
      .set(auth())
      .expect(200);
    const rice = foods.body.data.data.find(
      (f: { name: string }) => f.name === 'Cooked White Rice',
    );
    await request(app.getHttpServer())
      .post('/nutrition-log')
      .set(auth())
      .send({ foodId: rice.id, mealType: 'BREAKFAST', date: '2026-08-06', quantity: 1 })
      .expect(201);

    const achievements = await request(app.getHttpServer())
      .get('/achievements')
      .set(auth())
      .expect(200);
    const byKey = (key: string) =>
      (achievements.body.data as Array<{ key: string; progress: number; earnedAt: string | null }>).find(
        (a) => a.key === key,
      )!;

    // First-tier achievements in every domain are earned...
    expect(byKey('first_workout').earnedAt).not.toBeNull();
    expect(byKey('first_personal_record').earnedAt).not.toBeNull();
    expect(byKey('first_cardio_session').earnedAt).not.toBeNull();
    expect(byKey('first_meal_logged').earnedAt).not.toBeNull();

    // ...but the higher-tier achievements in each domain show real
    // progress toward their own target, not each other's counts, and
    // are correctly still locked.
    expect(byKey('ten_workouts')).toMatchObject({ progress: 3, earnedAt: null });
    expect(byKey('ten_cardio_sessions')).toMatchObject({ progress: 3, earnedAt: null });
    expect(byKey('fifty_workouts')).toMatchObject({ progress: 3, earnedAt: null });
    expect(byKey('hundred_meals_logged')).toMatchObject({ progress: 1, earnedAt: null });
  });
});
