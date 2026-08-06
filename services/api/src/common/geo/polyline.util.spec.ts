import { decodePolyline, encodePolyline, trimEndpoints } from './polyline.util';

describe('polyline.util', () => {
  describe('encodePolyline / decodePolyline', () => {
    it('round-trips a simple route within floating-point precision', () => {
      const points = [
        { lat: 38.5, lng: -120.2 },
        { lat: 40.7, lng: -120.95 },
        { lat: 43.252, lng: -126.453 },
      ];

      const encoded = encodePolyline(points);
      const decoded = decodePolyline(encoded);

      expect(decoded).toHaveLength(points.length);
      decoded.forEach((point, i) => {
        expect(point.lat).toBeCloseTo(points[i].lat, 4);
        expect(point.lng).toBeCloseTo(points[i].lng, 4);
      });
    });

    it("matches the known reference example from Google's algorithm spec", () => {
      const points = [
        { lat: 38.5, lng: -120.2 },
        { lat: 40.7, lng: -120.95 },
        { lat: 43.252, lng: -126.453 },
      ];
      expect(encodePolyline(points)).toBe('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
    });

    it('round-trips negative-delta (southbound/westbound) points', () => {
      const points = [
        { lat: 14.6091, lng: 121.0223 },
        { lat: 14.5, lng: 120.9 },
        { lat: 14.4, lng: 120.8 },
      ];
      const decoded = decodePolyline(encodePolyline(points));
      decoded.forEach((point, i) => {
        expect(point.lat).toBeCloseTo(points[i].lat, 4);
        expect(point.lng).toBeCloseTo(points[i].lng, 4);
      });
    });

    it('handles an empty route', () => {
      expect(encodePolyline([])).toBe('');
      expect(decodePolyline('')).toEqual([]);
    });
  });

  describe('trimEndpoints', () => {
    const points = Array.from({ length: 20 }, (_, i) => ({ lat: i, lng: i }));

    it('returns the same points when neither end is trimmed', () => {
      expect(trimEndpoints(points, { trimStart: false, trimEnd: false })).toEqual(points);
    });

    it('drops the first `count` points when trimStart is set', () => {
      const result = trimEndpoints(points, { trimStart: true, trimEnd: false, count: 5 });
      expect(result).toHaveLength(15);
      expect(result[0]).toEqual({ lat: 5, lng: 5 });
    });

    it('drops the last `count` points when trimEnd is set', () => {
      const result = trimEndpoints(points, { trimStart: false, trimEnd: true, count: 5 });
      expect(result).toHaveLength(15);
      expect(result.at(-1)).toEqual({ lat: 14, lng: 14 });
    });

    it('drops from both ends when both flags are set', () => {
      const result = trimEndpoints(points, { trimStart: true, trimEnd: true, count: 5 });
      expect(result).toHaveLength(10);
      expect(result[0]).toEqual({ lat: 5, lng: 5 });
      expect(result.at(-1)).toEqual({ lat: 14, lng: 14 });
    });

    it('never goes negative — a short route trimmed on both ends returns empty, not wrapped', () => {
      const short = Array.from({ length: 6 }, (_, i) => ({ lat: i, lng: i }));
      const result = trimEndpoints(short, { trimStart: true, trimEnd: true, count: 5 });
      expect(result).toEqual([]);
    });
  });
});
