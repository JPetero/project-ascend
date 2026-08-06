import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

function round1(value: number): number {
  return Math.round(value * 10) / 10;
}

describe('Nutrition Tracking (e2e)', () => {
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

    const registerA = await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        firstName: 'Nora',
        email: 'nutrition-a@example.com',
        password: 'Str0ngPass!',
        confirmPassword: 'Str0ngPass!',
        acceptedTerms: true,
      })
      .expect(201);
    tokenA = registerA.body.data.tokens.accessToken;

    const registerB = await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        firstName: 'Beth',
        email: 'nutrition-b@example.com',
        password: 'Str0ngPass!',
        confirmPassword: 'Str0ngPass!',
        acceptedTerms: true,
      })
      .expect(201);
    tokenB = registerB.body.data.tokens.accessToken;
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  const authA = () => ({ Authorization: `Bearer ${tokenA}` });
  const authB = () => ({ Authorization: `Bearer ${tokenB}` });

  describe('foods', () => {
    it('searches the seeded food catalog with pagination metadata', async () => {
      const res = await request(app.getHttpServer())
        .get('/foods')
        .query({ search: 'rice', page: 1, limit: 10 })
        .set(authA())
        .expect(200);

      expect(res.body.data.data.length).toBeGreaterThan(0);
      const rice = res.body.data.data.find((f: { name: string }) => f.name === 'Cooked White Rice');
      expect(rice).toBeDefined();
      expect(rice.sourceType).toBe('SEED');
      expect(rice.servings.length).toBeGreaterThan(0);
      expect(res.body.data.meta).toEqual({ page: 1, limit: 10, total: expect.any(Number) });
    });

    it('creates, updates, and archives a custom food, visible only to its owner', async () => {
      const created = await request(app.getHttpServer())
        .post('/foods')
        .set(authA())
        .send({
          name: 'Homemade Chicken Adobo',
          servingDescription: '1 cup (240 g)',
          servingGrams: 240,
          caloriesPerServing: 320,
          proteinGramsPerServing: 28,
          carbGramsPerServing: 6,
          fatGramsPerServing: 20,
        })
        .expect(201);

      const foodId = created.body.data.id;
      expect(created.body.data.sourceType).toBe('USER');
      expect(created.body.data.isOwnedByCurrentUser).toBe(true);

      // Not visible to another user via search.
      const otherSearch = await request(app.getHttpServer())
        .get('/foods')
        .query({ search: 'Adobo' })
        .set(authB())
        .expect(200);
      expect(
        otherSearch.body.data.data.find((f: { id: string }) => f.id === foodId),
      ).toBeUndefined();

      // Not accessible to another user by id either.
      await request(app.getHttpServer()).get(`/foods/${foodId}`).set(authB()).expect(404);

      // Another user's custom food isn't even visible to them, so edit and
      // archive attempts 404 rather than leak its existence via a 403.
      await request(app.getHttpServer())
        .patch(`/foods/${foodId}`)
        .set(authB())
        .send({ name: 'Hijacked' })
        .expect(404);
      await request(app.getHttpServer()).post(`/foods/${foodId}/archive`).set(authB()).expect(404);

      const updated = await request(app.getHttpServer())
        .patch(`/foods/${foodId}`)
        .set(authA())
        .send({ caloriesPerServing: 300 })
        .expect(200);
      expect(updated.body.data.caloriesPerServing).toBe(300);

      const archived = await request(app.getHttpServer())
        .post(`/foods/${foodId}/archive`)
        .set(authA())
        .expect(200);
      expect(archived.body.data.archivedAt).not.toBeNull();
    });

    it('rejects editing a shared seed food, even for a food visible to the requester', async () => {
      const rice = await request(app.getHttpServer())
        .get('/foods')
        .query({ search: 'Cooked White Rice' })
        .set(authA())
        .expect(200);
      const riceFood = rice.body.data.data.find(
        (f: { name: string }) => f.name === 'Cooked White Rice',
      );

      await request(app.getHttpServer())
        .patch(`/foods/${riceFood.id}`)
        .set(authA())
        .send({ name: 'Hijacked Rice' })
        .expect(403);
      await request(app.getHttpServer())
        .post(`/foods/${riceFood.id}/archive`)
        .set(authA())
        .expect(403);
    });

    it('replays the same custom food for a repeated idempotency key instead of creating a duplicate', async () => {
      const idempotencyKey = 'custom-food-create-key-1';
      const payload = {
        name: 'Offline-created Oatmeal',
        servingDescription: '1 bowl',
        caloriesPerServing: 250,
        proteinGramsPerServing: 8,
        carbGramsPerServing: 40,
        fatGramsPerServing: 5,
        idempotencyKey,
      };

      const first = await request(app.getHttpServer())
        .post('/foods')
        .set(authA())
        .send(payload)
        .expect(201);
      const replay = await request(app.getHttpServer())
        .post('/foods')
        .set(authA())
        .send(payload)
        .expect(201);

      expect(replay.body.data.id).toBe(first.body.data.id);

      const search = await request(app.getHttpServer())
        .get('/foods')
        .query({ search: 'Offline-created Oatmeal' })
        .set(authA())
        .expect(200);
      expect(search.body.data.data).toHaveLength(1);
    });
  });

  describe('macro targets', () => {
    it('computes a safe, bounded, labelled default estimate on first read', async () => {
      const res = await request(app.getHttpServer()).get('/macro-targets').set(authB()).expect(200);

      expect(res.body.data.isEstimatedDefault).toBe(true);
      expect(res.body.data.calorieTarget).toBeGreaterThanOrEqual(1200);
      expect(typeof res.body.data.disclaimer).toBe('string');
      expect(res.body.data.disclaimer.length).toBeGreaterThan(0);
    });

    it('lets a user set explicit targets, rejecting an unsafe calorie floor', async () => {
      await request(app.getHttpServer())
        .put('/macro-targets')
        .set(authA())
        .send({
          calorieTarget: 500,
          proteinGramsTarget: 150,
          carbGramsTarget: 200,
          fatGramsTarget: 60,
        })
        .expect(400);

      const res = await request(app.getHttpServer())
        .put('/macro-targets')
        .set(authA())
        .send({
          calorieTarget: 2200,
          proteinGramsTarget: 150,
          carbGramsTarget: 220,
          fatGramsTarget: 70,
        })
        .expect(200);

      expect(res.body.data.isEstimatedDefault).toBe(false);
      expect(res.body.data.calorieTarget).toBe(2200);
    });
  });

  describe('water', () => {
    it('logs, totals, updates, and deletes water entries with per-user isolation', async () => {
      const date = '2026-03-01';

      const first = await request(app.getHttpServer())
        .post('/water')
        .set(authA())
        .send({ date, amountMl: 500 })
        .expect(201);
      await request(app.getHttpServer())
        .post('/water')
        .set(authA())
        .send({ date, amountMl: 750 })
        .expect(201);

      const daily = await request(app.getHttpServer())
        .get('/water')
        .query({ date })
        .set(authA())
        .expect(200);
      expect(daily.body.data.totalMl).toBe(1250);
      expect(daily.body.data.entries.length).toBe(2);

      // A different user's water log for the same date is separate.
      const otherDaily = await request(app.getHttpServer())
        .get('/water')
        .query({ date })
        .set(authB())
        .expect(200);
      expect(otherDaily.body.data.totalMl).toBe(0);

      const entryId = first.body.data.id;
      await request(app.getHttpServer())
        .patch(`/water/${entryId}`)
        .set(authB())
        .send({ amountMl: 999 })
        .expect(404);

      await request(app.getHttpServer())
        .patch(`/water/${entryId}`)
        .set(authA())
        .send({ amountMl: 600 })
        .expect(200);

      await request(app.getHttpServer()).delete(`/water/${entryId}`).set(authA()).expect(204);

      const afterDelete = await request(app.getHttpServer())
        .get('/water')
        .query({ date })
        .set(authA())
        .expect(200);
      expect(afterDelete.body.data.totalMl).toBe(750);
    });
  });

  describe('nutrition log', () => {
    it('logs a meal entry by grams, snapshots rounded macros, and rejects cross-user access', async () => {
      const rice = await request(app.getHttpServer())
        .get('/foods')
        .query({ search: 'Cooked White Rice' })
        .set(authA())
        .expect(200);
      const riceFood = rice.body.data.data.find(
        (f: { name: string }) => f.name === 'Cooked White Rice',
      );
      expect(riceFood).toBeDefined();

      const date = '2026-03-02';
      const created = await request(app.getHttpServer())
        .post('/nutrition-log')
        .set(authA())
        .send({
          foodId: riceFood.id,
          mealType: 'LUNCH',
          date,
          quantity: 1,
          loggedByGrams: true,
          gramsLogged: 50,
        })
        .expect(201);

      const multiplier = 50 / riceFood.servingGrams;
      expect(created.body.data.calories).toBe(round1(riceFood.caloriesPerServing * multiplier));
      expect(created.body.data.proteinGrams).toBe(
        round1(riceFood.proteinGramsPerServing * multiplier),
      );

      // This is user A's first-ever logged meal in this file, so
      // "first_meal_logged" should be earned as a side effect.
      const achievements = await request(app.getHttpServer())
        .get('/achievements')
        .set(authA())
        .expect(200);
      const firstMealLogged = achievements.body.data.find(
        (a: { key: string }) => a.key === 'first_meal_logged',
      );
      expect(firstMealLogged.earnedAt).not.toBeNull();

      const entryId = created.body.data.id;

      // Another user cannot read, edit, or delete this entry.
      await request(app.getHttpServer())
        .patch(`/nutrition-log/${entryId}`)
        .set(authB())
        .send({ quantity: 2 })
        .expect(404);
      await request(app.getHttpServer())
        .delete(`/nutrition-log/${entryId}`)
        .set(authB())
        .expect(404);

      const daily = await request(app.getHttpServer())
        .get('/nutrition-log')
        .query({ date })
        .set(authA())
        .expect(200);
      expect(daily.body.data.length).toBe(1);

      const summary = await request(app.getHttpServer())
        .get('/nutrition-log/summary')
        .query({ date })
        .set(authA())
        .expect(200);
      expect(summary.body.data.entryCount).toBe(1);
      expect(summary.body.data.calories).toBe(round1(riceFood.caloriesPerServing * multiplier));

      // Recompute macros on update when the logged quantity changes.
      const updated = await request(app.getHttpServer())
        .patch(`/nutrition-log/${entryId}`)
        .set(authA())
        .send({ gramsLogged: 100 })
        .expect(200);
      const newMultiplier = 100 / riceFood.servingGrams;
      expect(updated.body.data.calories).toBe(round1(riceFood.caloriesPerServing * newMultiplier));

      await request(app.getHttpServer())
        .delete(`/nutrition-log/${entryId}`)
        .set(authA())
        .expect(204);
      const afterDelete = await request(app.getHttpServer())
        .get('/nutrition-log')
        .query({ date })
        .set(authA())
        .expect(200);
      expect(afterDelete.body.data.length).toBe(0);
    });

    it('rejects logging an archived food and a food owned by another user', async () => {
      const customFood = await request(app.getHttpServer())
        .post('/foods')
        .set(authB())
        .send({
          name: 'Bee Private Snack',
          servingDescription: '1 bar (40 g)',
          servingGrams: 40,
          caloriesPerServing: 180,
          proteinGramsPerServing: 5,
          carbGramsPerServing: 20,
          fatGramsPerServing: 8,
        })
        .expect(201);

      await request(app.getHttpServer())
        .post('/nutrition-log')
        .set(authA())
        .send({
          foodId: customFood.body.data.id,
          mealType: 'SNACK',
          date: '2026-03-03',
          quantity: 1,
        })
        .expect(404);

      await request(app.getHttpServer())
        .post(`/foods/${customFood.body.data.id}/archive`)
        .set(authB())
        .expect(200);

      await request(app.getHttpServer())
        .post('/nutrition-log')
        .set(authB())
        .send({
          foodId: customFood.body.data.id,
          mealType: 'SNACK',
          date: '2026-03-03',
          quantity: 1,
        })
        .expect(400);
    });

    it('replays the same result for a repeated idempotency key instead of creating a duplicate', async () => {
      const banana = await request(app.getHttpServer())
        .get('/foods')
        .query({ search: 'Banana' })
        .set(authA())
        .expect(200);
      const bananaFood = banana.body.data.data.find((f: { name: string }) => f.name === 'Banana');

      const idempotencyKey = 'nutrition-log-add-key-1';
      const payload = {
        foodId: bananaFood.id,
        mealType: 'SNACK',
        date: '2026-03-04',
        quantity: 1,
        idempotencyKey,
      };

      const first = await request(app.getHttpServer())
        .post('/nutrition-log')
        .set(authA())
        .send(payload)
        .expect(201);
      const second = await request(app.getHttpServer())
        .post('/nutrition-log')
        .set(authA())
        .send(payload)
        .expect(201);

      expect(second.body.data.id).toBe(first.body.data.id);

      const daily = await request(app.getHttpServer())
        .get('/nutrition-log')
        .query({ date: '2026-03-04' })
        .set(authA())
        .expect(200);
      expect(daily.body.data.length).toBe(1);
    });

    it('copies a day of entries without duplicating on a repeated idempotency key', async () => {
      const oats = await request(app.getHttpServer())
        .get('/foods')
        .query({ search: 'Oats' })
        .set(authA())
        .expect(200);
      const oatsFood = oats.body.data.data.find(
        (f: { name: string }) => f.name === 'Rolled Oats (Dry)',
      );

      const sourceDate = '2026-03-05';
      const targetDate = '2026-03-06';
      await request(app.getHttpServer())
        .post('/nutrition-log')
        .set(authA())
        .send({ foodId: oatsFood.id, mealType: 'BREAKFAST', date: sourceDate, quantity: 1 })
        .expect(201);

      const copyKey = 'nutrition-log-copy-key-1';
      await request(app.getHttpServer())
        .post('/nutrition-log/copy')
        .set(authA())
        .send({ sourceDate, targetDate, idempotencyKey: copyKey })
        .expect(201);
      await request(app.getHttpServer())
        .post('/nutrition-log/copy')
        .set(authA())
        .send({ sourceDate, targetDate, idempotencyKey: copyKey })
        .expect(201);

      const target = await request(app.getHttpServer())
        .get('/nutrition-log')
        .query({ date: targetDate })
        .set(authA())
        .expect(200);
      expect(target.body.data.length).toBe(1);
    });

    it('averages a 7-day window correctly around a single logged day', async () => {
      const apple = await request(app.getHttpServer())
        .get('/foods')
        .query({ search: 'Apple' })
        .set(authA())
        .expect(200);
      const appleFood = apple.body.data.data.find((f: { name: string }) => f.name === 'Apple');

      const endDate = '2026-03-20';
      await request(app.getHttpServer())
        .post('/nutrition-log')
        .set(authA())
        .send({ foodId: appleFood.id, mealType: 'SNACK', date: endDate, quantity: 2 })
        .expect(201);

      const summary = await request(app.getHttpServer())
        .get('/nutrition-log/summary/seven-day')
        .query({ endDate })
        .set(authA())
        .expect(200);

      expect(summary.body.data.days.length).toBe(7);
      const loggedDay = summary.body.data.days.find((d: { date: string }) => d.date === endDate);
      expect(loggedDay.calories).toBe(round1(appleFood.caloriesPerServing * 2));
      expect(summary.body.data.average.calories).toBe(
        round1((appleFood.caloriesPerServing * 2) / 7),
      );
    });
  });

  describe('saved meals', () => {
    it('creates a saved meal, replays the same result for a repeated idempotency key, edits, logs, and deletes it', async () => {
      const search = await request(app.getHttpServer())
        .get('/foods')
        .query({ search: 'Cooked White Rice' })
        .set(authA())
        .expect(200);
      const rice = search.body.data.data.find(
        (f: { name: string }) => f.name === 'Cooked White Rice',
      );
      const appleSearch = await request(app.getHttpServer())
        .get('/foods')
        .query({ search: 'Apple' })
        .set(authA())
        .expect(200);
      const apple = appleSearch.body.data.data.find((f: { name: string }) => f.name === 'Apple');

      const idempotencyKey = 'saved-meal-create-key-1';
      const first = await request(app.getHttpServer())
        .post('/saved-meals')
        .set(authA())
        .send({ name: 'Rice bowl', items: [{ foodId: rice.id, quantity: 1 }], idempotencyKey })
        .expect(201);

      const replay = await request(app.getHttpServer())
        .post('/saved-meals')
        .set(authA())
        .send({ name: 'Rice bowl', items: [{ foodId: rice.id, quantity: 1 }], idempotencyKey })
        .expect(201);
      expect(replay.body.data.id).toBe(first.body.data.id);

      const listAfterCreate = await request(app.getHttpServer())
        .get('/saved-meals')
        .set(authA())
        .expect(200);
      expect(listAfterCreate.body.data).toHaveLength(1);

      const savedMealId = first.body.data.id;

      const updated = await request(app.getHttpServer())
        .patch(`/saved-meals/${savedMealId}`)
        .set(authA())
        .send({ name: 'Rice and apple bowl', items: [{ foodId: apple.id, quantity: 3 }] })
        .expect(200);
      expect(updated.body.data.name).toBe('Rice and apple bowl');
      expect(updated.body.data.items).toHaveLength(1);
      expect(updated.body.data.items[0].food.name).toBe('Apple');
      expect(updated.body.data.items[0].quantity).toBe(3);

      await request(app.getHttpServer())
        .patch(`/saved-meals/${savedMealId}`)
        .set(authB())
        .send({ name: 'Hijacked' })
        .expect(403);

      const logDate = '2026-04-01';
      const logged = await request(app.getHttpServer())
        .post(`/saved-meals/${savedMealId}/log`)
        .set(authA())
        .send({ mealType: 'LUNCH', date: logDate })
        .expect(201);
      expect(logged.body.data).toHaveLength(1);
      expect(logged.body.data[0].calories).toBe(round1(apple.caloriesPerServing * 3));

      await request(app.getHttpServer())
        .delete(`/saved-meals/${savedMealId}`)
        .set(authB())
        .expect(403);

      await request(app.getHttpServer())
        .delete(`/saved-meals/${savedMealId}`)
        .set(authA())
        .expect(200);

      const listAfterDelete = await request(app.getHttpServer())
        .get('/saved-meals')
        .set(authA())
        .expect(200);
      expect(listAfterDelete.body.data).toHaveLength(0);
    });
  });
});
