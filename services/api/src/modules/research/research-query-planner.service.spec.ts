import { ResearchQueryPlannerService } from './research-query-planner.service';

describe('ResearchQueryPlannerService', () => {
  const planner = new ResearchQueryPlannerService();

  it('returns an empty plan for an empty query', () => {
    expect(planner.plan('   ')).toEqual([]);
  });

  it('expands a plain question with an evidence-focused variant', () => {
    const plan = planner.plan('is creatine safe');

    expect(plan).toEqual(['is creatine safe', 'is creatine safe clinical evidence guidelines']);
  });

  it('does not duplicate the expansion when the query already looks evidence-focused', () => {
    expect(planner.plan('shin splints treatment guidelines')).toEqual([
      'shin splints treatment guidelines',
    ]);
    expect(planner.plan('creatine safety systematic review')).toEqual([
      'creatine safety systematic review',
    ]);
  });

  it('trims surrounding whitespace before planning', () => {
    expect(planner.plan('  shin splints  ')).toEqual([
      'shin splints',
      'shin splints clinical evidence guidelines',
    ]);
  });
});
