import { Body, Controller, Delete, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { ReportMessageDto } from './dto/report-message.dto';
import { SendMessageDto } from './dto/send-message.dto';
import { SetMutedDto } from './dto/set-muted.dto';
import { StartConversationDto } from './dto/start-conversation.dto';
import { MessagesGateway } from './messages.gateway';
import { MessagesService } from './messages.service';

@ApiBearerAuth()
@ApiTags('messages')
@Controller('messages')
export class MessagesController {
  constructor(
    private readonly messagesService: MessagesService,
    private readonly gateway: MessagesGateway,
  ) {}

  @Get('unread-count')
  unreadCount(@CurrentUser() user: AuthenticatedUser) {
    return this.messagesService.unreadCount(user.id);
  }

  @Get('conversations')
  listConversations(@CurrentUser() user: AuthenticatedUser) {
    return this.messagesService.listConversations(user.id);
  }

  @Post('conversations')
  startConversation(@CurrentUser() user: AuthenticatedUser, @Body() dto: StartConversationDto) {
    return this.messagesService.getOrCreateConversation(user.id, dto.recipientId);
  }

  @Get('conversations/:id/messages')
  getMessages(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.messagesService.getMessages(
      user.id,
      id,
      page ? Number(page) : undefined,
      limit ? Number(limit) : undefined,
    );
  }

  @Post('conversations/:id/messages')
  async sendMessage(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: SendMessageDto,
  ) {
    const message = await this.messagesService.sendMessage(user.id, id, dto);
    this.gateway.emitNewMessage(id, message);
    return message;
  }

  @Post('conversations/:id/read')
  async markRead(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    await this.messagesService.markRead(user.id, id);
    return { read: true };
  }

  @Patch('conversations/:id/mute')
  async setMuted(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: SetMutedDto,
  ) {
    await this.messagesService.setMuted(user.id, id, dto.muted);
    return { muted: dto.muted };
  }

  @Delete('conversations/:id')
  async deleteForSelf(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    await this.messagesService.deleteForSelf(user.id, id);
    return { deleted: true };
  }

  @Post('conversations/:id/accept')
  accept(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.messagesService.acceptConversation(user.id, id);
  }

  @Post('conversations/:id/decline')
  decline(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.messagesService.declineConversation(user.id, id);
  }

  @Post(':messageId/report')
  report(
    @CurrentUser() user: AuthenticatedUser,
    @Param('messageId') messageId: string,
    @Body() dto: ReportMessageDto,
  ) {
    return this.messagesService.reportMessage(user.id, messageId, dto.reason);
  }
}
