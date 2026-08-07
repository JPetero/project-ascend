import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/types/jwt-payload.type';
import { QueryHealthSamplesDto } from './dto/query-health-samples.dto';
import { SyncHealthSamplesDto } from './dto/sync-health-samples.dto';
import { HealthMetricsService } from './health-metrics.service';

/**
 * Not `/health` — that path is already the liveness/readiness check
 * (see modules/health/health.controller.ts, public, DB-backed). This is
 * the authenticated Health Connect/HealthKit sample-ingestion API — see
 * packages/docs/wearables.md.
 */
@ApiBearerAuth()
@ApiTags('health-metrics')
@Controller('health-metrics')
export class HealthMetricsController {
  constructor(private readonly healthMetricsService: HealthMetricsService) {}

  @Post('sync')
  sync(@CurrentUser() user: AuthenticatedUser, @Body() dto: SyncHealthSamplesDto) {
    return this.healthMetricsService.sync(user.id, dto);
  }

  @Get('samples')
  listSamples(@CurrentUser() user: AuthenticatedUser, @Query() query: QueryHealthSamplesDto) {
    return this.healthMetricsService.listSamples(user.id, query);
  }

  @Get('sync-status')
  syncStatus(@CurrentUser() user: AuthenticatedUser) {
    return this.healthMetricsService.syncStatus(user.id);
  }
}
