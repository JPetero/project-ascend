import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/decorators/public.decorator';
import { PrismaService } from '../../prisma/prisma.service';

/**
 * Liveness/readiness split (S14 Part 6). Before this, a single
 * `GET /health` queried Postgres and was used for both purposes —
 * meaning a database blip made an orchestrator conclude the *process*
 * needed restarting, when the process was actually fine and the
 * database would recover on its own. `/livez` and `/readyz` answer two
 * genuinely different questions now; `/health` stays as a
 * backward-compatible alias for whatever already points at it (see
 * infrastructure/docker/api.Dockerfile).
 */
@ApiTags('health')
@Controller()
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * "Is the Nest process itself alive and able to handle an HTTP
   * request?" Never touches the database or any other dependency —
   * that's exactly the point. Use this for a Kubernetes-style liveness
   * probe, where a false "unhealthy" during a transient database issue
   * would cause an unnecessary (and unhelpful — restarting the process
   * doesn't fix the database) container restart.
   */
  @Public()
  @Get('livez')
  live() {
    return { status: 'ok', timestamp: new Date().toISOString() };
  }

  /**
   * "Can this instance actually serve real requests right now?" Checks
   * only genuinely core infrastructure — the database, the one
   * dependency every request in this app ultimately touches. Optional
   * feature providers (AI, Research, remote push, media storage, IAP
   * verification) are deliberately excluded: each already degrades its
   * own feature honestly when unconfigured (e.g. NoopResearchProvider's
   * 503) rather than needing to take Workout/Nutrition/the rest of the
   * app down with it. See `GET /admin/release-readiness` for the full
   * per-integration configuration picture instead of folding all of it
   * into this endpoint.
   */
  @Public()
  @Get('readyz')
  async ready() {
    await this.checkDatabase();
    return { status: 'ok', timestamp: new Date().toISOString() };
  }

  /**
   * Deprecated alias, semantically identical to `/readyz` (this is
   * what `/health` always checked). Kept only so the Docker
   * HEALTHCHECK and any pre-existing external monitoring already
   * pointed at `/health` keep working unchanged; point anything new at
   * `/livez` or `/readyz` directly instead.
   */
  @Public()
  @Get('health')
  async legacyHealth() {
    await this.checkDatabase();
    return { status: 'ok', timestamp: new Date().toISOString() };
  }

  private async checkDatabase(): Promise<void> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
    } catch {
      throw new ServiceUnavailableException('Database is unreachable.');
    }
  }
}
