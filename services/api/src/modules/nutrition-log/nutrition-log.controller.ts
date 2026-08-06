import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { CopyMealEntriesDto } from './dto/copy-meal-entries.dto';
import { CreateMealEntryDto } from './dto/create-meal-entry.dto';
import { QueryDailyLogDto } from './dto/query-daily-log.dto';
import { QuerySevenDaySummaryDto } from './dto/query-seven-day-summary.dto';
import { UpdateMealEntryDto } from './dto/update-meal-entry.dto';
import { NutritionLogService } from './nutrition-log.service';

@ApiBearerAuth()
@ApiTags('nutrition-log')
@Controller('nutrition-log')
export class NutritionLogController {
  constructor(private readonly nutritionLogService: NutritionLogService) {}

  @Get()
  getDaily(@CurrentUser() user: AuthenticatedUser, @Query() query: QueryDailyLogDto) {
    return this.nutritionLogService.getDaily(user.id, query.date);
  }

  @Get('summary')
  getDailySummary(@CurrentUser() user: AuthenticatedUser, @Query() query: QueryDailyLogDto) {
    return this.nutritionLogService.getDailySummary(user.id, query.date);
  }

  @Get('summary/seven-day')
  getSevenDaySummary(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: QuerySevenDaySummaryDto,
  ) {
    return this.nutritionLogService.getSevenDaySummary(user.id, query.endDate);
  }

  @Post()
  addEntry(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateMealEntryDto) {
    return this.nutritionLogService.addEntry(user.id, dto);
  }

  @Post('copy')
  copyEntries(@CurrentUser() user: AuthenticatedUser, @Body() dto: CopyMealEntriesDto) {
    return this.nutritionLogService.copyEntries(user.id, dto);
  }

  @Patch(':id')
  updateEntry(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: UpdateMealEntryDto,
  ) {
    return this.nutritionLogService.updateEntry(user.id, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  deleteEntry(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.nutritionLogService.deleteEntry(user.id, id);
  }
}
