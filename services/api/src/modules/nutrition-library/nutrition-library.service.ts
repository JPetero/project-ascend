import { Injectable, NotFoundException } from '@nestjs/common';
import { NutrientCategoryCode } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { NUTRIENT_LIBRARY_SEED, SAFETY_NOTE } from './nutrition-library-content';

/**
 * Free Ascend Nutrition Library (Build Session 8 Part 11) —
 * AppCapability.nutritionLibrary is free on every tier. Content is
 * seeded lazily from NUTRIENT_LIBRARY_SEED on first read rather than
 * requiring a separate `prisma db seed` run, mirroring
 * SportsService.getOrCreateSport's bootstrap pattern.
 */
@Injectable()
export class NutritionLibraryService {
  constructor(private readonly prisma: PrismaService) {}

  async listCategories() {
    await this.seedIfEmpty();
    return this.prisma.nutrientCategory.findMany({
      include: {
        articles: {
          select: { id: true, slug: true, title: true, summary: true },
          orderBy: { sortOrder: 'asc' },
        },
      },
    });
  }

  async listArticles(categoryCode?: NutrientCategoryCode) {
    await this.seedIfEmpty();
    return this.prisma.nutrientArticle.findMany({
      where: categoryCode ? { category: { code: categoryCode } } : undefined,
      include: { category: true },
      orderBy: { sortOrder: 'asc' },
    });
  }

  async getArticle(slug: string) {
    await this.seedIfEmpty();
    const article = await this.prisma.nutrientArticle.findUnique({
      where: { slug },
      include: {
        category: true,
        foodSources: { orderBy: { sortOrder: 'asc' } },
        references: { orderBy: { sortOrder: 'asc' } },
      },
    });
    if (!article) throw new NotFoundException('Article not found.');
    return article;
  }

  async saveArticle(userId: string, slug: string): Promise<void> {
    const article = await this.requireArticle(slug);
    await this.prisma.savedNutrientArticle.upsert({
      where: { userId_articleId: { userId, articleId: article.id } },
      update: {},
      create: { userId, articleId: article.id },
    });
  }

  async unsaveArticle(userId: string, slug: string): Promise<void> {
    const article = await this.requireArticle(slug);
    await this.prisma.savedNutrientArticle.deleteMany({
      where: { userId, articleId: article.id },
    });
  }

  async listSaved(userId: string) {
    const saved = await this.prisma.savedNutrientArticle.findMany({
      where: { userId },
      include: { article: { include: { category: true } } },
      orderBy: { createdAt: 'desc' },
    });
    return saved.map((s) => s.article);
  }

  private async requireArticle(slug: string) {
    const article = await this.prisma.nutrientArticle.findUnique({ where: { slug } });
    if (!article) throw new NotFoundException('Article not found.');
    return article;
  }

  private async seedIfEmpty(): Promise<void> {
    const count = await this.prisma.nutrientCategory.count();
    if (count > 0) return;

    for (const category of NUTRIENT_LIBRARY_SEED) {
      const createdCategory = await this.prisma.nutrientCategory.create({
        data: { code: category.code, name: category.name, description: category.description },
      });

      for (const [index, article] of category.articles.entries()) {
        await this.prisma.nutrientArticle.create({
          data: {
            categoryId: createdCategory.id,
            slug: article.slug,
            title: article.title,
            summary: article.summary,
            body: article.body,
            safetyNote: SAFETY_NOTE,
            sortOrder: index,
            foodSources: {
              create: article.foodSources.map((source, sourceIndex) => ({
                foodName: source.foodName,
                amount: source.amount,
                sortOrder: sourceIndex,
              })),
            },
            references: {
              create: article.references.map((reference, referenceIndex) => ({
                label: reference.label,
                sortOrder: referenceIndex,
              })),
            },
          },
        });
      }
    }
  }
}
