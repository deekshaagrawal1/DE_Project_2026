# Phase 3 — Baseline Timings Report

**Project:** Duolingo Language Learning Database  
**Team:** T0077 | Section A  
**Group Lead:** Aayush Ray (`millimeow`)  
**Members:** Deeksha Agrawal (`deekshaagrawal1`), Prakhar Yadav (`rakshak7879-bit`), Arundhati Singh (`arundhatis25577-svg`)  
**Milestone:** Checkpoint 2 (CP2) — Baseline Timings  
**Date:** November 17, 2026  

---

## 1. Environment & Setup

* **Database Engine:** PostgreSQL 18.7 (Postgres.app)
* **Operating System:** macOS 26.0.1 (Darwin arm64, Apple Silicon)
* **Hardware:** MacBook Pro M4 Pro
* **Database Name:** `duolingo`
* **Schema:** `duolingo`
* **Dataset Scale:** Seed dataset (11 tables, 188,300 lesson attempts, 189,109 daily activity records, 30,000 learners, 37,500 course enrollments, 28,598 league memberships, 1,760 lessons, 220 units, 11 courses, 10 languages, 10 achievements, 38,860 earned achievements).
* **Indexing State:** Baseline unindexed configuration. Only implicit B-tree indexes generated automatically by PostgreSQL for `PRIMARY KEY` and `UNIQUE` constraints are present. No secondary indexes, covering indexes, or optimizer configuration overrides were applied.

---

## 2. Benchmark Methodology

