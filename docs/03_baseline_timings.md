# CP2 — Baseline Query Timings

## 1. Overview

This report records the baseline performance of the 30 SQL queries provided for the Duolingo Language Learning Database project.

The queries were executed on PostgreSQL 18.4 using the original seed dataset, before adding any performance optimization indexes.

Each query was executed three times using `EXPLAIN (ANALYZE, BUFFERS)`. The average execution time was calculated from these three runs.

**Database:** duolingo_db  
**Schema:** duolingo  
**Total queries:** 30 (25 READ, 5 WRITE)  
**Benchmark runs per query:** 3  
**Measurement unit:** Milliseconds (ms)

The write queries were executed inside transactions with `ROLLBACK` to prevent permanent changes to the dataset.

## 2. Baseline Execution Timings

| Query | Type | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) |
|---|---|---:|---:|---:|---:|
| R01 | READ | 0.242 | 0.148 | 0.179 | 0.190 |
| R02 | READ | 0.069 | 0.047 | 0.046 | 0.054 |
| R03 | READ | 0.094 | 0.099 | 0.083 | 0.092 |
| R04 | READ | 5.295 | 5.030 | 4.578 | 4.968 |
| R05 | READ | 0.921 | 0.921 | 0.912 | 0.918 |
| R06 | READ | 6.017 | 5.606 | 5.400 | 5.674 |
| R07 | READ | 14.856 | 15.127 | 15.150 | 15.044 |
| R08 | READ | 16.059 | 15.790 | 15.875 | 15.908 |
| R09 | READ | 4.179 | 4.049 | 4.000 | 4.076 |
| R10 | READ | 4.449 | 4.174 | 4.192 | 4.272 |
| R11 | READ | 0.025 | 0.024 | 0.025 | 0.025 |
| R12 | READ | 0.036 | 0.035 | 0.034 | 0.035 |
| R13 | READ | 4.083 | 4.327 | 4.180 | 4.197 |
| R14 | READ | 1.756 | 1.725 | 1.749 | 1.743 |
| R15 | READ | 1.314 | 1.294 | 1.326 | 1.311 |
| R16 | READ | 2.720 | 2.623 | 2.626 | 2.656 |
| R17 | READ | 12.355 | 13.178 | 12.441 | 12.658 |
| R18 | READ | 5.767 | 5.693 | 5.837 | 5.766 |
| R19 | READ | 1450.941 | 1454.402 | 1456.925 | 1454.089 |
| R20 | READ | 8.405 | 7.782 | 7.768 | 7.985 |
| R21 | READ | 2.165 | 2.214 | 2.030 | 2.136 |
| R22 | READ | 30.780 | 31.636 | 30.964 | 31.127 |
| R23 | READ | 5.477 | 5.337 | 5.252 | 5.355 |
| R24 | READ | 22.457 | 22.324 | 22.718 | 22.500 |
| R25 | READ | 118.126 | 117.248 | 116.779 | 117.384 |
| W01 | WRITE | 0.491 | 0.418 | 0.394 | 0.434 |
| W02 | WRITE | 0.933 | 0.551 | 0.574 | 0.686 |
| W03 | WRITE | 0.332 | 0.295 | 0.298 | 0.308 |
| W04 | WRITE | 6.078 | 4.860 | 4.940 | 5.293 |
| W05 | WRITE | 46.616 | 43.084 | 34.341 | 41.347 |
| **Total** | | | | | **1768.231** |

The total is the sum of the 30 reported average execution times, not the total elapsed time of the benchmark script.

## 3. Execution Plan Analysis

The following observations are based on the scan operations recorded in the baseline execution plans.

