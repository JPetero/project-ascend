import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsIn, IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export enum SortOrder {
  ASC = 'asc',
  DESC = 'desc',
}

/**
 * Shared page/limit/search/sort shape for any list endpoint — Workout
 * today (exercises, workout plans, workout history), Nutrition and other
 * future domains without re-declaring the same four fields and the same
 * bounds every time. Domain-specific filters (categorySlug, mealType, ...)
 * belong on the subclassing DTO, not here.
 */
export class PaginationQueryDto {
  @ApiPropertyOptional({ default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page: number = 1;

  @ApiPropertyOptional({ default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit: number = 20;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(100)
  search?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(60)
  sortBy?: string;

  @ApiPropertyOptional({ enum: SortOrder, default: SortOrder.ASC })
  @IsOptional()
  @IsIn([SortOrder.ASC, SortOrder.DESC])
  sortOrder: SortOrder = SortOrder.ASC;
}

export interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
}

/** Prisma `skip`/`take` derived from a page/limit pair. */
export function paginationArgs(query: Pick<PaginationQueryDto, 'page' | 'limit'>): {
  skip: number;
  take: number;
} {
  return { skip: (query.page - 1) * query.limit, take: query.limit };
}

export function paginationMeta(
  query: Pick<PaginationQueryDto, 'page' | 'limit'>,
  total: number,
): PaginationMeta {
  return { page: query.page, limit: query.limit, total };
}
