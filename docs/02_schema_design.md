# Duolingo Language Learning Database
## Schema Design

**Team:** T0077 | Section A  
**Database:** PostgreSQL 18.4  
**Schema:** `duolingo`

## 1. Database Overview

The Duolingo Language Learning Database manages language courses, learner profiles, enrollments, lesson progress, daily activity, weekly leagues, and achievements.

The database consists of 11 relational tables connected through primary and foreign keys. The design supports learner progress tracking, leaderboard rankings, referral management, and learning activity reports.

The schema preserves the column names from the provided dataset to support the existing 30-query SQL workload.

## 2. Tables and Attributes

### 2.1 languages

Stores information about the languages available on the platform.

| Column | Description |
|---|---|
| `language_code` | Primary key; unique language code |
| `language_name` | Language name; unique |

### 2.2 courses

Stores language courses available to learners.

| Column | Description |
|---|---|
| `course_id` | Primary key |
| `from_lang` | Foreign key referencing `languages` |
| `learning_lang` | Foreign key referencing `languages` |
| `title` | Course title |
| `launched_on` | Course launch date |

The combination of `from_lang` and `learning_lang` is unique.

### 2.3 units

Stores units belonging to different courses.

| Column | Description |
|---|---|
| `unit_id` | Primary key |
| `course_id` | Foreign key referencing `courses` |
| `unit_no` | Unit number within the course |
| `title` | Unit title |
| `cefr_level` | Language proficiency level |

The combination of `course_id` and `unit_no` is unique.

### 2.4 lessons

Stores individual lessons within course units.

| Column | Description |
|---|---|
| `lesson_id` | Primary key |
| `unit_id` | Foreign key referencing `units` |
| `lesson_no` | Lesson number within the unit |
| `lesson_type` | Type of lesson |
| `xp_value` | XP awarded for the lesson |

The combination of `unit_id` and `lesson_no` is unique.

### 2.5 learners

Stores learner profiles, account details, subscriptions, and referrals.

| Column | Description |
|---|---|
| `learner_id` | Primary key |
| `username` | Unique learner username |
| `email` | Unique email address |
| `country_code` | Learner's country code |
| `daily_goal_xp` | Daily XP target |
| `subscription` | Subscription category |
| `referred_by` | Foreign key referencing `learners`; nullable |
| `joined_at` | Account creation timestamp |

The `referred_by` column references the same table because learners can refer other learners.

### 2.6 enrollments

Stores learner enrollments in language courses.

| Column | Description |
|---|---|
| `learner_id` | Foreign key referencing `learners` |
| `course_id` | Foreign key referencing `courses` |
| `enrolled_at` | Enrollment timestamp |
| `total_xp` | Total XP earned in the course |
| `is_active` | Enrollment status |

The combination of `learner_id` and `course_id` forms a composite primary key.

### 2.7 lesson_attempts

Records lesson attempts and learning performance.

| Column | Description |
|---|---|
| `attempt_id` | Primary key |
| `learner_id` | Foreign key referencing `learners` |
| `lesson_id` | Foreign key referencing `lessons` |
| `started_at` | Attempt start timestamp |
| `completed_at` | Completion timestamp; nullable |
| `mistakes` | Number of mistakes |
| `hearts_lost` | Hearts lost during the attempt |
| `xp_earned` | XP earned |
| `is_perfect` | Whether the attempt was perfect |
| `device` | Device used for the attempt |

A NULL `completed_at` represents an unfinished lesson attempt.

### 2.8 daily_activity

Stores daily activity summaries for learners.

| Column | Description |
|---|---|
| `learner_id` | Foreign key referencing `learners` |
| `activity_date` | Activity date |
| `xp` | XP earned that day |
| `lessons_completed` | Number of completed lessons |
| `used_streak_freeze` | Whether a streak freeze was used |

The combination of `learner_id` and `activity_date` forms the primary key.

### 2.9 league_memberships

Stores learner participation in weekly leagues.

| Column | Description |
|---|---|
| `learner_id` | Foreign key referencing `learners` |
| `week_start` | Start date of the league week |
| `tier` | League category |
| `cohort_id` | League group identifier |
| `weekly_xp` | XP earned during the week |
| `final_rank` | Final leaderboard position; nullable |
| `result` | League outcome; nullable |

The combination of `learner_id` and `week_start` forms the primary key.

### 2.10 achievements

