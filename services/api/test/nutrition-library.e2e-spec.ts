import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { AllExceptionsFilter } from '../src/common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from '../src/common/interceptors/response-envelope.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';
import { resetDatabase } from './utils/reset-database';

describe('Nutrition Library (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let token: string;

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

    const res = await request(app.getHttpServer())
      .post('/auth/register')
      .send({
        firstName: 'Ada',
        email: 'nutrition-lib-a@example.com',
        password: 'Str0ngPass!',
        confirmPassword: 'Str0ngPass!',
        acceptedTerms: true,
      })
      .expect(201);
    token = res.body.data.tokens.accessToken as string;
  });

  afterAll(async () => {
    await resetDatabase(prisma);
    await app.close();
  });

  const auth = () => ({ Authorization: `Bearer ${token}` });

  it('lists the three seeded categories with nested articles', async () => {
    const res = await request(app.getHttpServer())
      .get('/nutrition-library/categories')
      .set(auth())
      .expect(200);

    const codes = (res.body.data as Array<{ code: string; articles: unknown[] }>).map(
      (c) => c.code,
    );
    expect(codes.sort()).toEqual(['MACRONUTRIENT', 'MINERAL', 'VITAMIN']);
    for (const category of res.body.data as Array<{ articles: unknown[] }>) {
      expect(category.articles.length).toBeGreaterThan(0);
    }
  });

  it('filters articles by category', async () => {
    const res = await request(app.getHttpServer())
      .get('/nutrition-library/articles')
      .query({ category: 'VITAMIN' })
      .set(auth())
      .expect(200);

    const slugs = (res.body.data as Array<{ slug: string }>).map((a) => a.slug);
    expect(slugs).toContain('vitamin-c');
    expect(slugs).not.toContain('protein');
  });

  it('returns a full article with food sources, references, and a safety note', async () => {
    const res = await request(app.getHttpServer())
      .get('/nutrition-library/articles/protein')
      .set(auth())
      .expect(200);

    expect(res.body.data.title).toBe('Protein');
    expect(res.body.data.safetyNote).toContain('not medical advice');
    expect((res.body.data.foodSources as unknown[]).length).toBeGreaterThan(0);
    expect((res.body.data.references as unknown[]).length).toBeGreaterThan(0);
  });

  it('404s an unknown slug', async () => {
    await request(app.getHttpServer())
      .get('/nutrition-library/articles/not-a-real-nutrient')
      .set(auth())
      .expect(404);
  });

  it('saves and unsaves an article', async () => {
    await request(app.getHttpServer())
      .post('/nutrition-library/articles/iron/save')
      .set(auth())
      .expect(201);

    const saved = await request(app.getHttpServer())
      .get('/nutrition-library/saved')
      .set(auth())
      .expect(200);
    expect((saved.body.data as Array<{ slug: string }>).map((a) => a.slug)).toContain('iron');

    await request(app.getHttpServer())
      .delete('/nutrition-library/articles/iron/save')
      .set(auth())
      .expect(200);

    const afterUnsave = await request(app.getHttpServer())
      .get('/nutrition-library/saved')
      .set(auth())
      .expect(200);
    expect((afterUnsave.body.data as Array<{ slug: string }>).map((a) => a.slug)).not.toContain(
      'iron',
    );
  });
});
