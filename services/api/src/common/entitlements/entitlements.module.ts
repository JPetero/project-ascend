import { Global, Module } from '@nestjs/common';
import { AiEntitlementService } from './ai-entitlement.service';
import { CapabilityService } from './capability.service';

@Global()
@Module({
  providers: [CapabilityService, AiEntitlementService],
  exports: [CapabilityService, AiEntitlementService],
})
export class EntitlementsModule {}