* **Script:** Executed using the standardized benchmark automation script [benchmarks/run_benchmark.sh](file:///Users/prakharyadav/Desktop/DE_Project_2026/benchmarks/run_benchmark.sh).
* **Repetitions:** Each query was executed **3 consecutive times** (`RUNS=3`) under identical system conditions.
* **Timing Capture:** Latency is reported directly from PostgreSQL's internal engine via `EXPLAIN (ANALYZE, BUFFERS)` execution time (in milliseconds). Planning time is excluded from execution time.
* **Transactional Integrity for Writes:**
  * Read queries (`R01`–`R25`) run under `SET search_path TO duolingo; EXPLAIN (ANALYZE, BUFFERS) <query>`.
  * Write queries (`W01`–`W05`) run strictly inside transactional blocks: `SET search_path TO duolingo; BEGIN; EXPLAIN (ANALYZE, BUFFERS) <query> ROLLBACK;`. All modifications are rolled back immediately, guaranteeing that the database state and table volumes remain identical across all runs.
* **Data Sources:** All measurements are taken directly from the benchmark output artifacts:
  * Summary statistics: [benchmarks/results/baseline/summary.csv](file:///Users/prakharyadav/Desktop/DE_Project_2026/benchmarks/results/baseline/summary.csv)
  * Raw execution plans: `benchmarks/results/baseline/R01.txt` through `W05.txt`.

---

## 3. Baseline Timing Table (30 Queries)

Below are the recorded execution times for all 30 queries in the canonical workload:

| SQL Query | Type | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) |
|---|---|---:|---:|---:|---:|
| R01: Course path: units and lessons of the Spanish course for English speakers, in order | READ | 0.119 | 0.127 | 0.128 | 0.125 |
| R02: Home screen: learner 1042's courses with total XP | READ | 0.047 | 0.043 | 0.044 | 0.045 |
| R03: Streak counter: learner 1042's current streak (consecutive days up to 30 June 2026, freezes count) | READ | 0.092 | 0.083 | 0.075 | 0.083 |
| R04: Daily goal ring: XP learner 1042 earned on 30 June 2026 vs their daily goal | READ | 4.774 | 4.512 | 4.402 | 4.563 |
| R05: Leagues tab: leaderboard of learner 1042's cohort for the week starting 29 June 2026 | READ | 0.921 | 0.913 | 0.861 | 0.898 |
| R06: "Start" button: the first lesson of learner 1042's Spanish course they have not completed yet | READ | 5.939 | 5.625 | 5.546 | 5.703 |
| R07: Curriculum team: lessons of the Spanish course with the most mistakes per attempt (100+ attempts) | READ | 15.772 | 15.455 | 15.607 | 15.611 |
| R08: Product analytics: quit rate per lesson type | READ | 18.314 | 17.473 | 17.324 | 17.704 |
| R09: Growth: daily active learners in June 2026 | READ | 4.264 | 4.383 | 4.356 | 4.334 |
| R10: Monetisation: streak freezes used per subscription tier in 2026 | READ | 4.953 | 4.538 | 4.372 | 4.621 |
| R11: Sign-in by username | READ | 0.029 | 0.021 | 0.022 | 0.024 |
| R12: Profile: learner 1042's achievements, newest first | READ | 0.040 | 0.037 | 0.035 | 0.037 |
| R13: Referral programme: learners who have not referred anyone yet | READ | 4.401 | 4.271 | 4.457 | 4.376 |
| R14: Leagues team: promotion and demotion rates per tier over the last 4 completed weeks | READ | 1.885 | 1.810 | 1.750 | 1.815 |
| R15: Retention: learners who joined in January 2026 and were still active in June 2026 | READ | 1.464 | 1.389 | 1.393 | 1.415 |
| R16: Friends: search learners by username starting with "Karan" | READ | 4.186 | 4.249 | 4.265 | 4.233 |
| R17: Product analytics: perfect-lesson rate per device in 2026 | READ | 15.970 | 14.958 | 14.850 | 15.259 |
| R18: Course popularity: enrollments per course, and how many started in 2026 | READ | 6.121 | 5.952 | 6.119 | 6.064 |
| R19: Curriculum report: completions and average mistakes of every lesson in the Spanish course | READ | 1502.055 | 1629.272 | 1547.057 | 1559.461 |
| R20: Growth: XP earned per day across the platform and running total, June 2026 | READ | 8.466 | 8.482 | 8.220 | 8.389 |
| R21: Streak reminders: learners active every day from 23 to 29 June but not yet on 30 June | READ | 2.476 | 2.182 | 2.123 | 2.260 |
| R22: Support console: all lesson attempts, newest first, page 4,001 (25 per page) | READ | 33.034 | 32.352 | 32.239 | 32.542 |
| R23: Monetisation: Super and Max learners in India who were active in the last 7 days of June 2026 | READ | 5.983 | 5.769 | 5.906 | 5.886 |
| R24: Curriculum team: average hearts lost per lesson, by CEFR level | READ | 25.518 | 23.506 | 22.858 | 23.961 |
| R25: Notifications team: lessons started per hour of the day, per country | READ | 115.022 | 115.095 | 116.609 | 115.575 |
| W01: Lesson start: learner 1042 starts lesson 1 | WRITE | 0.878 | 0.567 | 0.620 | 0.688 |
| W02: Lesson end: finish the most recent unfinished attempt of 30 June 2026 with 2 mistakes | WRITE | 0.643 | 0.609 | 0.584 | 0.612 |
| W03: Daily activity: add 20 XP to learner 1042's 1 July 2026 (creating the row if needed) | WRITE | 0.389 | 0.346 | 0.352 | 0.362 |
| W04: Weekly league close (week of 29 June 2026): rank everyone in their cohort and set promotion results | WRITE | 5.106 | 5.154 | 5.124 | 5.128 |
| W05: Achievements catch-up: award the "100 XP" badge to every learner who has 100+ XP but not the badge | WRITE | 34.239 | 35.905 | 37.221 | 35.788 |
| **Total (sum of all 30)** | | **1854.770** | **1906.945** | **1870.971** | **1877.562** |

---

## 4. Query-by-Query Scan Types & Performance Observations

Below is the scan type from the physical plan of each query and the architectural reason why it performs fast or slow in the unindexed baseline:

* **R01 (0.125 ms):** `Seq Scan on units | Seq Scan on courses | Index Scan using uq_lesson_in_unit on lessons`  
  *Why:* Very fast. Scans tiny metadata tables (`courses` has 11 rows, `units` has 220 rows) and utilizes the composite unique index `(unit_id, lesson_no)` on `lessons`.
* **R02 (0.045 ms):** `Index Scan using enrollments_pkey on enrollments | Seq Scan on courses`  
  *Why:* Highly efficient index point-lookup. Directly probes `enrollments_pkey` on `(learner_id, course_id)` for `learner_id = 1042` and joins with the 11-row `courses` table.
* **R03 (0.083 ms):** `Index Only Scan using daily_activity_pkey on daily_activity`  
  *Why:* Fastest multi-row read. PostgreSQL fulfills the entire query directly from the primary key index `(learner_id, activity_date)` without touching heap table blocks.
* **R04 (4.563 ms):** `Index Scan using learners_pkey on learners | Seq Scan on lesson_attempts`  
  *Why:* Moderately slow. Although the learner profile lookup is indexed, computing today's XP requires scanning all 188,300 rows of `lesson_attempts` due to lack of an index on `(learner_id, started_at)` and the non-sargable expression `DATE(started_at)`.
* **R05 (0.898 ms):** `Index Scan using league_memberships_pkey on league_memberships | Seq Scan on league_memberships | Index Scan using learners_pkey on learners`  
  *Why:* Subquery cohort lookup uses primary key, but gathering all members of the cohort requires a sequential scan across 28,598 rows of `league_memberships` because `cohort_id` has no secondary index.
* **R06 (5.703 ms):** `Index Scan using uq_unit_in_course on units | Index Scan using uq_lesson_in_unit on lessons | Seq Scan on lesson_attempts`  
  *Why:* Navigating course units and lessons uses unique indexes, but evaluating the `NOT EXISTS` anti-join forces sequential scanning of `lesson_attempts` (188,300 rows) to check completion status.
* **R07 (15.611 ms):** `Seq Scan on lesson_attempts | Seq Scan on lessons | Seq Scan on units`  
  *Why:* Analytics scan. Must sequentially scan all 188,300 attempts, hash-join them with `lessons` and `units`, and group with `HAVING count(*) >= 100` before sorting.
* **R08 (17.704 ms):** `Seq Scan on lesson_attempts | Seq Scan on lessons`  
  *Why:* Full analytics scan. Performs a complete sequential scan of 188,300 attempts joined with 1,760 lessons to compute aggregate quit rates per lesson type.
* **R09 (4.334 ms):** `Seq Scan on daily_activity`  
  *Why:* Scans all 189,109 rows of `daily_activity` to filter by date range `2026-06-01` to `2026-06-30` and aggregate active users per day.
* **R10 (4.621 ms):** `Seq Scan on daily_activity | Index Scan using learners_pkey on learners`  
  *Why:* Scans all 189,109 rows of `daily_activity` filtering on `used_streak_freeze` and year 2026, joining each hit to `learners_pkey`.
* **R11 (0.024 ms):** `Index Scan using learners_username_key on learners`  
  *Why:* **Fastest query overall.** Direct unique B-tree index lookup on `username`, retrieving a single tuple within 3 shared buffer hits.
* **R12 (0.037 ms):** `Index Scan using learner_achievements_pkey on learner_achievements | Seq Scan on achievements`  
  *Why:* Extremely fast. Uses the primary key index on `learner_achievements` `(learner_id, achievement_id)` to filter for learner 1042, joined with the 10-row `achievements` table.
* **R13 (4.376 ms):** `Seq Scan on learners`  
  *Why:* Scans 30,000 learner records while evaluating a subquery with `NOT IN (SELECT referred_by FROM learners)`. *(Note: Due to NULLs in `referred_by`, this query logically evaluates to empty in SQL).*
* **R14 (1.815 ms):** `Seq Scan on league_memberships`  
  *Why:* Scans 28,598 league records to filter 4 weeks of competition data and group by tier.
* **R15 (1.415 ms):** `Seq Scan on learners | Index Scan using daily_activity_pkey on daily_activity`  
  *Why:* Scans 30,000 learners joining in January 2026, then uses the index on `daily_activity` to evaluate learner retention.
* **R16 (4.233 ms):** `Index Scan using learners_username_key on learners`  
  *Why:* Probes the B-tree index on `username`, but `ILIKE 'karan%'` with default collation prevents an optimal range index scan, scanning index entries sequentially.
* **R17 (15.259 ms):** `Seq Scan on lesson_attempts`  
  *Why:* Evaluates `EXTRACT(YEAR FROM started_at) = 2026` across all 188,300 attempts sequentially, followed by hash aggregation per device.
* **R18 (6.064 ms):** `Seq Scan on enrollments | Seq Scan on courses`  
  *Why:* Scans all 37,500 course enrollments and hash-joins with 11 courses to aggregate total and new enrollments.
* **R19 (1559.461 ms):** `Index Scan using uq_unit_in_course on units | Index Scan using uq_lesson_in_unit on lessons | Seq Scan on lesson_attempts`  
  *Why:* **Slowest query in the workload (83.1% of total workload time).** The two correlated subqueries in the SELECT clause execute two full sequential scans of `lesson_attempts` (188,300 rows) for *every single lesson* in Course 1 (160 lessons). This executes 320 full table scans (over 60.2 million row evaluations) and accesses 573,509 shared memory buffers.
* **R20 (8.389 ms):** `Seq Scan on lesson_attempts`  
  *Why:* Scans all 188,300 attempts to aggregate June 2026 daily XP, followed by an in-memory window sort for running total XP.
* **R21 (2.260 ms):** `Index Only Scan using daily_activity_pkey on daily_activity`  
  *Why:* Filters `daily_activity` date ranges directly using the B-tree primary key index without reading heap table pages, followed by hash aggregation.
* **R22 (32.542 ms):** `Seq Scan on lesson_attempts`  
  *Why:* Deep offset pagination (`OFFSET 100000 LIMIT 25`). Lacking an index on `started_at DESC`, PostgreSQL must scan all 188,300 rows and sort them using an **external merge disk sort spilling 6.6 MB to disk** before skipping 100,000 rows.
* **R23 (5.886 ms):** `Seq Scan on daily_activity | Seq Scan on learners`  
  *Why:* Performs full scans on both `daily_activity` (189,109 rows) and `learners` (30,000 rows) to perform a hash join on active paid learners in India.
* **R24 (23.961 ms):** `Seq Scan on lesson_attempts | Seq Scan on lessons | Seq Scan on units`  
  *Why:* Joins all 188,300 attempt records to lessons and units via sequential scans and hash joins to calculate average hearts lost per CEFR level.
* **R25 (115.575 ms):** `Seq Scan on lesson_attempts | Seq Scan on learners`  
  *Why:* **Second slowest query.** Scans 188,300 attempts and 30,000 learners, joins them via Hash Join, and sorts all 188,300 rows by `(country_code, EXTRACT(HOUR FROM started_at))` using an **external merge disk sort spilling 3.3 MB to temporary files** before group aggregation.
* **W01 (0.688 ms):** `(no scan)`  
  *Why:* Single-row INSERT into `lesson_attempts` taking advantage of defined column default values.
* **W02 (0.612 ms):** `Index Scan using lesson_attempts_pkey on lesson_attempts`  
  *Why:* Subquery resolves the target attempt ID, and the UPDATE directly mutates the tuple using the primary key index scan.
* **W03 (0.362 ms):** `(no scan)`  
  *Why:* Fast single-row UPSERT on `daily_activity` resolving the primary key conflict arbiter in memory.
* **W04 (5.128 ms):** `Seq Scan on league_memberships`  
  *Why:* Evaluates window function `row_number()` partitioned across all cohorts on the week of 29 June 2026, followed by batch updating ranks and outcomes.
* **W05 (35.788 ms):** `Seq Scan on achievements | Seq Scan on enrollments`  
  *Why:* Scans all 37,500 enrollments, groups by learner, identifies 11,909 eligible learners, and inserts 4,016 new rows into `learner_achievements` (handling 7,893 PK conflicts and evaluating 4,016 foreign key validation triggers).

---

## 5. In-Depth Plan Analysis: Extremes

### 5.1 Fastest Queries
1. **R11 (0.024 ms):** Single-tuple index lookup on `learners.username`. PostgreSQL uses the unique constraint B-tree index `learners_username_key` to locate the leaf page immediately (`shared hit=3`).
2. **R12 (0.037 ms):** Probes the composite primary key index `learner_achievements_pkey` on `(learner_id, achievement_id)` where `learner_id = 1042`, fetching the learner's 2 badges within 0.037 ms.
3. **R02 (0.045 ms):** Composite primary key index scan on `enrollments_pkey` for `learner_id = 1042` joined with tiny `courses` table.
4. **R03 (0.083 ms):** `Index Only Scan` on `daily_activity_pkey`. Since the index covers `(learner_id, activity_date)` and the query requires only `activity_date`, the heap table is bypassed entirely.

### 5.2 Slowest Queries
1. **R19 (1559.461 ms — 83.1% of entire baseline runtime):**
   * **Root Cause:** Correlated scalar subqueries inside the `SELECT` projection:
     ```sql
     (SELECT count(*) FROM lesson_attempts a WHERE a.lesson_id = l.lesson_id AND a.completed_at IS NOT NULL) AS completions,
     (SELECT round(avg(a.mistakes), 2) FROM lesson_attempts a WHERE a.lesson_id = l.lesson_id) AS avg_mistakes
     ```
   * **Plan Breakdown:** For each of the 160 lessons in Course 1, SubPlan 1 executes a full sequential scan on `lesson_attempts` (188,300 rows), and SubPlan 2 executes another full sequential scan on `lesson_attempts` (188,300 rows).
   * **Cost:** $160 \times 2 = 320$ sequential table scans across 188,300 rows = **60,256,000 row inspections**, causing 573,509 buffer hits.
   * **Fix for Phase 4:** Replace correlated scalar subqueries with a single `LEFT JOIN` on a pre-aggregated subquery or group join, supported by a composite index on `(lesson_id, completed_at, mistakes)`.
2. **R25 (115.575 ms):**
   * **Root Cause:** Joins 188,300 attempts to 30,000 learners without secondary indexes, followed by an unindexed sort on expressions `(le.country_code, EXTRACT(HOUR FROM a.started_at))`.
   * **Plan Breakdown:** The sort exceeds PostgreSQL's default `work_mem` buffer, spilling to disk (`Sort Method: external merge  Disk: 3312kB`, `temp read=414 written=416`).
   * **Fix for Phase 4:** Index on foreign keys and rewrite/pre-aggregate to eliminate external merge disk spills.
3. **W05 (35.788 ms):**
   * **Root Cause:** Batch insert evaluating 11,909 candidates against `learner_achievements_pkey` (4,016 inserts, 7,893 conflicts), triggering 4,016 individual foreign key validation checks on both `learner_id` and `achievement_id`.
4. **R22 (32.542 ms):**
   * **Root Cause:** Deep offset pagination (`OFFSET 100000 LIMIT 25`). Without an index on `started_at`, the engine sequentially scans all 188,300 rows and executes an external merge sort spilling 6,648 kB to disk before discarding 100,000 rows.
   * **Fix for Phase 4:** B-tree index on `started_at DESC` or keyset pagination.

---

## 6. Overall Performance Observations & Conclusion

1. **Workload Latency Skew:**
   * Total average baseline execution time across all 30 queries is **1877.562 ms**.
   * A single unoptimized query (**R19**) accounts for **83.06%** of total runtime. The two slowest queries (**R19 + R25**) account for **89.21%** of total runtime.
2. **The Power of Default Primary/Unique Indexes:**
   * Queries that filter by single candidate keys (`R11`, `R02`, `R03`, `R12`) execute in under **0.1 ms**, demonstrating that PostgreSQL's B-tree index implementation provides sub-millisecond retrieval when indexes exist.
3. **Sequential Scan Bottlenecks:**
   * High-traffic transaction tables (`lesson_attempts`, `daily_activity`, `league_memberships`, `enrollments`) completely lack secondary B-tree indexes on foreign keys (`learner_id`, `lesson_id`, `cohort_id`) and temporal columns (`started_at`, `activity_date`).
   * This forces the planner into full sequential scans and memory-intensive external disk sorts (`R22`, `R25`), which will degrade severely under larger dataset scales.
4. **Readiness for Phase 4 (Optimization):**
   * Baseline performance has been comprehensively measured and cataloged under identical, reproducible conditions.
   * The identified bottlenecks provide clear targets for Phase 4: targeted B-tree indexing on foreign keys, expression indexes for date/time filters, elimination of correlated subqueries via joins, and query rewrites for pagination.
