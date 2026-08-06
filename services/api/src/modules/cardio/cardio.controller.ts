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
import { CardioService } from './cardio.service';
import { CreateCardioSessionDto } from './dto/create-cardio-session.dto';
import { QueryCardioSessionsDto } from './dto/query-cardio-sessions.dto';
import { UpdateCardioSessionDto } from './dto/update-cardio-session.dto';

@ApiBearerAuth()
@ApiTags('cardio')
@Controller('cardio-sessions')
export class CardioController {
  constructor(private readonly cardioService: CardioService) {}

  @Get()
  list(@CurrentUser() user: AuthenticatedUser, @Query() query: QueryCardioSessionsDto) {
    return this.cardioService.list(user.id, query);
  }

  @Get(':id')
  getById(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.cardioService.getById(user.id, id);
  }

  @Post()
  create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateCardioSessionDto) {
    return this.cardioService.create(user.id, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: UpdateCardioSessionDto,
  ) {
    return this.cardioService.update(user.id, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  delete(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.cardioService.delete(user.id, id);
  }
}
