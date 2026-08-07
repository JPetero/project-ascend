import { Controller, Delete, Get, Param, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { NutrientCategoryCode } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { NutritionLibraryService } from './nutrition-library.service';

@ApiBearerAuth()
@ApiTags('nutrition-library')
@Controller('nutrition-library')
export class NutritionLibraryController {
  constructor(private readonly library: NutritionLibraryService) {}

  @Get('categories')
  listCategories() {
    return this.library.listCategories();
  }

  @Get('articles')
  listArticles(@Query('category') category?: NutrientCategoryCode) {
    return this.library.listArticles(category);
  }

  @Get('saved')
  listSaved(@CurrentUser() user: AuthenticatedUser) {
    return this.library.listSaved(user.id);
  }

  @Get('articles/:slug')
  getArticle(@Param('slug') slug: string) {
    return this.library.getArticle(slug);
  }

  @Post('articles/:slug/save')
  async save(@CurrentUser() user: AuthenticatedUser, @Param('slug') slug: string) {
    await this.library.saveArticle(user.id, slug);
    return { saved: true };
  }

  @Delete('articles/:slug/save')
  async unsave(@CurrentUser() user: AuthenticatedUser, @Param('slug') slug: string) {
    await this.library.unsaveArticle(user.id, slug);
    return { saved: false };
  }
}
