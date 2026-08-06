import { Module } from '@nestjs/common';
import { DeloadController } from './deload.controller';
import { DeloadService } from './deload.service';

@Module({
  controllers: [DeloadController],
  providers: [DeloadService],
})
export class DeloadModule {}
