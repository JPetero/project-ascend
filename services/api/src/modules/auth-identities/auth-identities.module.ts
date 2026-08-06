import { Module } from '@nestjs/common';
import { AuthIdentitiesController } from './auth-identities.controller';
import { AuthIdentitiesService } from './auth-identities.service';

@Module({
  controllers: [AuthIdentitiesController],
  providers: [AuthIdentitiesService],
  exports: [AuthIdentitiesService],
})
export class AuthIdentitiesModule {}
