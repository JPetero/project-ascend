import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';
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
}
