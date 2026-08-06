import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AuditModule } from './common/audit/audit.module';
import { AuthModule } from './modules/auth/auth.module';
import { JwtAuthGuard } from './modules/auth/guards/jwt-auth.guard';
import configuration from './config/configuration';
import { validateEnv } from './config/env.validation';
import { DevicesModule } from './modules/devices/devices.module';
import { EquipmentTypesModule } from './modules/equipment-types/equipment-types.module';
import { ExerciseCategoriesModule } from './modules/exercise-categories/exercise-categories.module';
import { ExercisesModule } from './modules/exercises/exercises.module';
import { HealthModule } from './modules/health/health.module';
import { MuscleGroupsModule } from './modules/muscle-groups/muscle-groups.module';
import { PersonalRecordsModule } from './modules/personal-records/personal-records.module';
import { PreferencesModule } from './modules/preferences/preferences.module';
import { ProfilesModule } from './modules/profiles/profiles.module';
import { UsersModule } from './modules/users/users.module';
import { WorkoutHistoryModule } from './modules/workout-history/workout-history.module';
import { WorkoutPlansModule } from './modules/workout-plans/workout-plans.module';
import { WorkoutSessionsModule } from './modules/workout-sessions/workout-sessions.module';
import { WorkoutsModule } from './modules/workouts/workouts.module';
import { PrismaModule } from './prisma/prisma.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
      validate: validateEnv,
    }),
    ThrottlerModule.forRoot([
      {
        ttl: 60_000,
        limit: 100,
      },
    ]),
    PrismaModule,
    AuditModule,
    AuthModule,
    UsersModule,
    ProfilesModule,
    PreferencesModule,
    DevicesModule,
    HealthModule,
    ExerciseCategoriesModule,
    MuscleGroupsModule,
    EquipmentTypesModule,
    ExercisesModule,
    WorkoutsModule,
    WorkoutPlansModule,
    PersonalRecordsModule,
    WorkoutSessionsModule,
    WorkoutHistoryModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_GUARD, useClass: JwtAuthGuard },
  ],
})
export class AppModule {}
