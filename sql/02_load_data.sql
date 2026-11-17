SET search_path TO duolingo;

\copy languages FROM 'seed_data/languages.csv' WITH (FORMAT csv, HEADER true)
\copy courses FROM 'seed_data/courses.csv' WITH (FORMAT csv, HEADER true)
\copy units FROM 'seed_data/units.csv' WITH (FORMAT csv, HEADER true)
\copy lessons FROM 'seed_data/lessons.csv' WITH (FORMAT csv, HEADER true)
\copy learners FROM 'seed_data/learners.csv' WITH (FORMAT csv, HEADER true)
\copy achievements FROM 'seed_data/achievements.csv' WITH (FORMAT csv, HEADER true)
\copy enrollments FROM 'seed_data/enrollments.csv' WITH (FORMAT csv, HEADER true)
\copy lesson_attempts FROM 'seed_data/lesson_attempts.csv' WITH (FORMAT csv, HEADER true)
\copy daily_activity FROM 'seed_data/daily_activity.csv' WITH (FORMAT csv, HEADER true)
\copy league_memberships FROM 'seed_data/league_memberships.csv' WITH (FORMAT csv, HEADER true)
\copy learner_achievements FROM 'seed_data/learner_achievements.csv' WITH (FORMAT csv, HEADER true)

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
