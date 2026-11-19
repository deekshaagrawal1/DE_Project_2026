-- =====================================================================
-- Duolingo DBMS Project: Phase 5 Partitioning Strategy
-- File: sql/08_partitioning.sql
-- Table: lesson_attempts (Largest high-volume transactional entity)
-- Strategy: Declarative Range Partitioning by started_at (Quarterly)
-- PostgreSQL Target: 18.x
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Partitioning Rationale & Architecture
-- ---------------------------------------------------------------------
-- In Duolingo's production architecture, `lesson_attempts` is the highest-volume
-- append-heavy transactional table, recording ~188,300 rows in seed data and
-- scaling to 3,766,000+ rows (20x) and 18,800,000+ rows (100x).
--
-- Bottlenecks on Monolithic Table:
-- 1. Sequential Scans & B-tree Depth: Range queries filtering on time windows
--    (e.g., June 2026 reporting, monthly retention, quarterly analytics) must
--    scan massive indexes or heap blocks.
-- 2. Autovacuum & Bloat: Vacuuming a monolithic 3.7M+ row table incurs high I/O
--    and bloat accumulation on completed historical attempts.
-- 3. Data Lifecycle & Archival: Dropping or archiving historical data (e.g., attempts
--    older than 18 months) on a monolithic table requires massive DELETE statements,
--    causing catastrophic write amplification and WAL churn. Partitioning allows
--    O(1) DROP TABLE or ALTER TABLE DETACH PARTITION operations.
--
-- Why Range Partitioning on `started_at`?
-- - Temporal Alignment: Almost all analytical, reporting, and operational queries
--   (R04, R06, R07, R08, R17, R20, R22, R25, W01, W02) filter or order by timestamp.
-- - Partition Pruning: PostgreSQL's planner eliminates non-matching partitions during
--   query planning and execution (run-time pruning) when range bounds are constant.
-- - Boundary Sizing: Quarterly partitions maintain manageable chunk sizes (~30,000 to
--   ~40,000 rows in seed, ~600,000 to ~750,000 rows at 20x, ~3.7M at 100x), fitting
--   comfortably within standard `shared_buffers` (RAM).
--
-- Primary Key Constraint Rule in Partitioned Tables:
-- In PostgreSQL declarative partitioning, any UNIQUE or PRIMARY KEY constraint on
-- a partitioned table MUST include all partition key columns. Therefore, the composite
-- primary key for `lesson_attempts_partitioned` is defined as `(attempt_id, started_at)`.
-- ---------------------------------------------------------------------

SET search_path TO duolingo;

-- ---------------------------------------------------------------------
-- 2. Create Declarative Partitioned Table
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS duolingo.lesson_attempts_partitioned (
    attempt_id INTEGER NOT NULL,
    learner_id INTEGER NOT NULL
        REFERENCES duolingo.learners(learner_id) ON DELETE CASCADE,
    lesson_id INTEGER NOT NULL
        REFERENCES duolingo.lessons(lesson_id) ON DELETE RESTRICT,
    started_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ,
    mistakes SMALLINT NOT NULL DEFAULT 0,
    hearts_lost SMALLINT NOT NULL DEFAULT 0,
    xp_earned SMALLINT NOT NULL DEFAULT 0,
    is_perfect BOOLEAN NOT NULL DEFAULT false,
    device VARCHAR(10) NOT NULL,

    -- Composite primary key including the partition key
    PRIMARY KEY (attempt_id, started_at),

    -- Domain & Integrity Constraints preserved from 01_schema.sql
    CONSTRAINT chk_mistakes
        CHECK (mistakes >= 0),
    CONSTRAINT chk_hearts
        CHECK (
            hearts_lost >= 0
            AND hearts_lost <= mistakes
        ),
    CONSTRAINT chk_attempt_xp
        CHECK (xp_earned >= 0),
    CONSTRAINT chk_attempt_time
        CHECK (
            completed_at IS NULL
            OR completed_at >= started_at
        ),
    CONSTRAINT chk_perfect_attempt
        CHECK (
            NOT is_perfect
            OR mistakes = 0
        ),
    CONSTRAINT chk_unfinished_xp
        CHECK (
            completed_at IS NOT NULL
            OR xp_earned = 0
        ),
    CONSTRAINT chk_device
        CHECK (device IN ('ANDROID', 'IOS', 'WEB'))
) PARTITION BY RANGE (started_at);

