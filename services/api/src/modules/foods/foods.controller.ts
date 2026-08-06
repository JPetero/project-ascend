import {
  Body,
  Controller,
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
import { CreateFoodDto } from './dto/create-food.dto';
import { QueryFoodsDto } from './dto/query-foods.dto';
import { UpdateFoodDto } from './dto/update-food.dto';
import { FoodsService } from './foods.service';

@ApiBearerAuth()
@ApiTags('foods')
@Controller('foods')
export class FoodsController {
  constructor(private readonly foodsService: FoodsService) {}

  @Get()
  search(@CurrentUser() user: AuthenticatedUser, @Query() query: QueryFoodsDto) {
    return this.foodsService.search(user.id, query);
  }

  @Get(':id')
  getById(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.foodsService.getById(user.id, id);
  }

  @Post()
  createCustom(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateFoodDto) {
    return this.foodsService.createCustom(user.id, dto);
  }

  @Patch(':id')
  updateCustom(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: UpdateFoodDto,
  ) {
    return this.foodsService.updateCustom(user.id, id, dto);
  }

  @Post(':id/archive')
  @HttpCode(HttpStatus.OK)
  archiveCustom(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.foodsService.archiveCustom(user.id, id);
  }
}
