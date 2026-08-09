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
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { CommunityService } from './community.service';
import { CreateCommunityCommentDto } from './dto/create-community-comment.dto';
import { CreateCommunityPostDto } from './dto/create-community-post.dto';
import { CreateCommunityReportDto } from './dto/create-community-report.dto';
import { QueryCommunityPostsDto } from './dto/query-community-posts.dto';
import { UpsertCommunityProfileDto } from './dto/upsert-community-profile.dto';

@ApiBearerAuth()
@ApiTags('community')
@Controller('community')
export class CommunityController {
  constructor(private readonly communityService: CommunityService) {}

  @Post('profile')
  upsertOwnProfile(@CurrentUser() user: AuthenticatedUser, @Body() dto: UpsertCommunityProfileDto) {
    return this.communityService.upsertOwnProfile(user.id, dto);
  }

  @Get('profile/:userId')
  getProfile(@CurrentUser() user: AuthenticatedUser, @Param('userId') userId: string) {
    return this.communityService.getProfile(user.id, userId);
  }

  @Post('posts')
  createPost(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateCommunityPostDto) {
    return this.communityService.createPost(user.id, dto);
  }

  @Get('posts')
  listFeed(@CurrentUser() user: AuthenticatedUser, @Query() query: QueryCommunityPostsDto) {
    return this.communityService.listFeed(user.id, query);
  }

  @Get('posts/saved')
  listSaved(@CurrentUser() user: AuthenticatedUser, @Query() query: QueryCommunityPostsDto) {
    return this.communityService.listSaved(user.id, query);
  }

  @Get('analytics/me')
  getMyContentAnalytics(@CurrentUser() user: AuthenticatedUser) {
    return this.communityService.getMyContentAnalytics(user.id);
  }

  @Get('posts/:id')
  getPost(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.communityService.getPost(user.id, id);
  }

  @Delete('posts/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  deletePost(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.communityService.deletePost(user.id, id);
  }

  @Post('posts/:id/like')
  @HttpCode(HttpStatus.NO_CONTENT)
  like(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.communityService.like(user.id, id);
  }

  @Delete('posts/:id/like')
  @HttpCode(HttpStatus.NO_CONTENT)
  unlike(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.communityService.unlike(user.id, id);
  }

  @Post('posts/:id/save')
  @HttpCode(HttpStatus.NO_CONTENT)
  save(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.communityService.save(user.id, id);
  }

  @Delete('posts/:id/save')
  @HttpCode(HttpStatus.NO_CONTENT)
  unsave(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.communityService.unsave(user.id, id);
  }

  @Post('posts/:id/comments')
  addComment(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() dto: CreateCommunityCommentDto,
  ) {
    return this.communityService.addComment(user.id, id, dto);
  }

  @Get('posts/:id/comments')
  listComments(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Query() query: QueryCommunityPostsDto,
  ) {
    return this.communityService.listComments(user.id, id, query);
  }

  @Delete('comments/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  deleteComment(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.communityService.deleteComment(user.id, id);
  }

  @Post('follow/:userId')
  @HttpCode(HttpStatus.NO_CONTENT)
  follow(@CurrentUser() user: AuthenticatedUser, @Param('userId') userId: string) {
    return this.communityService.follow(user.id, userId);
  }

  @Delete('follow/:userId')
  @HttpCode(HttpStatus.NO_CONTENT)
  unfollow(@CurrentUser() user: AuthenticatedUser, @Param('userId') userId: string) {
    return this.communityService.unfollow(user.id, userId);
  }

  @Get('follow/:userId/followers')
  listFollowers(@Param('userId') userId: string, @Query() query: QueryCommunityPostsDto) {
    return this.communityService.listFollowers(userId, query);
  }

  @Get('follow/:userId/following')
  listFollowing(@Param('userId') userId: string, @Query() query: QueryCommunityPostsDto) {
    return this.communityService.listFollowing(userId, query);
  }

  @Get('blocks')
  listBlocked(@CurrentUser() user: AuthenticatedUser) {
    return this.communityService.listBlocked(user.id);
  }

  @Post('block/:userId')
  @HttpCode(HttpStatus.NO_CONTENT)
  block(@CurrentUser() user: AuthenticatedUser, @Param('userId') userId: string) {
    return this.communityService.block(user.id, userId);
  }

  @Delete('block/:userId')
  @HttpCode(HttpStatus.NO_CONTENT)
  unblock(@CurrentUser() user: AuthenticatedUser, @Param('userId') userId: string) {
    return this.communityService.unblock(user.id, userId);
  }

  @Post('reports')
  report(@CurrentUser() user: AuthenticatedUser, @Body() dto: CreateCommunityReportDto) {
    return this.communityService.report(user.id, dto);
  }
}
