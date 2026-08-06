import { paginationArgs, paginationMeta } from './pagination-query.dto';

describe('pagination-query.dto', () => {
  it('derives skip/take from page and limit', () => {
    expect(paginationArgs({ page: 1, limit: 20 })).toEqual({ skip: 0, take: 20 });
    expect(paginationArgs({ page: 3, limit: 10 })).toEqual({ skip: 20, take: 10 });
  });

  it('builds pagination metadata carrying the total through unchanged', () => {
    expect(paginationMeta({ page: 2, limit: 15 }, 47)).toEqual({
      page: 2,
      limit: 15,
      total: 47,
    });
  });
});
