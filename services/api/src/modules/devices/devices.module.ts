import { Module } from '@nestjs/common';
import { HealthMetricsModule } from '../health-metrics/health-metrics.module';
import { DevicesController } from './devices.controller';
import { DevicesService } from './devices.service';

@Module({
  imports: [HealthMetricsModule],
  controllers: [DevicesController],
  providers: [DevicesService],
})
export class DevicesModule {}
