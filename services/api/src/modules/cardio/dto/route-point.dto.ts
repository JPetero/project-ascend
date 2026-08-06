import { ApiProperty } from '@nestjs/swagger';
import { IsInt, IsLatitude, IsLongitude, Min } from 'class-validator';

/**
 * One recorded point of a LIVE_GPS session's route. Deliberately minimal
 * — `t` is elapsed seconds since the session started (a small int, not a
 * full timestamp) to keep the wire payload compact; GPS-accuracy
 * filtering happens client-side before a point is ever queued for
 * upload (see the Flutter live-tracking controller), so the backend
 * never needs a per-point accuracy value.
 */
export class RoutePointDto {
  @ApiProperty()
  @IsLatitude()
  lat!: number;

  @ApiProperty()
  @IsLongitude()
  lng!: number;

  @ApiProperty({ description: 'Elapsed seconds since the session started.' })
  @IsInt()
  @Min(0)
  t!: number;
}
