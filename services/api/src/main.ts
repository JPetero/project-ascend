import 'reflect-metadata';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';
import { ResponseEnvelopeInterceptor } from './common/interceptors/response-envelope.interceptor';
import { requestLoggingMiddleware } from './common/middleware/request-logging.middleware';
import { buildHelmetOptions } from './common/middleware/security-headers';
import { AppConfig } from './config/configuration';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const configService = app.get(ConfigService);
  const appConfig = configService.get<AppConfig>('app')!;

  app.use(requestLoggingMiddleware);
  app.use(helmet(buildHelmetOptions()));
  // A wildcard CORS_ORIGIN reflects any request's Origin header back
  // (NestJS/cors' `origin: true`) rather than actually disabling CORS —
  // combined with credentials, that lets any site make credentialed
  // cross-origin requests. Only ever pair `credentials: true` with a
  // real, explicit origin allowlist; env.validation.ts's validateEnv
  // additionally refuses to boot with an unset/wildcard CORS_ORIGIN in
  // production so this can't reach a real deployment silently.
  const isWildcardOrigin = appConfig.corsOrigin === '*';
  app.enableCors({
    origin: isWildcardOrigin ? true : appConfig.corsOrigin.split(','),
    credentials: !isWildcardOrigin,
  });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );
  app.useGlobalFilters(new AllExceptionsFilter());
  app.useGlobalInterceptors(new ResponseEnvelopeInterceptor());
  // Ensures onModuleDestroy (e.g. PrismaService's $disconnect) actually runs
  // when Docker sends SIGTERM on `docker stop`/`docker compose down`.
  app.enableShutdownHooks();

  const swaggerConfig = new DocumentBuilder()
    .setTitle('Project Ascend API')
    .setDescription('Backend API for Project Ascend — fitness, nutrition, and AI companion app.')
    .setVersion('0.1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('docs', app, document);

  await app.listen(appConfig.port);
  // eslint-disable-next-line no-console
  console.log(`Project Ascend API listening on port ${appConfig.port} (env: ${appConfig.nodeEnv})`);
}

void bootstrap();
