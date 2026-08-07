import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsBoolean, IsOptional, IsString } from 'class-validator';
import { PaginationQueryDto } from '../../../common/pagination/pagination-query.dto';

export class QueryCommunityPostsDto extends PaginationQueryDto {
  // Omitted: the general feed (own posts + public posts + followed
  // users' followers-only posts, minus anyone blocked). Provided: a
  // single author's posts, still filtered through the same visibility
  // rules relative to the viewer.
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  authorId?: string;

  // Build Session 8 Part 4's "Following" feed mode — restricts results
  // to the caller's own posts plus posts by people they follow (instead
  // of the default "Discover" mode's own + any PUBLIC + followed
  // FOLLOWERS-only posts).
  @ApiPropertyOptional()
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  followingOnly?: boolean;
}
