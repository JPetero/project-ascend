import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { AddReplyDto } from './dto/add-reply.dto';
import { CreateTicketDto } from './dto/create-ticket.dto';
import { SupportService } from './support.service';

@ApiBearerAuth()
@ApiTags('support')
@Controller('support/tickets')
export class SupportController {
  constructor(private readonly supportService: SupportService) {}

  @Post()
  create(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateTicketDto) {
    return this.supportService.create(user.id, dto);
  }

  @Get()
  listMine(@CurrentUser() user: AuthenticatedUser) {
    return this.supportService.listMine(user.id);
  }

  @Get(':id')
  getMine(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.supportService.getMine(user.id, id);
  }

  @Post(':id/replies')
  addReply(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: AddReplyDto,
  ) {
    return this.supportService.addReply(user.id, id, dto);
  }
}
