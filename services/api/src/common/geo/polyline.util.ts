/**
 * Google's encoded polyline algorithm (precision 5) — a compact,
 * dependency-free way to store a route's lat/lng points as one string
 * instead of a JSON array, used by CardioService for LIVE_GPS sessions.
 * See https://developers.google.com/maps/documentation/utilities/polylinealgorithm
 * for the reference algorithm this implements.
 */

export interface LatLng {
  lat: number;
  lng: number;
}

const PRECISION = 1e5;

function encodeSignedNumber(num: number): string {
  let sgnNum = num << 1;
  if (num < 0) sgnNum = ~sgnNum;
  let result = '';
  while (sgnNum >= 0x20) {
    result += String.fromCharCode((0x20 | (sgnNum & 0x1f)) + 63);
    sgnNum >>= 5;
  }
  result += String.fromCharCode(sgnNum + 63);
  return result;
}

export function encodePolyline(points: LatLng[]): string {
  let encoded = '';
  let prevLat = 0;
  let prevLng = 0;

  for (const point of points) {
    const lat = Math.round(point.lat * PRECISION);
    const lng = Math.round(point.lng * PRECISION);
    encoded += encodeSignedNumber(lat - prevLat);
    encoded += encodeSignedNumber(lng - prevLng);
    prevLat = lat;
    prevLng = lng;
  }

  return encoded;
}

export function decodePolyline(encoded: string): LatLng[] {
  const points: LatLng[] = [];
  let index = 0;
  let lat = 0;
  let lng = 0;

  while (index < encoded.length) {
    let shift = 0;
    let result = 0;
    let byte: number;
    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    lat += result & 1 ? ~(result >> 1) : result >> 1;

    shift = 0;
    result = 0;
    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    lng += result & 1 ? ~(result >> 1) : result >> 1;

    points.push({ lat: lat / PRECISION, lng: lng / PRECISION });
  }

  return points;
}

/**
 * Drops the first/last `count` points from a route — used to honor
 * hideStartLocation/hideEndLocation by discarding the points near a
 * session's exact start/end *before* anything is ever persisted, rather
 * than merely filtering them out of API responses later. A route with
 * fewer than `count * 2` points after trimming both ends is trimmed as
 * much as safely possible without going negative, never wrapping around.
 */
export function trimEndpoints(
  points: LatLng[],
  { trimStart, trimEnd, count = 5 }: { trimStart: boolean; trimEnd: boolean; count?: number },
): LatLng[] {
  if (!trimStart && !trimEnd) return points;

  const startTrim = trimStart ? Math.min(count, points.length) : 0;
  const remaining = points.length - startTrim;
  const endTrim = trimEnd ? Math.min(count, remaining) : 0;
  const endIndex = points.length - endTrim;

  if (startTrim >= endIndex) return [];
  return points.slice(startTrim, endIndex);
}
