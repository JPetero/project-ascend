import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { PaginationQueryDto } from '../../common/pagination/pagination-query.dto';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { ChallengesService } from './challenges.service';
import { CreateChallengeDto } from './dto/create-challenge.dto';

@ApiBearerAuth()
@ApiTags('challenges')
@Controller('challenges')
export class ChallengesController {
  constructor(private readonly challengesService: ChallengesService) {}

  @Post()
  create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateChallengeDto) {
    return this.challengesService.create(user.id, dto);
  }

  @Get()
  listMine(@CurrentUser() user: AuthenticatedUser) {
    return this.challengesService.listMine(user.id);
  }

  // Registered ahead of GET /:id so "discover" is never mistaken for a
  // challenge id.
  @Get('discover')
  listDiscoverable(@CurrentUser() user: AuthenticatedUser, @Query() query: PaginationQueryDto) {
    return this.challengesService.listDiscoverable(user.id, query);
  }

  @Get(':id')
  getById(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.challengesService.getById(user.id, id);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  delete(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.challengesService.delete(user.id, id);
  }

  @Post(':id/join')
  @HttpCode(HttpStatus.NO_CONTENT)
  join(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.challengesService.join(user.id, id);
  }

  @Delete(':id/leave')
  @HttpCode(HttpStatus.NO_CONTENT)
  leave(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.challengesService.leave(user.id, id);
  }
}
