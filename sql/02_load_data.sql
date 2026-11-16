SET search_path TO duolingo;

COPY languages FROM '/FULL/PATH/seed_data/languages.csv' WITH CSV HEADER;
COPY courses FROM '/FULL/PATH/seed_data/courses.csv' WITH CSV HEADER;
COPY units FROM '/FULL/PATH/seed_data/units.csv' WITH CSV HEADER;
COPY lessons FROM '/FULL/PATH/seed_data/lessons.csv' WITH CSV HEADER;
COPY learners FROM '/FULL/PATH/seed_data/learners.csv' WITH CSV HEADER;
COPY achievements FROM '/FULL/PATH/seed_data/achievements.csv' WITH CSV HEADER;
COPY enrollments FROM '/FULL/PATH/seed_data/enrollments.csv' WITH CSV HEADER;
COPY lesson_attempts FROM '/FULL/PATH/seed_data/lesson_attempts.csv' WITH CSV HEADER;
COPY daily_activity FROM '/FULL/PATH/seed_data/daily_activity.csv' WITH CSV HEADER;
COPY league_memberships FROM '/FULL/PATH/seed_data/league_memberships.csv' WITH CSV HEADER;
COPY learner_achievements FROM '/FULL/PATH/seed_data/learner_achievements.csv' WITH CSV HEADER;

ANALYZE;

SELECT 'languages' AS table_name, COUNT(*) AS total FROM languages
UNION ALL
SELECT 'courses', COUNT(*) FROM courses
UNION ALL
SELECT 'units', COUNT(*) FROM units
UNION ALL
SELECT 'lessons', COUNT(*) FROM lessons
UNION ALL
SELECT 'learners', COUNT(*) FROM learners
UNION ALL
SELECT 'achievements', COUNT(*) FROM achievements
UNION ALL
SELECT 'enrollments', COUNT(*) FROM enrollments
UNION ALL
SELECT 'lesson_attempts', COUNT(*) FROM lesson_attempts
UNION ALL
SELECT 'daily_activity', COUNT(*) FROM daily_activity
UNION ALL
SELECT 'league_memberships', COUNT(*) FROM league_memberships
UNION ALL
SELECT 'learner_achievements', COUNT(*) FROM learner_achievements;