Stores achievements available on the platform.

| Column | Description |
|---|---|
| `achievement_id` | Primary key |
| `code` | Unique achievement code |
| `name` | Achievement name |

### 2.11 learner_achievements

Records achievements earned by learners.

| Column | Description |
|---|---|
| `learner_id` | Foreign key referencing `learners` |
| `achievement_id` | Foreign key referencing `achievements` |
| `earned_at` | Timestamp when the achievement was earned |

The combination of `learner_id` and `achievement_id` forms the primary key.

## 3. Data Types and Keys

The PostgreSQL schema uses the following data types:

| Data Type | Usage |
|---|---|
| `INTEGER` | IDs, XP totals, and numeric counters |
| `SMALLINT` | Small numeric values such as lesson numbers and mistakes |
| `VARCHAR` | Names, codes, categories, and email addresses |
| `BOOLEAN` | True/false values |
| `DATE` | Calendar dates |
| `TIMESTAMPTZ` | Timestamps for learner and activity events |

**Primary keys** uniquely identify records, while **foreign keys** connect records across tables.

Examples of candidate keys include `learners.username`, `learners.email`, and `achievements.code`. Composite primary keys are used in `enrollments`, `daily_activity`, `league_memberships`, and `learner_achievements`.

The exact column types and constraints are defined in `sql/01_schema.sql`.

## 4. Relationships and Cardinality

| Relationship | Cardinality | Explanation |
|---|---|---|
| Languages – Courses | One-to-many | One language can be associated with multiple courses |
| Courses – Units | One-to-many | One course contains multiple units |
| Units – Lessons | One-to-many | One unit contains multiple lessons |
| Learners – Enrollments | One-to-many | One learner can have multiple enrollments |
| Courses – Enrollments | One-to-many | One course can have multiple enrolled learners |
| Learners – Lesson Attempts | One-to-many | One learner can attempt multiple lessons |
| Lessons – Lesson Attempts | One-to-many | One lesson can have multiple attempts |
| Learners – Daily Activity | One-to-many | One learner can have multiple daily activity records |
| Learners – League Memberships | One-to-many | One learner can participate in multiple weekly leagues |
| Learners – Learners | One-to-many | One learner can refer multiple other learners |
| Learners – Learner Achievements | One-to-many | One learner can earn multiple achievements |
| Achievements – Learner Achievements | One-to-many | One achievement can be earned by multiple learners |

The `enrollments` and `learner_achievements` tables also implement many-to-many relationships between learners and courses, and learners and achievements.

## 5. Important Design Decisions

**Course hierarchy:** Courses, units, and lessons are stored separately to maintain a clear learning structure.

**Multiple enrollments:** The `enrollments` table allows learners to join different courses without duplicating learner details.

**Repeated lesson attempts:** `lesson_attempts` stores individual attempts because a learner may attempt the same lesson more than once.

**Incomplete lessons:** `completed_at` is nullable to represent attempts that were started but not completed.

**Referral management:** `referred_by` is a nullable, self-referencing foreign key. This supports referral queries, including identifying learners who have not referred anyone.

**Daily activity tracking:** `daily_activity` stores XP and completed lesson counts for each learner and date.

**Weekly leaderboards:** `league_memberships` stores league tiers, weekly XP, rankings, and outcomes separately from learner profiles.

**Achievements:** `learner_achievements` connects learners with achievements and prevents duplicate learner-achievement combinations.

## 6. Integrity Constraints

The SQL schema uses PRIMARY KEY, FOREIGN KEY, UNIQUE, NOT NULL, and CHECK constraints.

Important validation rules include:

1. Language codes must follow the required format.
2. Source and learning languages must differ.
3. Unit and lesson numbers must be positive.
4. Lesson XP values must be positive.
5. Lesson types must use allowed categories.
6. Daily XP goals must use valid values.
7. Subscription types must use allowed categories.
8. Learners cannot refer themselves.
9. Enrollment XP cannot be negative.
10. Mistakes and hearts lost cannot be negative.
11. Earned XP cannot be negative.
12. Lesson completion time cannot precede start time.
13. Daily XP and completed lesson counts cannot be negative.
14. Weekly league XP cannot be negative.
15. League ranks and results must follow valid ranges and categories.

These rules provide the basis for the required minimum of 12 CHECK constraints. The SQL implementation must use rules compatible with the supplied data.

### Referential Integrity