| Query | Scan Type | Performance Observation |
|---|---|---|
| R01 | Seq Scan, Index Scan | Small course and unit tables are scanned, while lesson ordering uses an index. |
| R02 | Index Scan, Seq Scan | Enrollment lookup uses a primary-key index; the small courses table is scanned. |
| R03 | Index Only Scan | The daily activity primary-key index supports efficient access without a full table scan. |
| R04 | Index Scan, Seq Scan | Learner lookup is indexed, but lesson attempts require a sequential scan. |
| R05 | Index Scan, Seq Scan | The query combines indexed lookups with a scan of league memberships. |
| R06 | Index Scan, Seq Scan | Units and lessons use indexes, while checking unfinished attempts requires scanning lesson attempts. |
| R07 | Seq Scan | Lesson attempt and curriculum tables are scanned for mistake analysis. |
| R08 | Seq Scan | Calculating quit rates involves scanning lesson attempts and lessons. |
| R09 | Seq Scan | The daily activity table is scanned for active-user reporting. |
| R10 | Seq Scan, Index Scan | Activity records are scanned and learner information is accessed through an index. |
| R11 | Index Scan | Username lookup uses the unique index and is the fastest query. |
| R12 | Index Scan, Seq Scan | The achievement relationship uses a primary-key index; the small achievements table is scanned. |
| R13 | Seq Scan | Finding learners without referrals involves scanning learner records. |
| R14 | Seq Scan | League memberships are scanned to calculate promotion and demotion rates. |
| R15 | Seq Scan, Index Scan | Learners are scanned, with indexed lookups into daily activity. |
| R16 | Index Scan | Username prefix search uses the existing username index. |
| R17 | Seq Scan | Perfect-lesson analysis scans the lesson attempts table. |
| R18 | Seq Scan | Course popularity reporting scans enrollments and courses. |
| R19 | Index Scan, Seq Scan | Repeated processing of lesson attempts contributes to very high execution time. |
| R20 | Seq Scan | Platform-wide XP calculations require reading lesson attempt records. |
| R21 | Index Only Scan | The daily activity index supports streak-related lookups. |
| R22 | Seq Scan | Deep pagination requires substantial processing of lesson attempts. |
| R23 | Seq Scan | Activity and learner records are scanned to identify active paid subscribers. |
| R24 | Seq Scan | Hearts-lost analysis scans lesson attempts and related curriculum tables. |
| R25 | Seq Scan | Hourly activity analysis scans lesson attempts and learners. |
| W01 | No scan reported | Starting a lesson inserts a new attempt and executes quickly. |
| W02 | Index Scan | Completing an attempt uses the attempt primary-key index. |
| W03 | No scan reported | The daily XP update executes quickly, with no scan node reported by the benchmark summary. |
| W04 | Seq Scan | Weekly league processing scans league membership records. |
| W05 | Seq Scan | Achievement processing scans achievement and enrollment records. |

## 4. Key Findings

### 4.1 Slowest Queries

The five highest average execution times were:

| Query | Average (ms) |
|---|---:|
| R19 | 1454.089 |
| R25 | 117.384 |
| W05 | 41.347 |
| R22 | 31.127 |
| R24 | 22.500 |

R19 is the most significant performance concern. Its execution time is much higher than the other queries, and its plan includes a sequential scan on `lesson_attempts`.

R25 also takes considerably longer than most queries because it processes lesson attempts and learner information for activity reporting.

R22 shows that deep pagination can become relatively expensive even on the seed dataset.

### 4.2 Fastest Queries

R11, R12, R02 and R03 all complete in less than 0.1 ms on average.

These queries benefit from existing primary-key or unique indexes. No additional optimization indexes were created for the baseline.

### 4.3 Sequential Scans

Several reporting queries rely on sequential scans, particularly those processing `lesson_attempts`, `daily_activity` and `enrollments`.

Sequential scans are not always inefficient, especially for small tables or reports requiring many rows. However, scanning large tables repeatedly can become a bottleneck as the dataset grows.

### 4.4 Write Query Performance

W01, W02 and W03 execute in less than 1 ms on average. W04 takes 5.293 ms, while W05 averages 41.347 ms.

These measurements provide a baseline for evaluating whether additional indexes improve read performance at the cost of slower writes.

## 5. Conclusion

All 30 provided queries were successfully benchmarked using three execution runs each.

The measurements establish the database's performance before optimization. The most important areas for further investigation are R19, R25, R22, R24 and W05.

In the next checkpoint, indexes and query rewrites will be evaluated against these baseline results to determine whether execution times improve without changing query correctness.

The complete measurements are stored in `benchmarks/results/baseline/summary.csv`, and individual execution plans are saved in the same baseline directory.
