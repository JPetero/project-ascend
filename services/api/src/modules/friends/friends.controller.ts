import { Body, Controller, Delete, Get, Param, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { SearchUsersDto } from './dto/search-users.dto';
import { SendFriendRequestDto } from './dto/send-friend-request.dto';
import { FriendsService } from './friends.service';

@ApiBearerAuth()
@ApiTags('friends')
@Controller('friends')
export class FriendsController {
  constructor(private readonly friendsService: FriendsService) {}

  @Get('search')
  search(@CurrentUser() user: AuthenticatedUser, @Query() query: SearchUsersDto) {
    return this.friendsService.searchUsers(user.id, query.query);
  }

  @Get('count')
  count(@CurrentUser() user: AuthenticatedUser) {
    return this.friendsService.friendCount(user.id);
  }

  @Get('requests/incoming')
  incoming(@CurrentUser() user: AuthenticatedUser) {
    return this.friendsService.listIncomingRequests(user.id);
  }

  @Get('requests/outgoing')
  outgoing(@CurrentUser() user: AuthenticatedUser) {
    return this.friendsService.listOutgoingRequests(user.id);
  }

  @Post('requests')
  sendRequest(@CurrentUser() user: AuthenticatedUser, @Body() dto: SendFriendRequestDto) {
    return this.friendsService.sendRequest(user.id, dto.recipientId);
  }

  @Post('requests/:id/accept')
  accept(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.friendsService.acceptRequest(user.id, id);
  }

  @Post('requests/:id/decline')
  decline(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.friendsService.declineRequest(user.id, id);
  }

  @Post('requests/:id/cancel')
  cancel(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.friendsService.cancelRequest(user.id, id);
  }

  @Get()
  listFriends(@CurrentUser() user: AuthenticatedUser) {
    return this.friendsService.listFriends(user.id);
  }

  @Delete(':friendId')
  async removeFriend(@CurrentUser() user: AuthenticatedUser, @Param('friendId') friendId: string) {
    await this.friendsService.removeFriend(user.id, friendId);
    return { removed: true };
  }
}
