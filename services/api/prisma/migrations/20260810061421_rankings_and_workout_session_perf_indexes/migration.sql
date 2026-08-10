-- CreateIndex
CREATE INDEX "ranking_opt_ins_scope_regionLabel_idx" ON "ranking_opt_ins"("scope", "regionLabel");

-- CreateIndex
CREATE INDEX "workout_sessions_userId_status_completedAt_idx" ON "workout_sessions"("userId", "status", "completedAt");