Foreign keys prevent records from referencing nonexistent parent records.

The proposed delete rules are:

- **RESTRICT:** For referenced language, course, unit, lesson, and achievement records.
- **CASCADE:** For dependent learner activity and enrollment records.
- **SET NULL:** For `learners.referred_by` when the referring learner is deleted.

Changes to referenced keys must also preserve valid foreign-key relationships.

### Nullable Fields

The following attributes allow NULL values:

- `learners.referred_by`
- `lesson_attempts.completed_at`
- `league_memberships.final_rank`
- `league_memberships.result`

Other attributes are intended to be NOT NULL.

## 7. Normalization and Functional Dependencies

The database separates related information into individual tables to reduce unnecessary duplication.

The design follows **1NF, 2NF, and 3NF**, with BCNF considered using the identified functional dependencies.

- **1NF:** Each attribute contains a single value.
- **2NF:** Non-key attributes depend on the complete primary key.
- **3NF:** Non-key attributes do not depend on other non-key attributes.
- **BCNF:** Every identified determinant is a candidate key.

For example, `enrollments` stores learner-course relationships without repeating learner profiles or course details.

### Main Functional Dependencies

| Table | Functional Dependency |
|---|---|
| `languages` | `language_code → language_name` |
| `courses` | `course_id → from_lang, learning_lang, title, launched_on` |
| `units` | `unit_id → course_id, unit_no, title, cefr_level` |
| `lessons` | `lesson_id → unit_id, lesson_no, lesson_type, xp_value` |
| `learners` | `learner_id → username, email, country_code, daily_goal_xp, subscription, referred_by, joined_at` |
| `enrollments` | `(learner_id, course_id) → enrolled_at, total_xp, is_active` |
| `lesson_attempts` | `attempt_id → remaining attempt attributes` |
| `daily_activity` | `(learner_id, activity_date) → xp, lessons_completed, used_streak_freeze` |
| `league_memberships` | `(learner_id, week_start) → tier, cohort_id, weekly_xp, final_rank, result` |
| `achievements` | `achievement_id → code, name` |
| `learner_achievements` | `(learner_id, achievement_id) → earned_at` |

Attributes such as `total_xp`, `daily_activity.xp`, and `weekly_xp` are retained as stored summaries for the existing workload. These values must remain consistent with the underlying activity records.

## 8. Data Integrity Checks

The following checks are used to validate the loaded database:

| Check | Purpose | Execution Result |
|---|---|---|
| Row-count verification | Confirm that all CSV records were loaded | Pending |
| Foreign-key verification | Identify invalid references between tables | Pending |
| Enrollment consistency | Check that lesson attempts correspond to enrolled courses | Pending |
| Daily XP comparison | Compare daily XP totals with lesson-attempt records | Pending |

The source dataset contains 11 CSV files. Loaded row counts must be compared with the original files.

The actual PostgreSQL query results, including any inconsistencies, will be documented after executing the schema and data-loading scripts.

## 9. Workload Support

The database design supports the seven main problem areas in the SQL workload.

| Problem | Schema Support |
|---|---|
| P1 — Learner Home Screen | Course progress, daily XP, streak activity, and lesson information |
| P2 — Leaderboards | Weekly XP, league tiers, rankings, and outcomes |
| P3 — Lesson Progress | Lesson attempts, completion status, and XP updates |
| P4 — Curriculum Analytics | Lesson performance, mistakes, abandoned attempts, and hearts lost |
| P5 — Referral Queries | Learner referral relationships and identification of non-referring learners |
| P6 — Activity Reports | Daily active learners, course popularity, XP trends, and learner activity |
| P7 — Account and Support Operations | Learner profiles, subscriptions, achievements, and account-related searches |

The original SQL queries remain unchanged during the initial schema implementation.

## 10. ER Diagram

The ER diagram represents all 11 tables and their relationships, including primary keys, foreign keys, and cardinality.

The main course hierarchy is:

`Languages → Courses → Units → Lessons`

Learner-related tables connect through `learner_id`, while `enrollments` and `learner_achievements` represent many-to-many relationships.

**File location:** `diagrams/er_diagram.*`

## 11. Conclusion

The Duolingo database schema organises course content, learner information, learning activity, and achievements into 11 related tables.

The design uses appropriate keys, relationships, and integrity constraints to maintain data consistency while supporting the existing SQL workload.
