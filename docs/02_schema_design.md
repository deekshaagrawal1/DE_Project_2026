# Duolingo Language Learning Database
## Phase 2 — Schema Design

**Team:** T0077 | Section A  
**Database:** PostgreSQL 18.4  
**Schema:** `duolingo`

---

## 1. Database Overview

The Duolingo Language Learning Database consists of 11 related tables that store information about languages, courses, learners, lessons, daily activity, leagues and achievements.

The database follows a relational structure in which tables are connected through primary and foreign keys. This helps maintain data consistency, reduces unnecessary duplication and allows related information to be retrieved using SQL queries.

The original CSV column names are preserved to maintain compatibility with the provided SQL workload.

## 2. Table Structure

| Table | Purpose | Primary Key |
|---|---|---|
| `languages` | Stores available languages | `language_code` |
| `courses` | Stores language courses | `course_id` |
| `units` | Stores units within courses | `unit_id` |
| `lessons` | Stores lessons within units | `lesson_id` |
| `learners` | Stores learner profiles | `learner_id` |
| `enrollments` | Connects learners with courses | `(learner_id, course_id)` |
| `lesson_attempts` | Records lesson attempts and XP | `attempt_id` |
| `daily_activity` | Stores daily learning activity | `(learner_id, activity_date)` |
| `league_memberships` | Stores weekly league participation | `(learner_id, week_start)` |
| `achievements` | Stores achievement details | `achievement_id` |
| `learner_achievements` | Records achievements earned by learners | `(learner_id, achievement_id)` |

### Column Definitions

| Table | Columns and Data Types |
|---|---|
| `languages` | `language_code VARCHAR(2)`, `language_name VARCHAR(60)` |
| `courses` | `course_id INTEGER`, `from_lang VARCHAR(2)`, `learning_lang VARCHAR(2)`, `title VARCHAR(150)`, `launched_on DATE` |
| `units` | `unit_id INTEGER`, `course_id INTEGER`, `unit_no SMALLINT`, `title VARCHAR(150)`, `cefr_level VARCHAR(2)` |
| `lessons` | `lesson_id INTEGER`, `unit_id INTEGER`, `lesson_no SMALLINT`, `lesson_type VARCHAR(12)`, `xp_value SMALLINT` |
| `learners` | `learner_id INTEGER`, `username VARCHAR(100)`, `email VARCHAR(254)`, `country_code VARCHAR(2)`, `daily_goal_xp SMALLINT`, `subscription VARCHAR(10)`, `referred_by INTEGER`, `joined_at TIMESTAMPTZ` |
| `enrollments` | `learner_id INTEGER`, `course_id INTEGER`, `enrolled_at TIMESTAMPTZ`, `total_xp INTEGER`, `is_active BOOLEAN` |
| `lesson_attempts` | `attempt_id INTEGER`, `learner_id INTEGER`, `lesson_id INTEGER`, `started_at TIMESTAMPTZ`, `completed_at TIMESTAMPTZ`, `mistakes SMALLINT`, `hearts_lost SMALLINT`, `xp_earned SMALLINT`, `is_perfect BOOLEAN`, `device VARCHAR(10)` |
| `daily_activity` | `learner_id INTEGER`, `activity_date DATE`, `xp INTEGER`, `lessons_completed SMALLINT`, `used_streak_freeze BOOLEAN` |
| `league_memberships` | `learner_id INTEGER`, `week_start DATE`, `tier VARCHAR(12)`, `cohort_id INTEGER`, `weekly_xp INTEGER`, `final_rank SMALLINT`, `result VARCHAR(10)` |
| `achievements` | `achievement_id INTEGER`, `code VARCHAR(40)`, `name VARCHAR(100)` |
| `learner_achievements` | `learner_id INTEGER`, `achievement_id INTEGER`, `earned_at TIMESTAMPTZ` |

The schema uses integer types for numeric values, VARCHAR for text, BOOLEAN for true/false values, and DATE or TIMESTAMPTZ for dates and timestamps.

## 3. Keys and Relationships

### Primary and Candidate Keys

Primary keys uniquely identify records in each table. Composite primary keys are used where two columns together identify a record.

Examples include:

- `learner_id` in `learners`
- `course_id` in `courses`
- `(learner_id, course_id)` in `enrollments`
- `(learner_id, activity_date)` in `daily_activity`

Additional candidate keys include `learners.username`, `learners.email` and `achievements.code`, which are maintained as UNIQUE and NOT NULL.

### Foreign Keys

| Table | Foreign Key | References |
|---|---|---|
| `courses` | `from_lang`, `learning_lang` | `languages.language_code` |
| `units` | `course_id` | `courses.course_id` |
| `lessons` | `unit_id` | `units.unit_id` |
| `learners` | `referred_by` | `learners.learner_id` |
| `enrollments` | `learner_id`, `course_id` | `learners`, `courses` |
| `lesson_attempts` | `learner_id`, `lesson_id` | `learners`, `lessons` |
| `daily_activity` | `learner_id` | `learners.learner_id` |
| `league_memberships` | `learner_id` | `learners.learner_id` |
| `learner_achievements` | `learner_id`, `achievement_id` | `learners`, `achievements` |

### Relationship Cardinality

The main relationships are:

- One language can be used in multiple courses.
- One course contains multiple units.
- One unit contains multiple lessons.
- One learner can make multiple lesson attempts.
- One learner can have multiple daily activity records.
- Learners and courses have a many-to-many relationship through `enrollments`.
- Learners and achievements have a many-to-many relationship through `learner_achievements`.

### Referential Integrity

Foreign keys ensure that records reference existing entries in related tables.

The schema uses the following delete rules:

