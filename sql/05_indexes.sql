-- CP3: apply once to the seed database; no server configuration changes.
SET search_path TO duolingo;
-- R04/R06: learner equality first, then timestamp range; cover daily XP reads.
CREATE INDEX idx_attempt_learner_started ON lesson_attempts (learner_id, started_at) INCLUDE (xp_earned, lesson_id, completed_at);
-- R19: lesson equality groups with mistakes/completion covered; also supports R07 joins.
CREATE INDEX idx_attempt_lesson ON lesson_attempts (lesson_id) INCLUDE (mistakes, completed_at);
-- R20/R22: ordered timestamps avoid deep-pagination sort and enable range filtering.
CREATE INDEX idx_attempt_started ON lesson_attempts (started_at DESC) INCLUDE (attempt_id, learner_id, lesson_id, xp_earned);
-- W02: small partial B-tree contains only unfinished attempts; descending ID supports max; timestamp is covered for filtering.
CREATE INDEX idx_attempt_unfinished ON lesson_attempts (attempt_id DESC) INCLUDE (started_at) WHERE completed_at IS NULL;
-- R09/R21/R23: date first for platform date ranges, learner next for joining/grouping.
CREATE INDEX idx_activity_date ON daily_activity (activity_date, learner_id) INCLUDE (xp);
-- R05/W04: week equality then cohort for leaderboard/ranking; covers learner and XP.
CREATE INDEX idx_league_week_cohort ON league_memberships (week_start, cohort_id, weekly_xp DESC, learner_id);
-- R13: anti-join on referral target; excludes NULLs because equality cannot match them.
CREATE INDEX idx_learner_referral ON learners (referred_by) WHERE referred_by IS NOT NULL;
-- R15: narrow January timestamp range; cover learner ID for retention probe.
CREATE INDEX idx_learner_joined ON learners (joined_at) INCLUDE (learner_id);
ANALYZE;
