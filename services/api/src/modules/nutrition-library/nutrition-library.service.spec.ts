import { NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { PrismaService } from '../../prisma/prisma.service';
import { NutritionLibraryService } from './nutrition-library.service';

describe('NutritionLibraryService', () => {
  let service: NutritionLibraryService;
  let prisma: {
    nutrientCategory: { count: jest.Mock; findMany: jest.Mock; create: jest.Mock };
    nutrientArticle: { findMany: jest.Mock; findUnique: jest.Mock; create: jest.Mock };
    savedNutrientArticle: { upsert: jest.Mock; deleteMany: jest.Mock; findMany: jest.Mock };
  };

  beforeEach(async () => {
    prisma = {
      nutrientCategory: {
        count: jest.fn().mockResolvedValue(1),
        findMany: jest.fn().mockResolvedValue([]),
        create: jest.fn(),
      },
      nutrientArticle: {
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn(),
        create: jest.fn(),
      },
      savedNutrientArticle: {
        upsert: jest.fn(),
        deleteMany: jest.fn(),
        findMany: jest.fn().mockResolvedValue([]),
      },
    };

    const moduleRef = await Test.createTestingModule({
      providers: [NutritionLibraryService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = moduleRef.get(NutritionLibraryService);
  });

  describe('seeding', () => {
    it('does not reseed when categories already exist', async () => {
      await service.listCategories();

      expect(prisma.nutrientCategory.create).not.toHaveBeenCalled();
    });

    it('seeds categories and articles on first read when empty', async () => {
      prisma.nutrientCategory.count.mockResolvedValue(0);
      prisma.nutrientCategory.create.mockResolvedValue({ id: 'category-1' });
      prisma.nutrientArticle.create.mockResolvedValue({});

      await service.listArticles();

      expect(prisma.nutrientCategory.create).toHaveBeenCalled();
      expect(prisma.nutrientArticle.create).toHaveBeenCalled();
      // Every seeded article carries the same safety note.
      const calls = prisma.nutrientArticle.create.mock.calls as Array<
        [{ data: { safetyNote: string } }]
      >;
      expect(calls.length).toBeGreaterThan(0);
      for (const [{ data }] of calls) {
        expect(data.safetyNote).toContain('not medical advice');
      }
    });
  });

  describe('getArticle', () => {
    it('404s a slug that does not exist', async () => {
      prisma.nutrientArticle.findUnique.mockResolvedValue(null);

      await expect(service.getArticle('not-a-real-nutrient')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('returns the article with food sources and references', async () => {
      prisma.nutrientArticle.findUnique.mockResolvedValue({
        id: 'article-1',
        slug: 'protein',
        foodSources: [{ foodName: 'Chicken breast' }],
        references: [{ label: 'Dietary Guidelines for Americans' }],
      });

      const article = await service.getArticle('protein');

      expect(article.slug).toBe('protein');
    });
  });

  describe('saveArticle / unsaveArticle', () => {
    it('404s saving a slug that does not exist', async () => {
      prisma.nutrientArticle.findUnique.mockResolvedValue(null);

      await expect(service.saveArticle('user-1', 'not-a-real-nutrient')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('saves an existing article', async () => {
      prisma.nutrientArticle.findUnique.mockResolvedValue({ id: 'article-1', slug: 'protein' });

      await service.saveArticle('user-1', 'protein');

      expect(prisma.savedNutrientArticle.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { userId_articleId: { userId: 'user-1', articleId: 'article-1' } },
        }),
      );
    });

    it('unsaves an existing article', async () => {
      prisma.nutrientArticle.findUnique.mockResolvedValue({ id: 'article-1', slug: 'protein' });

      await service.unsaveArticle('user-1', 'protein');

      expect(prisma.savedNutrientArticle.deleteMany).toHaveBeenCalledWith({
        where: { userId: 'user-1', articleId: 'article-1' },
      });
    });
  });
});
