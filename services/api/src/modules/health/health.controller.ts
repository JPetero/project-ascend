import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/decorators/public.decorator';
import { PrismaService } from '../../prisma/prisma.service';

@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * A liveness check that doesn't verify the database would let the
   * container (and Docker's HEALTHCHECK) report "healthy" while unable to
   * serve any real request — so this doubles as a lightweight readiness
   * check.
   */
  @Public()
  @Get()
  async check() {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
    } catch {
      throw new ServiceUnavailableException('Database is unreachable.');
    }
    return { status: 'ok', timestamp: new Date().toISOString() };
  }
}
