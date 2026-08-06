import {
  feetToMeters,
  flOzToMl,
  formatDistanceMeters,
  formatWeightKg,
  kcalToKj,
  kgToLb,
  kjToKcal,
  lbToKg,
  metersToFeet,
  metersToMiles,
  milesToMeters,
  minutesToSeconds,
  mlToFlOz,
  secondsToHoursMinutes,
  secondsToMinutes,
  UnitSystem,
} from './units.util';

describe('units.util', () => {
  it('round-trips weight conversions', () => {
    expect(kgToLb(1)).toBeCloseTo(2.2046, 3);
    expect(lbToKg(kgToLb(80))).toBeCloseTo(80, 5);
  });

  it('round-trips distance conversions', () => {
    expect(milesToMeters(1)).toBeCloseTo(1609.344, 2);
    expect(metersToMiles(milesToMeters(5))).toBeCloseTo(5, 5);
    expect(feetToMeters(metersToFeet(10))).toBeCloseTo(10, 5);
  });

  it('round-trips volume conversions', () => {
    expect(mlToFlOz(flOzToMl(8))).toBeCloseTo(8, 5);
  });

  it('round-trips energy conversions', () => {
    expect(kjToKcal(kcalToKj(500))).toBeCloseTo(500, 5);
  });

  it('converts seconds to minutes and hours/minutes', () => {
    expect(secondsToMinutes(90)).toBe(1.5);
    expect(minutesToSeconds(1.5)).toBe(90);
    expect(secondsToHoursMinutes(3725)).toEqual({ hours: 1, minutes: 2 });
  });

  it('formats weight for the given unit system', () => {
    expect(formatWeightKg(80, UnitSystem.METRIC)).toBe('80 kg');
    expect(formatWeightKg(80, UnitSystem.IMPERIAL)).toBe('176.4 lb');
  });

  it('formats distance for the given unit system, switching units at scale', () => {
    expect(formatDistanceMeters(500, UnitSystem.METRIC)).toBe('500 m');
    expect(formatDistanceMeters(1500, UnitSystem.METRIC)).toBe('1.5 km');
    expect(formatDistanceMeters(200, UnitSystem.IMPERIAL)).toBe('656.2 ft');
    expect(formatDistanceMeters(milesToMeters(2), UnitSystem.IMPERIAL)).toBe('2 mi');
  });
});
