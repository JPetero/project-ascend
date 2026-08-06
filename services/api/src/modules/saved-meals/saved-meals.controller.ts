import { Body, Controller, Delete, Get, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { CreateSavedMealDto } from './dto/create-saved-meal.dto';
import { LogSavedMealDto } from './dto/log-saved-meal.dto';
import { SavedMealsService } from './saved-meals.service';

@ApiBearerAuth()
@ApiTags('saved-meals')
@Controller('saved-meals')
export class SavedMealsController {
  constructor(private readonly savedMealsService: SavedMealsService) {}

  @Get()
  list(@CurrentUser() user: AuthenticatedUser) {
    return this.savedMealsService.list(user.id);
  }

  @Post()
  create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateSavedMealDto) {
    return this.savedMealsService.create(user.id, dto);
  }

  @Delete(':id')
  delete(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.savedMealsService.delete(user.id, id);
  }

  @Post(':id/log')
  logMeal(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: LogSavedMealDto,
  ) {
    return this.savedMealsService.logMeal(user.id, id, dto);
  }
}
