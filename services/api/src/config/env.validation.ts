import { plainToInstance } from 'class-transformer';
import {
  IsIn,
  IsNotEmpty,
  IsNumberString,
  IsOptional,
  IsString,
  validateSync,
} from 'class-validator';

class EnvironmentVariables {
  @IsIn(['development', 'test', 'production'])
  @IsOptional()
  NODE_ENV = 'development';

  @IsNumberString()
  @IsOptional()
  PORT = '3000';

  @IsString()
  @IsOptional()
  CORS_ORIGIN = '*';

  @IsString()
  @IsNotEmpty()
  DATABASE_URL!: string;

  @IsString()
  @IsNotEmpty()
  JWT_ACCESS_SECRET!: string;

  @IsString()
  @IsNotEmpty()
  JWT_REFRESH_SECRET!: string;

  @IsString()
  @IsOptional()
  JWT_ACCESS_TTL = '15m';

  @IsString()
  @IsOptional()
  JWT_REFRESH_TTL = '30d';

  // Media Platform (Build Session 8 Part 2) — all optional. Defaults to
  // the local development storage provider, which needs none of these.
  @IsIn(['local', 's3'])
  @IsOptional()
  MEDIA_STORAGE_PROVIDER = 'local';

  @IsString()
  @IsOptional()
  MEDIA_S3_ENDPOINT?: string;

  @IsString()
  @IsOptional()
  MEDIA_S3_REGION?: string;

  @IsString()
  @IsOptional()
  MEDIA_S3_BUCKET?: string;

  @IsString()
  @IsOptional()
  MEDIA_S3_ACCESS_KEY_ID?: string;

  @IsString()
  @IsOptional()
  MEDIA_S3_SECRET_ACCESS_KEY?: string;

  @IsString()
  @IsOptional()
  MEDIA_S3_PUBLIC_BASE_URL?: string;
}

/**
 * Fails fast at boot if required secrets/config are missing, per the
 * "fail fast when required secrets are absent in production" requirement.
 */
export function validateEnv(config: Record<string, unknown>) {
  const validatedConfig = plainToInstance(EnvironmentVariables, config, {
    enableImplicitConversion: true,
  });
  const errors = validateSync(validatedConfig, { skipMissingProperties: false });

  if (errors.length > 0) {
    const details = errors
      .flatMap((error) => Object.values(error.constraints ?? {}))
      .join('\n  - ');
    throw new Error(`Invalid environment configuration:\n  - ${details}`);
  }

  if (
    validatedConfig.NODE_ENV === 'production' &&
    (validatedConfig.JWT_ACCESS_SECRET.startsWith('dev_') ||
      validatedConfig.JWT_REFRESH_SECRET.startsWith('dev_'))
  ) {
    throw new Error('Refusing to start in production with development JWT secrets.');
  }

  return validatedConfig;
}
