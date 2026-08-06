/**
 * Reusable unit conversions. The database and API always store/return
 * canonical metric units (kg, meters, kcal, ml, seconds) — these helpers
 * exist for the *display* boundary (a future imperial-preference UI, a
 * report, a client-side formatter), not for changing what's persisted.
 * Nothing here is Workout- or Nutrition-specific.
 */

const KG_PER_LB = 0.45359237;
const METERS_PER_MILE = 1609.344;
const METERS_PER_FOOT = 0.3048;
const ML_PER_FL_OZ = 29.5735;
const KCAL_PER_KJ = 0.239006;

export function kgToLb(kg: number): number {
  return kg / KG_PER_LB;
}

export function lbToKg(lb: number): number {
  return lb * KG_PER_LB;
}

export function metersToMiles(meters: number): number {
  return meters / METERS_PER_MILE;
}

export function milesToMeters(miles: number): number {
  return miles * METERS_PER_MILE;
}

export function metersToFeet(meters: number): number {
  return meters / METERS_PER_FOOT;
}

export function feetToMeters(feet: number): number {
  return feet * METERS_PER_FOOT;
}

export function mlToFlOz(ml: number): number {
  return ml / ML_PER_FL_OZ;
}

export function flOzToMl(flOz: number): number {
  return flOz * ML_PER_FL_OZ;
}

export function kcalToKj(kcal: number): number {
  return kcal / KCAL_PER_KJ;
}

export function kjToKcal(kj: number): number {
  return kj * KCAL_PER_KJ;
}

export function secondsToMinutes(seconds: number): number {
  return seconds / 60;
}

export function minutesToSeconds(minutes: number): number {
  return minutes * 60;
}

export function secondsToHoursMinutes(seconds: number): { hours: number; minutes: number } {
  const totalMinutes = Math.floor(seconds / 60);
  return { hours: Math.floor(totalMinutes / 60), minutes: totalMinutes % 60 };
}

export enum UnitSystem {
  METRIC = 'METRIC',
  IMPERIAL = 'IMPERIAL',
}

/** Formats a weight for display in the given unit system, rounded to one
 * decimal place — the same rounding discipline used throughout the
 * Nutrition macro snapshots, applied here for consistency. */
export function formatWeightKg(kg: number, system: UnitSystem): string {
  if (system === UnitSystem.IMPERIAL) {
    return `${round1(kgToLb(kg))} lb`;
  }
  return `${round1(kg)} kg`;
}

export function formatDistanceMeters(meters: number, system: UnitSystem): string {
  if (system === UnitSystem.IMPERIAL) {
    return meters >= METERS_PER_MILE
      ? `${round1(metersToMiles(meters))} mi`
      : `${round1(metersToFeet(meters))} ft`;
  }
  return meters >= 1000 ? `${round1(meters / 1000)} km` : `${round1(meters)} m`;
}

function round1(value: number): number {
  return Math.round(value * 10) / 10;
}