-- ---------------------------------------------------------------------
-- 3. Create Quarterly Partitions (Covering 2025 to 2026+)
-- ---------------------------------------------------------------------
-- 2025 Quarters
CREATE TABLE IF NOT EXISTS duolingo.lesson_attempts_2025_q1 PARTITION OF duolingo.lesson_attempts_partitioned
    FOR VALUES FROM ('2025-01-01 00:00:00+00') TO ('2025-04-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS duolingo.lesson_attempts_2025_q2 PARTITION OF duolingo.lesson_attempts_partitioned
    FOR VALUES FROM ('2025-04-01 00:00:00+00') TO ('2025-07-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS duolingo.lesson_attempts_2025_q3 PARTITION OF duolingo.lesson_attempts_partitioned
    FOR VALUES FROM ('2025-07-01 00:00:00+00') TO ('2025-10-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS duolingo.lesson_attempts_2025_q4 PARTITION OF duolingo.lesson_attempts_partitioned
    FOR VALUES FROM ('2025-10-01 00:00:00+00') TO ('2026-01-01 00:00:00+00');

-- 2026 Quarters
CREATE TABLE IF NOT EXISTS duolingo.lesson_attempts_2026_q1 PARTITION OF duolingo.lesson_attempts_partitioned
    FOR VALUES FROM ('2026-01-01 00:00:00+00') TO ('2026-04-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS duolingo.lesson_attempts_2026_q2 PARTITION OF duolingo.lesson_attempts_partitioned
    FOR VALUES FROM ('2026-04-01 00:00:00+00') TO ('2026-07-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS duolingo.lesson_attempts_2026_q3 PARTITION OF duolingo.lesson_attempts_partitioned
    FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2026-10-01 00:00:00+00');

CREATE TABLE IF NOT EXISTS duolingo.lesson_attempts_2026_q4 PARTITION OF duolingo.lesson_attempts_partitioned
    FOR VALUES FROM ('2026-10-01 00:00:00+00') TO ('2027-01-01 00:00:00+00');

-- Catch-all default partition for forward data safety
CREATE TABLE IF NOT EXISTS duolingo.lesson_attempts_default PARTITION OF duolingo.lesson_attempts_partitioned
    DEFAULT;

-- ---------------------------------------------------------------------
-- 4. Global Partition Indexes (Automatically Propagated to Partitions)
-- ---------------------------------------------------------------------
-- Indexes created on the partitioned parent table are automatically
-- generated across each individual partition child table.

-- Index for learner activity lookup (R04, R06, learner dashboards)
CREATE INDEX IF NOT EXISTS idx_part_attempts_learner
    ON duolingo.lesson_attempts_partitioned (learner_id, started_at);

-- Index for curriculum analysis by lesson (R07, R08, R19, R24)
CREATE INDEX IF NOT EXISTS idx_part_attempts_lesson
    ON duolingo.lesson_attempts_partitioned (lesson_id, mistakes, hearts_lost);

-- Index for ordering and pagination (R22, R20)
CREATE INDEX IF NOT EXISTS idx_part_attempts_started_desc
    ON duolingo.lesson_attempts_partitioned (started_at DESC);

-- Partial index for unfinished attempts (W02 fast target resolution)
CREATE INDEX IF NOT EXISTS idx_part_attempts_unfinished
    ON duolingo.lesson_attempts_partitioned (started_at, attempt_id)
    WHERE completed_at IS NULL;

-- ---------------------------------------------------------------------
-- 5. Data Migration Helper (Safe non-destructive migration)
-- ---------------------------------------------------------------------
-- Note: To migrate existing records from lesson_attempts into the partitioned table:
-- INSERT INTO duolingo.lesson_attempts_partitioned
-- SELECT attempt_id, learner_id, lesson_id, started_at, completed_at,
--        mistakes, hearts_lost, xp_earned, is_perfect, device
-- FROM duolingo.lesson_attempts
-- ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
-- 6. Verification: Partition Pruning Proof
-- ---------------------------------------------------------------------
-- The following query will exhibit Partition Pruning, scanning ONLY
-- partition `lesson_attempts_2026_q2` and ignoring all other partitions:
--
-- EXPLAIN (ANALYZE, BUFFERS)
-- SELECT count(*), avg(mistakes)
-- FROM duolingo.lesson_attempts_partitioned
-- WHERE started_at >= '2026-06-01 00:00:00+00' AND started_at < '2026-07-01 00:00:00+00';
