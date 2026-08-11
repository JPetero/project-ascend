import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { AppConfig } from '../../config/configuration';
import { AuthIdentitiesModule } from '../auth-identities/auth-identities.module';
import { EmailModule } from '../email/email.module';
import { UsersModule } from '../users/users.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { SecurityTokenCleanupService } from './security-token-cleanup.service';
import { JwtStrategy } from './strategies/jwt.strategy';

@Module({
  imports: [
    PassportModule,
    UsersModule,
    EmailModule,
    AuthIdentitiesModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => {
        const jwtConfig = configService.get<AppConfig>('app')!.jwt;
        return {
          secret: jwtConfig.accessSecret,
          signOptions: { expiresIn: jwtConfig.accessTtl },
        };
      },
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy, SecurityTokenCleanupService],
  exports: [AuthService, SecurityTokenCleanupService],
})
export class AuthModule {}
