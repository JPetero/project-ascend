import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthIdentitiesController } from './auth-identities.controller';
import { AuthIdentitiesService } from './auth-identities.service';
import { AppleTokenVerifier } from './providers/apple-token-verifier';
import { GoogleTokenVerifier } from './providers/google-token-verifier';

@Module({
  imports: [ConfigModule],
  controllers: [AuthIdentitiesController],
  providers: [AuthIdentitiesService, GoogleTokenVerifier, AppleTokenVerifier],
  exports: [AuthIdentitiesService, GoogleTokenVerifier, AppleTokenVerifier],
})
export class AuthIdentitiesModule {}
