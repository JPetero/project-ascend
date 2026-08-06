/**
 * Small enums genuinely shared across domains, collected here as one
 * discoverable import point rather than redeclared per-module. Re-exports
 * `SortOrder`/`UnitSystem` from their owning modules so a consumer that
 * just wants "the common enums" doesn't need to know which sub-module
 * each one actually lives in.
 */
export { SortOrder } from '../pagination/pagination-query.dto';
export { UnitSystem } from '../units/units.util';

export enum DayOfWeek {
  SUNDAY = 0,
  MONDAY = 1,
  TUESDAY = 2,
  WEDNESDAY = 3,
  THURSDAY = 4,
  FRIDAY = 5,
  SATURDAY = 6,
}
