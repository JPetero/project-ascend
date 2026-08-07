import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AuditModule } from './common/audit/audit.module';
import { IdempotencyModule } from './common/idempotency/idempotency.module';
import { AchievementsModule } from './modules/achievements/achievements.module';
import { AdminModule } from './modules/admin/admin.module';
import { AuthModule } from './modules/auth/auth.module';
import { AuthIdentitiesModule } from './modules/auth-identities/auth-identities.module';
import { JwtAuthGuard } from './modules/auth/guards/jwt-auth.guard';
import { CardioModule } from './modules/cardio/cardio.module';
import { ChallengesModule } from './modules/challenges/challenges.module';
import { CommunityModule } from './modules/community/community.module';
import { RankingsModule } from './modules/rankings/rankings.module';
import configuration from './config/configuration';
import { validateEnv } from './config/env.validation';
import { DeloadModule } from './modules/deload/deload.module';
import { DevicesModule } from './modules/devices/devices.module';
import { EntitlementsModule } from './common/entitlements/entitlements.module';
import { EquipmentTypesModule } from './modules/equipment-types/equipment-types.module';
import { ExerciseCategoriesModule } from './modules/exercise-categories/exercise-categories.module';
import { ExercisesModule } from './modules/exercises/exercises.module';
import { FoodsModule } from './modules/foods/foods.module';
import { HealthModule } from './modules/health/health.module';
import { HealthMetricsModule } from './modules/health-metrics/health-metrics.module';
import { LegalModule } from './modules/legal/legal.module';
import { MacroTargetsModule } from './modules/macro-targets/macro-targets.module';
import { MuscleGroupsModule } from './modules/muscle-groups/muscle-groups.module';
import { NutritionLogModule } from './modules/nutrition-log/nutrition-log.module';
import { PersonalRecordsModule } from './modules/personal-records/personal-records.module';
import { PreferencesModule } from './modules/preferences/preferences.module';
import { ProfilesModule } from './modules/profiles/profiles.module';
import { PromoteModule } from './modules/promote/promote.module';
import { SavedMealsModule } from './modules/saved-meals/saved-meals.module';
import { SubscriptionsModule } from './modules/subscriptions/subscriptions.module';
import { SupportModule } from './modules/support/support.module';
import { TrainerGroupsModule } from './modules/trainer-groups/trainer-groups.module';
import { UsersModule } from './modules/users/users.module';
import { WaterModule } from './modules/water/water.module';
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
    IdempotencyModule,
    EntitlementsModule,
    AuthModule,
    AuthIdentitiesModule,
    LegalModule,
    DeloadModule,
    UsersModule,
    ProfilesModule,
    PreferencesModule,
    DevicesModule,
    HealthModule,
    HealthMetricsModule,
    ExerciseCategoriesModule,
    MuscleGroupsModule,
    EquipmentTypesModule,
    ExercisesModule,
    WorkoutsModule,
    WorkoutPlansModule,
    PersonalRecordsModule,
    WorkoutSessionsModule,
    WorkoutHistoryModule,
    FoodsModule,
    NutritionLogModule,
    MacroTargetsModule,
    WaterModule,
    SavedMealsModule,
    AchievementsModule,
    CardioModule,
    CommunityModule,
    TrainerGroupsModule,
    RankingsModule,
    ChallengesModule,
    SubscriptionsModule,
    SupportModule,
    AdminModule,
    PromoteModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_GUARD, useClass: JwtAuthGuard },
  ],
})
export class AppModule {}
