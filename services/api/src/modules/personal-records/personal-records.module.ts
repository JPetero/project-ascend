import { Module } from '@nestjs/common';
import { PersonalRecordsController } from './personal-records.controller';
import { PersonalRecordsService } from './personal-records.service';

@Module({
  controllers: [PersonalRecordsController],
  providers: [PersonalRecordsService],
  exports: [PersonalRecordsService],
})
export class PersonalRecordsModule {}