- **RESTRICT:** Prevents deletion of referenced languages, courses, units, lessons and achievement definitions.
- **CASCADE:** Deletes dependent learner records, such as enrollments and activity, when their parent learner is deleted.
- **SET NULL:** Clears `referred_by` if the referenced learner is deleted.

Foreign-key updates use the default `NO ACTION` behaviour, preventing changes that leave invalid references.

## 4. Integrity Constraints

Primary keys, foreign keys, UNIQUE, NOT NULL and CHECK constraints are used to maintain valid data.

The planned CHECK constraints include:

| Table | Constraints |
|---|---|
| `languages` | Language code must contain two lowercase letters |
| `courses` | Source and learning languages must differ |
| `units` | Unit number must be positive; CEFR level must be valid |
| `lessons` | Lesson number and XP must be positive; lesson type must be valid |
| `learners` | Daily goal and subscription must use allowed values; self-referrals are not allowed |
| `enrollments` | Total XP cannot be negative |
| `lesson_attempts` | Mistakes, hearts lost and XP cannot be negative; completion time cannot precede start time; perfect attempts cannot contain mistakes |
| `daily_activity` | XP and completed lessons cannot be negative |
| `league_memberships` | Weekly XP cannot be negative; final rank must be between 1 and 30; league result must use an allowed value |

**Allowed values:**

- Subscription: `FREE`, `SUPER`, `MAX`
- Lesson type: `LEARN`, `PRACTICE`, `STORY`, `LEGENDARY`
- Daily goal XP: `10`, `20`, `30`, `50`
- CEFR level: `A1`, `A2`, `B1`, `B2`, `C1`
- League result: `PROMOTED`, `DEMOTED`, `STAYED`

At least 12 CHECK constraints will be defined in `sql/01_schema.sql`. Their compatibility with the CSV data must be verified during loading.

### NULL Handling

The following columns allow NULL values:

| Column | Reason |
|---|---|
| `learners.referred_by` | Not every learner has a referrer |
| `lesson_attempts.completed_at` | Some lesson attempts are unfinished |
| `league_memberships.final_rank` | Ranking may not be finalized |
| `league_memberships.result` | League outcome may be pending |

All other columns are intended to be NOT NULL.

## 5. Normalization

The database separates related information into individual tables to reduce duplication and maintain consistency.

- **1NF:** Each column contains a single value.
- **2NF:** Non-key columns depend on the complete primary key.
- **3NF:** Non-key columns do not depend on other non-key columns.
- **BCNF:** Based on the identified dependencies, determinants are candidate keys.

For example, learner details are stored only in `learners`, while enrollments store the relationship between learners and courses. Similarly, achievement details are stored in `achievements` instead of being repeated for every learner.

### Functional Dependencies

| Table | Functional Dependency |
|---|---|
| `languages` | `language_code → language_name` |
| `courses` | `course_id → from_lang, learning_lang, title, launched_on` |
| `units` | `unit_id → course_id, unit_no, title, cefr_level` |
| `lessons` | `lesson_id → unit_id, lesson_no, lesson_type, xp_value` |
| `learners` | `learner_id → username, email, country_code, daily_goal_xp, subscription, referred_by, joined_at` |
| `enrollments` | `(learner_id, course_id) → enrolled_at, total_xp, is_active` |
| `lesson_attempts` | `attempt_id → all remaining attributes` |
| `daily_activity` | `(learner_id, activity_date) → xp, lessons_completed, used_streak_freeze` |
| `league_memberships` | `(learner_id, week_start) → tier, cohort_id, weekly_xp, final_rank, result` |
| `achievements` | `achievement_id → code, name` |
| `learner_achievements` | `(learner_id, achievement_id) → earned_at` |

Stored XP summaries are retained because they are part of the dataset and support frequently used queries. Their values should remain consistent with the underlying lesson activity.

## 6. Data Validation

Data validation checks whether the schema correctly stores the provided CSV records and maintains the required relationships.

### Expected Row Counts

| Table | Rows |
|---|---:|
| `languages` | 10 |
| `courses` | 11 |
| `units` | 220 |
| `lessons` | 1,760 |
| `learners` | 30,000 |
| `enrollments` | 37,500 |
| `lesson_attempts` | 188,300 |
| `daily_activity` | 189,109 |
| `league_memberships` | 28,598 |
| `achievements` | 10 |
| `learner_achievements` | 38,860 |

### Integrity Checks

The following checks will be performed after loading the CSV files:

1. **Row counts:** Verify that the number of records matches the source files.
2. **Foreign keys:** Check for records referencing missing learners, courses or lessons.
3. **Enrollment consistency:** Check whether lesson attempts belong to courses in which learners are enrolled.
4. **Daily XP:** Compare recorded daily XP with lesson-attempt XP.

**Validation status:** Pending PostgreSQL execution. The actual results and any inconsistencies will be documented after data loading.

## 7. ER Diagram

The ER diagram represents the 11 tables, their primary and foreign keys, and the relationships between them.

The main course structure is:

`Languages → Courses → Units → Lessons`

Learner-related tables are connected using `learner_id`. The `enrollments` and `learner_achievements` tables represent many-to-many relationships.

**Diagram location:** `diagrams/er_diagram.*`

The final diagram will be added after confirming the SQL schema.

## 8. Indexing

The initial schema uses only indexes automatically created by PRIMARY KEY and UNIQUE constraints.

Additional indexes are excluded from this phase so that baseline query performance can be measured before optimization.

## 9. Conclusion

The Duolingo database schema contains 11 relational tables with defined keys, relationships, data types and integrity constraints.

The design maintains referential integrity, reduces unnecessary duplication and supports the existing SQL workload. Final validation will be completed through PostgreSQL data loading and integrity checks.
