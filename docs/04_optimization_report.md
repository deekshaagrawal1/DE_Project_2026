# CP3 — Optimization report

## Measurement provenance

Measured on 18 November 2026 using PostgreSQL 18.6 (Postgres.app), macOS/Apple Silicon, in an isolated local database loaded from the repository seed archive. The existing CP2 results were measured on another machine/server version and are preserved unchanged. For a fair speed comparison, `cp3_baseline/` contains a fresh untuned run on this same machine; the table also shows the committed CP2 averages for reference.

Five consecutive runs per query in both local phases; PostgreSQL `EXPLAIN (ANALYZE, BUFFERS)` Execution Time excludes planning/client startup and includes instrumentation overhead. Every write ran inside BEGIN/ROLLBACK. Time zone Asia/Kolkata, default server settings, no performance configuration overrides, no materialized caches and no dataset edits. Only constraint indexes existed before CP3. The database was ANALYZEd after loading and creating indexes. This is a sequential cache-dependent benchmark; correctness checks warm caches before the baseline and index creation affects cache state. No cold-cache or concurrent-load claim is made. Rollback does not reverse physical work, dead tuples, WAL or cache effects. Small differences may be noise; no repeated statistical trial establishes causality.

Raw plans contain all 150 samples per phase. `optimized/environment.json` records settings, row counts, index sizes and input/plan SHA-256 hashes.

## All 30 queries

| Query | CP2 (ms) | Local before (ms) | Problem in before plan | Optimization | After (ms) | Improvement | Same result? |
|---|---:|---:|---|---|---:|---|---|
| R01 | 0.125 | 0.104 | Seq Scan on units ;  Seq Scan on courses ;  Index Scan using uq_lesson_in_unit on lessons | SQL unchanged; broad aggregation or already selective access. No demonstrated targeted gain. | 0.098 | 5.77% (1.06×) | Yes, EXCEPT ALL |
| R02 | 0.045 | 0.029 | Index Scan using enrollments_pkey on enrollments ;  Seq Scan on courses | SQL unchanged; broad aggregation or already selective access. No demonstrated targeted gain. | 0.040 | -37.93% (0.72×) | Yes, EXCEPT ALL |
| R03 | 0.083 | 0.054 | Index Only Scan using daily_activity_pkey on daily_activity | SQL unchanged; broad aggregation or already selective access. No demonstrated targeted gain. | 0.046 | 14.81% (1.17×) | Yes, EXCEPT ALL |
| R04 | 4.563 | 4.362 | Index Scan using learners_pkey on learners ;  Seq Scan on lesson_attempts | Learner/date covering index; replace DATE(timestamp) with local-midnight half-open range. | 0.037 | 99.15% (117.89×) | Yes, EXCEPT ALL |
| R05 | 0.898 | 0.836 | Index Scan using league_memberships_pkey on league_memberships ;  Seq Scan on league_memberships ;  Index Scan using learners_pkey on learners | Week/cohort covering index narrows the leaderboard cohort. | 0.070 | 91.63% (11.94×) | Yes, EXCEPT ALL |
| R06 | 5.703 | 5.801 | Index Scan using uq_unit_in_course on units ;  Index Scan using uq_lesson_in_unit on lessons ;  Seq Scan on lesson_attempts | Learner-leading attempt index narrows the anti-join. | 0.054 | 99.07% (107.43×) | Yes, EXCEPT ALL |
| R07 | 15.611 | 16.133 | Seq Scan on lesson_attempts ;  Seq Scan on lessons ;  Seq Scan on units | Lesson covering index supports curriculum joins. | 6.211 | 61.50% (2.60×) | Yes, EXCEPT ALL |
| R08 | 17.704 | 18.173 | Seq Scan on lesson_attempts ;  Seq Scan on lessons | SQL unchanged; broad aggregation or already selective access. No demonstrated targeted gain. | 15.891 | 12.56% (1.14×) | Yes, EXCEPT ALL |
| R09 | 4.334 | 4.212 | Seq Scan on daily_activity | Date-leading activity index supports June filtering. | 0.860 | 79.58% (4.90×) | Yes, EXCEPT ALL |
| R10 | 4.621 | 4.245 | Seq Scan on daily_activity ;  Index Scan using learners_pkey on learners | SQL unchanged; broad aggregation or already selective access. No demonstrated targeted gain. | 3.938 | 7.23% (1.08×) | Yes, EXCEPT ALL |
| R11 | 0.024 | 0.016 | Index Scan using learners_username_key on learners | SQL unchanged; broad aggregation or already selective access. No demonstrated targeted gain. | 0.016 | 0.00% (1.00×) | Yes, EXCEPT ALL |
| R12 | 0.037 | 0.034 | Index Scan using learner_achievements_pkey on learner_achievements ;  Seq Scan on achievements | SQL unchanged; broad aggregation or already selective access. No demonstrated targeted gain. | 0.035 | -2.94% (0.97×) | Yes, EXCEPT ALL |
| R13 | 4.376 | 4.269 | Seq Scan on learners | Correct NOT IN NULL bug using NOT EXISTS; referral partial index. | 3.491 | 18.22% (1.22×) | Intentional NULL fix |
| R14 | 1.815 | 1.752 | Seq Scan on league_memberships | Week-leading league index supports date range. | 1.491 | 14.90% (1.18×) | Yes, EXCEPT ALL |
| R15 | 1.415 | 1.320 | Seq Scan on learners ;  Index Scan using daily_activity_pkey on daily_activity | Joined-at covering index narrows January learners. | 0.216 | 83.64% (6.11×) | Yes, EXCEPT ALL |
| R16 | 4.233 | 1.970 | Index Scan using learners_username_key on learners | SQL unchanged; broad aggregation or already selective access. No demonstrated targeted gain. | 1.934 | 1.83% (1.02×) | Yes, EXCEPT ALL |
| R17 | 15.259 | 13.187 | Seq Scan on lesson_attempts | SQL unchanged; broad aggregation or already selective access. No demonstrated targeted gain. | 12.714 | 3.59% (1.04×) | Yes, EXCEPT ALL |
| R18 | 6.064 | 5.855 | Seq Scan on enrollments ;  Seq Scan on courses | SQL unchanged; broad aggregation or already selective access. No demonstrated targeted gain. | 5.633 | 3.79% (1.04×) | Yes, EXCEPT ALL |
| R19 | 1559.461 | 1624.255 | Index Scan using uq_unit_in_course on units ;  Index Scan using uq_lesson_in_unit on lessons ;  Seq Scan on lesson_attempts | Aggregate attempts once, LEFT JOIN; preserve zero count and NULL average. | 17.446 | 98.93% (93.10×) | Yes, EXCEPT ALL |
| R20 | 8.389 | 7.843 | Seq Scan on lesson_attempts | Half-open timestamp range with covering time index. | 2.181 | 72.19% (3.60×) | Yes, EXCEPT ALL |
| R21 | 2.260 | 5.489 | Seq Scan on daily_activity ;  Index Only Scan using daily_activity_pkey on daily_activity | Date-leading activity index supports range and absence lookup. | 0.667 | 87.85% (8.23×) | Yes, EXCEPT ALL |
| R22 | 32.542 | 31.763 | Seq Scan on lesson_attempts | Covering timestamp index avoids sorting; retains OFFSET and same page. | 5.331 | 83.22% (5.96×) | Yes, EXCEPT ALL |
| R23 | 5.886 | 5.842 | Seq Scan on daily_activity ;  Seq Scan on learners | Date-leading activity index narrows recent rows. | 2.065 | 64.65% (2.83×) | Yes, EXCEPT ALL |
| R24 | 23.961 | 23.256 | Seq Scan on lesson_attempts ;  Seq Scan on lessons ;  Seq Scan on units | SQL unchanged; broad aggregation or already selective access. No demonstrated targeted gain. | 22.258 | 4.29% (1.04×) | Yes, EXCEPT ALL |
| R25 | 115.575 | 103.516 | Seq Scan on lesson_attempts ;  Seq Scan on learners | SQL unchanged; broad aggregation or already selective access. No demonstrated targeted gain. | 102.160 | 1.31% (1.01×) | Yes, EXCEPT ALL |
| W01 | 0.688 | 0.409 | (no scan) | Unchanged INSERT; maintains new attempt indexes. | 0.531 | -29.83% (0.77×) | Unchanged SQL; rollback |
| W02 | 0.612 | 0.522 | Index Scan using lesson_attempts_pkey on lesson_attempts | Unfinished-only descending-ID index covers timestamp filter and max ID. | 0.207 | 60.34% (2.52×) | Unchanged SQL; rollback |
| W03 | 0.362 | 0.311 | (no scan) | Unchanged upsert; maintains activity index. | 0.368 | -18.33% (0.85×) | Unchanged SQL; rollback |
| W04 | 5.128 | 4.906 | Seq Scan on league_memberships | Unchanged UPDATE; week/cohort index helps selection but adds maintenance. | 4.932 | -0.53% (0.99×) | Unchanged SQL; rollback |
| W05 | 35.788 | 34.215 | Seq Scan on achievements ;  Seq Scan on enrollments | Unchanged bulk INSERT; no new index on target table. | 33.377 | 2.45% (1.03×) | Unchanged SQL; rollback |
| **Total** | 1877.562 | **1924.679** | Sum of query averages | | **244.298** | **87.31% (7.88×)** | See R13 exception |

Totals are sums of rounded averages, not wall-clock benchmark duration. R13 changes the work performed, so the total is not a fully semantics-identical workload comparison.

## Correctness proof

R04, R19 and R20 pass bidirectional `EXCEPT ALL` comparisons (duplicates included) and ordered SHA-256 checksums. All other reads except R13 also pass bidirectional `EXCEPT ALL` on the seed data. For unchanged queries with nonunique ORDER BY keys, tied rows have unspecified relative order; R22 retains OFFSET rather than changing to keyset pagination. The five write SQL statements are unchanged; every measured execution rolls back. A separate full-data dump audit confirms 514,378 INSERT rows and the same SHA-256 before/final (see optimized/data_integrity.json); this audit is recorded for this run, not performed by the wrapper. See `optimized/equivalence.json` and `benchmarks/verify_cp3.py`.

R13 originally returns **0 rows**, but the corrected anti-join returns **24268 rows**. A NULL in referred_by makes NOT IN evaluate to unknown for nonmatches, which WHERE discards. NOT EXISTS expresses the requested learners who have referred nobody. This is an intentional correctness exception, not an equivalence claim. A separate three-row fixture tests NULL handling. [PostgreSQL NULL semantics](https://www.postgresql.org/docs/18/functions-subquery.html).

R19 keeps lessons without attempts: COALESCE supplies count zero while the average remains NULL. R04/R20 use local dates converted to timestamptz, retaining the session time-zone semantics of the original casts.

## Five biggest percentage improvements — first-run plans

### R04: 4.362 → 0.037 ms (99.15%)

Before

```text
=== R04 run 1 ===
GroupAggregate  (cost=4738.81..4738.83 rows=1 width=10) (actual time=3.884..4.449 rows=1.00 loops=1)
  Group Key: l.daily_goal_xp
  Buffers: shared hit=1798
  ->  Sort  (cost=4738.81..4738.81 rows=1 width=4) (actual time=3.881..4.446 rows=1.00 loops=1)
        Sort Key: l.daily_goal_xp
        Sort Method: quicksort  Memory: 25kB
        Buffers: shared hit=1798
        ->  Nested Loop Left Join  (cost=1000.29..4738.80 rows=1 width=4) (actual time=3.858..4.440 rows=1.00 loops=1)
              Buffers: shared hit=1795
              ->  Index Scan using learners_pkey on learners l  (cost=0.29..8.30 rows=1 width=6) (actual time=0.004..0.005 rows=1.00 loops=1)
                    Index Cond: (learner_id = 1042)
                    Index Searches: 1
                    Buffers: shared hit=3
              ->  Gather  (cost=1000.00..4730.48 rows=1 width=6) (actual time=3.853..4.433 rows=1.00 loops=1)
                    Workers Planned: 1
                    Workers Launched: 1
                    Buffers: shared hit=1792
                    ->  Parallel Seq Scan on lesson_attempts a  (cost=0.00..3730.38 rows=1 width=6) (actual time=3.051..3.110 rows=0.50 loops=2)
                          Filter: ((learner_id = 1042) AND (date(started_at) = '2026-06-30'::date))
                          Rows Removed by Filter: 94150
                          Buffers: shared hit=1792
Planning:
  Buffers: shared hit=227
Planning Time: 0.322 ms
Execution Time: 4.473 ms
```

After

```text
=== R04 run 1 ===
GroupAggregate  (cost=16.77..16.79 rows=1 width=10) (actual time=0.019..0.020 rows=1.00 loops=1)
  Group Key: l.daily_goal_xp
  Buffers: shared hit=10
  ->  Sort  (cost=16.77..16.78 rows=1 width=4) (actual time=0.016..0.016 rows=1.00 loops=1)
        Sort Key: l.daily_goal_xp
        Sort Method: quicksort  Memory: 25kB
        Buffers: shared hit=10
        ->  Nested Loop Left Join  (cost=0.71..16.76 rows=1 width=4) (actual time=0.010..0.010 rows=1.00 loops=1)
              Buffers: shared hit=7
              ->  Index Scan using learners_pkey on learners l  (cost=0.29..8.30 rows=1 width=6) (actual time=0.004..0.004 rows=1.00 loops=1)
                    Index Cond: (learner_id = 1042)
                    Index Searches: 1
                    Buffers: shared hit=3
              ->  Index Only Scan using idx_attempt_learner_started on lesson_attempts a  (cost=0.42..8.45 rows=1 width=6) (actual time=0.005..0.005 rows=1.00 loops=1)
                    Index Cond: ((learner_id = 1042) AND (started_at >= ('2026-06-30'::date)::timestamp with time zone) AND (started_at < ('2026-07-01'::date)::timestamp with time zone))
                    Heap Fetches: 0
                    Index Searches: 1
                    Buffers: shared hit=4
Planning:
  Buffers: shared hit=369 read=1
Planning Time: 0.690 ms
Execution Time: 0.040 ms
```

### R06: 5.801 → 0.054 ms (99.07%)

Before

```text
=== R06 run 1 ===
Limit  (cost=328.13..352.88 rows=1 width=14) (actual time=5.818..5.818 rows=1.00 loops=1)
  Buffers: shared hit=1806
  ->  Incremental Sort  (cost=328.13..4262.90 rows=159 width=14) (actual time=5.817..5.817 rows=1.00 loops=1)
        Sort Key: u.unit_no, l.lesson_no
        Presorted Key: u.unit_no
        Full-sort Groups: 1  Sort Method: top-N heapsort  Average Memory: 25kB  Peak Memory: 25kB
        Buffers: shared hit=1806
        ->  Nested Loop Anti Join  (cost=0.42..4259.86 rows=159 width=14) (actual time=5.794..5.808 rows=7.00 loops=1)
              Join Filter: (a.lesson_id = l.lesson_id)
              Rows Removed by Join Filter: 288
              Buffers: shared hit=1800
              ->  Nested Loop  (cost=0.42..99.69 rows=160 width=14) (actual time=0.005..0.008 rows=9.00 loops=1)
                    Buffers: shared hit=8
                    ->  Index Scan using uq_unit_in_course on units u  (cost=0.14..10.24 rows=20 width=6) (actual time=0.002..0.002 rows=2.00 loops=1)
                          Index Cond: (course_id = 1)
                          Index Searches: 1
                          Buffers: shared hit=2
                    ->  Index Scan using uq_lesson_in_unit on lessons l  (cost=0.28..4.39 rows=8 width=16) (actual time=0.002..0.002 rows=4.50 loops=2)
                          Index Cond: (unit_id = u.unit_id)
                          Index Searches: 2
                          Buffers: shared hit=6
              ->  Materialize  (cost=0.00..4145.78 rows=6 width=4) (actual time=0.009..0.643 rows=32.22 loops=9)
                    Storage: Memory  Maximum Storage: 18kB
                    Buffers: shared hit=1792
                    ->  Seq Scan on lesson_attempts a  (cost=0.00..4145.75 rows=6 width=4) (actual time=0.080..5.784 rows=39.00 loops=1)
                          Filter: ((completed_at IS NOT NULL) AND (learner_id = 1042))
                          Rows Removed by Filter: 188261
                          Buffers: shared hit=1792
Planning:
  Buffers: shared hit=276
Planning Time: 0.399 ms
Execution Time: 5.834 ms
```

After

```text
=== R06 run 1 ===
Limit  (cost=20.38..21.92 rows=1 width=14) (actual time=0.043..0.043 rows=1.00 loops=1)
  Buffers: shared hit=23
  ->  Incremental Sort  (cost=20.38..257.05 rows=154 width=14) (actual time=0.042..0.043 rows=1.00 loops=1)
        Sort Key: u.unit_no, l.lesson_no
        Presorted Key: u.unit_no
        Full-sort Groups: 1  Sort Method: top-N heapsort  Average Memory: 25kB  Peak Memory: 25kB
        Buffers: shared hit=23
        ->  Nested Loop Anti Join  (cost=0.84..254.09 rows=154 width=14) (actual time=0.023..0.035 rows=7.00 loops=1)
              Join Filter: (a.lesson_id = l.lesson_id)
              Rows Removed by Join Filter: 292
              Buffers: shared hit=17
              ->  Nested Loop  (cost=0.42..93.95 rows=160 width=14) (actual time=0.005..0.007 rows=9.00 loops=1)
                    Buffers: shared hit=8
                    ->  Index Scan using uq_unit_in_course on units u  (cost=0.14..10.24 rows=20 width=6) (actual time=0.002..0.002 rows=2.00 loops=1)
                          Index Cond: (course_id = 1)
                          Index Searches: 1
                          Buffers: shared hit=2
                    ->  Index Scan using uq_lesson_in_unit on lessons l  (cost=0.28..4.11 rows=8 width=16) (actual time=0.001..0.002 rows=4.50 loops=2)
                          Index Cond: (unit_id = u.unit_id)
                          Index Searches: 2
                          Buffers: shared hit=6
              ->  Materialize  (cost=0.42..13.90 rows=61 width=4) (actual time=0.001..0.002 rows=32.67 loops=9)
                    Storage: Memory  Maximum Storage: 18kB
                    Buffers: shared hit=9
                    ->  Index Only Scan using idx_attempt_learner_started on lesson_attempts a  (cost=0.42..13.60 rows=61 width=4) (actual time=0.007..0.013 rows=39.00 loops=1)
                          Index Cond: (learner_id = 1042)
                          Filter: (completed_at IS NOT NULL)
                          Heap Fetches: 5
                          Index Searches: 1
                          Buffers: shared hit=9
Planning:
  Buffers: shared hit=382
Planning Time: 0.556 ms
Execution Time: 0.061 ms
```

### R19: 1624.255 → 17.446 ms (98.93%)

Before

```text
=== R19 run 1 ===
Incremental Sort  (cost=102064.04..1326829.65 rows=160 width=48) (actual time=329.341..1588.731 rows=160.00 loops=1)
  Sort Key: u.unit_no, l.lesson_no
  Presorted Key: u.unit_no
  Full-sort Groups: 5  Sort Method: quicksort  Average Memory: 26kB  Peak Memory: 26kB
  Buffers: shared hit=573509
  ->  Nested Loop  (cost=0.42..1326824.49 rows=160 width=48) (actual time=10.844..1588.677 rows=160.00 loops=1)
        Buffers: shared hit=573503
        ->  Index Scan using uq_unit_in_course on units u  (cost=0.14..10.24 rows=20 width=6) (actual time=0.001..0.009 rows=20.00 loops=1)
              Index Cond: (course_id = 1)
              Index Searches: 1
              Buffers: shared hit=2
        ->  Index Scan using uq_lesson_in_unit on lessons l  (cost=0.28..4.39 rows=8 width=10) (actual time=0.002..0.004 rows=8.00 loops=20)
              Index Cond: (unit_id = u.unit_id)
              Index Searches: 20
              Buffers: shared hit=61
        SubPlan 1
          ->  Aggregate  (cost=4145.99..4146.00 rows=1 width=8) (actual time=5.418..5.418 rows=1.00 loops=160)
                Buffers: shared hit=286720
                ->  Seq Scan on lesson_attempts a  (cost=0.00..4145.75 rows=95 width=0) (actual time=0.026..5.408 rows=264.04 loops=160)
                      Filter: ((completed_at IS NOT NULL) AND (lesson_id = l.lesson_id))
                      Rows Removed by Filter: 188036
                      Buffers: shared hit=286720
        SubPlan 2
          ->  Aggregate  (cost=4146.02..4146.03 rows=1 width=32) (actual time=4.510..4.510 rows=1.00 loops=160)
                Buffers: shared hit=286720
                ->  Seq Scan on lesson_attempts a_1  (cost=0.00..4145.75 rows=107 width=2) (actual time=0.019..4.494 rows=298.36 loops=160)
                      Filter: (lesson_id = l.lesson_id)
                      Rows Removed by Filter: 188002
                      Buffers: shared hit=286720
Planning:
  Buffers: shared hit=275
Planning Time: 0.383 ms
Execution Time: 1588.770 ms
```

After

```text
=== R19 run 1 ===
Sort  (cost=5186.53..5186.93 rows=160 width=48) (actual time=17.095..17.098 rows=160.00 loops=1)
  Sort Key: u.unit_no, l.lesson_no
  Sort Method: quicksort  Memory: 31kB
  Buffers: shared hit=1809
  ->  Hash Right Join  (cost=5128.56..5180.67 rows=160 width=48) (actual time=16.774..17.074 rows=160.00 loops=1)
        Hash Cond: (lesson_attempts.lesson_id = l.lesson_id)
        Buffers: shared hit=1806
        ->  HashAggregate  (cost=5087.25..5113.60 rows=1757 width=44) (actual time=16.666..16.903 rows=1760.00 loops=1)
              Group Key: lesson_attempts.lesson_id
              Batches: 1  Memory Usage: 337kB
              Buffers: shared hit=1792
              ->  Seq Scan on lesson_attempts  (cost=0.00..3675.00 rows=188300 width=14) (actual time=0.002..4.359 rows=188300.00 loops=1)
                    Buffers: shared hit=1792
        ->  Hash  (cost=39.31..39.31 rows=160 width=8) (actual time=0.104..0.105 rows=160.00 loops=1)
              Buckets: 1024  Batches: 1  Memory Usage: 15kB
              Buffers: shared hit=14
              ->  Hash Join  (cost=5.00..39.31 rows=160 width=8) (actual time=0.015..0.098 rows=160.00 loops=1)
                    Hash Cond: (l.unit_id = u.unit_id)
                    Buffers: shared hit=14
                    ->  Seq Scan on lessons l  (cost=0.00..29.60 rows=1760 width=10) (actual time=0.002..0.039 rows=1760.00 loops=1)
                          Buffers: shared hit=12
                    ->  Hash  (cost=4.75..4.75 rows=20 width=6) (actual time=0.009..0.009 rows=20.00 loops=1)
                          Buckets: 1024  Batches: 1  Memory Usage: 9kB
                          Buffers: shared hit=2
                          ->  Seq Scan on units u  (cost=0.00..4.75 rows=20 width=6) (actual time=0.002..0.007 rows=20.00 loops=1)
                                Filter: (course_id = 1)
                                Rows Removed by Filter: 200
                                Buffers: shared hit=2
Planning:
  Buffers: shared hit=312
Planning Time: 0.501 ms
Execution Time: 17.131 ms
```

### R05: 0.836 → 0.070 ms (91.63%)

Before

```text
=== R05 run 1 ===
Sort  (cost=709.62..709.63 rows=1 width=33) (actual time=0.853..0.854 rows=30.00 loops=1)
  Sort Key: (rank() OVER w1)
  Sort Method: quicksort  Memory: 26kB
  Buffers: shared hit=363
  InitPlan 1
    ->  Index Scan using league_memberships_pkey on league_memberships  (cost=0.29..8.31 rows=1 width=4) (actual time=0.004..0.004 rows=1.00 loops=1)
          Index Cond: ((learner_id = 1042) AND (week_start = '2026-06-29'::date))
          Index Searches: 1
          Buffers: shared hit=3
  ->  WindowAgg  (cost=701.29..701.31 rows=1 width=33) (actual time=0.841..0.847 rows=30.00 loops=1)
        Window: w1 AS (ORDER BY lm.weekly_xp ROWS UNBOUNDED PRECEDING)
        Storage: Memory  Maximum Storage: 17kB
        Buffers: shared hit=360
        ->  Sort  (cost=701.29..701.29 rows=1 width=25) (actual time=0.838..0.839 rows=30.00 loops=1)
              Sort Key: lm.weekly_xp DESC
              Sort Method: quicksort  Memory: 26kB
              Buffers: shared hit=360
              ->  Nested Loop  (cost=0.29..701.28 rows=1 width=25) (actual time=0.071..0.831 rows=30.00 loops=1)
                    Buffers: shared hit=357
                    ->  Seq Scan on league_memberships lm  (cost=0.00..692.97 rows=1 width=8) (actual time=0.065..0.815 rows=30.00 loops=1)
                          Filter: ((week_start = '2026-06-29'::date) AND (cohort_id = (InitPlan 1).col1))
                          Rows Removed by Filter: 28568
                          Buffers: shared hit=267
                    ->  Index Scan using learners_pkey on learners le  (cost=0.29..8.30 rows=1 width=21) (actual time=0.000..0.000 rows=1.00 loops=30)
                          Index Cond: (learner_id = lm.learner_id)
                          Index Searches: 30
                          Buffers: shared hit=90
Planning:
  Buffers: shared hit=205
Planning Time: 0.341 ms
Execution Time: 0.882 ms
```

After

```text
=== R05 run 1 ===
Sort  (cost=20.95..20.95 rows=1 width=33) (actual time=0.044..0.046 rows=30.00 loops=1)
  Sort Key: (rank() OVER w1)
  Sort Method: quicksort  Memory: 26kB
  Buffers: shared hit=99
  InitPlan 1
    ->  Index Scan using league_memberships_pkey on league_memberships  (cost=0.29..8.31 rows=1 width=4) (actual time=0.004..0.004 rows=1.00 loops=1)
          Index Cond: ((learner_id = 1042) AND (week_start = '2026-06-29'::date))
          Index Searches: 1
          Buffers: shared hit=3
  ->  WindowAgg  (cost=0.57..12.63 rows=1 width=33) (actual time=0.020..0.039 rows=30.00 loops=1)
        Window: w1 AS (ORDER BY lm.weekly_xp ROWS UNBOUNDED PRECEDING)
        Storage: Memory  Maximum Storage: 17kB
        Buffers: shared hit=96
        ->  Nested Loop  (cost=0.57..12.61 rows=1 width=25) (actual time=0.018..0.030 rows=30.00 loops=1)
              Buffers: shared hit=96
              ->  Index Only Scan using idx_league_week_cohort on league_memberships lm  (cost=0.29..4.31 rows=1 width=8) (actual time=0.013..0.013 rows=30.00 loops=1)
                    Index Cond: ((week_start = '2026-06-29'::date) AND (cohort_id = (InitPlan 1).col1))
                    Heap Fetches: 0
                    Index Searches: 1
                    Buffers: shared hit=6
              ->  Index Scan using learners_pkey on learners le  (cost=0.29..8.30 rows=1 width=21) (actual time=0.000..0.000 rows=1.00 loops=30)
                    Index Cond: (learner_id = lm.learner_id)
                    Index Searches: 30
                    Buffers: shared hit=90
Planning:
  Buffers: shared hit=272
Planning Time: 0.464 ms
Execution Time: 0.078 ms
```

### R21: 5.489 → 0.667 ms (87.85%)

Before

```text
=== R21 run 1 ===
Sort  (cost=33139.90..33139.93 rows=9 width=4) (actual time=4.763..4.764 rows=39.00 loops=1)
  Sort Key: d.learner_id
  Sort Method: quicksort  Memory: 25kB
  Buffers: shared hit=1820
  ->  HashAggregate  (cost=3911.01..33139.76 rows=9 width=4) (actual time=4.527..4.755 rows=39.00 loops=1)
        Group Key: d.learner_id
        Filter: ((count(*) = 7) AND (NOT EXISTS(SubPlan 1)))
        Batches: 1  Memory Usage: 217kB
        Rows Removed by Filter: 2368
        Buffers: shared hit=1817
        ->  Seq Scan on daily_activity d  (cost=0.00..3892.63 rows=3676 width=4) (actual time=0.005..4.283 rows=3699.00 loops=1)
              Filter: ((activity_date >= '2026-06-23'::date) AND (activity_date <= '2026-06-29'::date))
              Rows Removed by Filter: 185410
              Buffers: shared hit=1056
        SubPlan 1
          ->  Index Only Scan using daily_activity_pkey on daily_activity t  (cost=0.42..8.44 rows=1 width=0) (actual time=0.001..0.001 rows=0.81 loops=200)
                Index Cond: ((learner_id = d.learner_id) AND (activity_date = '2026-06-30'::date))
                Heap Fetches: 161
                Index Searches: 200
                Buffers: shared hit=761
Planning:
  Buffers: shared hit=108
Planning Time: 0.184 ms
Execution Time: 4.796 ms
```

After

```text
=== R21 run 1 ===
GroupAggregate  (cost=578.87..36257.16 rows=11 width=4) (actual time=0.364..0.616 rows=39.00 loops=1)
  Group Key: d.learner_id
  Filter: ((count(*) = 7) AND (NOT (ANY (d.learner_id = (hashed SubPlan 2).col1))))
  Rows Removed by Filter: 2368
  Buffers: shared hit=28
  ->  Sort  (cost=578.87..590.24 rows=4547 width=4) (actual time=0.294..0.353 rows=3699.00 loops=1)
        Sort Key: d.learner_id
        Sort Method: quicksort  Memory: 97kB
        Buffers: shared hit=22
        ->  Index Only Scan using idx_activity_date on daily_activity d  (cost=0.42..302.62 rows=4547 width=4) (actual time=0.006..0.125 rows=3699.00 loops=1)
              Index Cond: ((activity_date >= '2026-06-23'::date) AND (activity_date <= '2026-06-29'::date))
              Heap Fetches: 2
              Index Searches: 1
              Buffers: shared hit=19
  SubPlan 2
    ->  Index Only Scan using idx_activity_date on daily_activity t  (cost=0.42..63.90 rows=441 width=4) (actual time=0.002..0.019 rows=486.00 loops=1)
          Index Cond: (activity_date = '2026-06-30'::date)
          Heap Fetches: 0
          Index Searches: 1
          Buffers: shared hit=6
Planning:
  Buffers: shared hit=138
Planning Time: 0.240 ms
Execution Time: 0.641 ms
```

## Write overhead

| Query | Before (ms) | After (ms) | Delta (ms) | Delta (%) |
|---|---:|---:|---:|---:|
| W01 | 0.409 | 0.531 | +0.122 | +29.83% |
| W02 | 0.522 | 0.207 | -0.315 | -60.34% |
| W03 | 0.311 | 0.368 | +0.057 | +18.33% |
| W04 | 4.906 | 4.932 | +0.026 | +0.53% |
| W05 | 34.215 | 33.377 | -0.838 | -2.45% |

Additional attempt/activity/league indexes add write maintenance. The table reports measured regressions rather than hiding them; sub-millisecond absolute increases are acceptable for this seed workload given the read gains. W05 has no new index on its target, so changes there should be treated as execution variability. These measurements exclude commit/fsync latency and do not establish production write capacity.

## Index storage

| Index | Table | Index bytes | Table heap bytes | Index / heap |
|---|---|---:|---:|---:|
| idx_activity_date | daily_activity | 5980160 | 8650752 | 69.13% |
| idx_attempt_learner_started | lesson_attempts | 9363456 | 14680064 | 63.78% |
| idx_attempt_lesson | lesson_attempts | 5963776 | 14680064 | 40.62% |
| idx_attempt_started | lesson_attempts | 7651328 | 14680064 | 52.12% |
| idx_attempt_unfinished | lesson_attempts | 696320 | 14680064 | 4.74% |
| idx_league_week_cohort | league_memberships | 942080 | 2236416 | 42.12% |
| idx_learner_joined | learners | 958464 | 3014656 | 31.79% |
| idx_learner_referral | learners | 188416 | 3014656 | 6.25% |

Total new index storage: **31,744,000 bytes**. Table sizes use pg_relation_size (heap main fork), excluding existing indexes/TOAST. Equality-leading columns and INCLUDE payloads support selective covering access; partial indexes omit irrelevant NULL/finished rows. [PostgreSQL multicolumn indexes](https://www.postgresql.org/docs/18/indexes-multicolumn.html).

## Limits and queries without a convincing speedup

R08/R10/R17/R18/R24/R25 aggregate or join broad portions of the dataset and retain sequential scans. R16 still filters an ordered username index for ILIKE; no selective prefix index was added. R11/R12 were already tiny key lookups. Treat minor gains/regressions on unchanged plans as noise. R22 still reads/discards 100,000 index entries; eliminating its sort does not remove deep-offset scaling costs. No claim is made that each index independently causes each improvement; this compares the combined change set.

## Reproduce

Use PostgreSQL 15+ and the repository root. Set PGHOST/PGPORT/PGUSER as needed and add PostgreSQL binaries to PATH. Choose a fresh disposable database name; seed CSV files stay uncommitted. Index SQL is intentionally applied once.

```bash
unzip seed_data.zip
createdb cp3
psql -X -v ON_ERROR_STOP=1 -1 -d cp3 -f sql/01_schema.sql
psql -X -v ON_ERROR_STOP=1 -1 -d cp3 -f sql/02_load_data.sql
./benchmarks/run_cp3.sh cp3
```

Archive the existing cp3_baseline and optimized directories before rerunning (the wrapper refuses to overwrite them). The committed benchmark script is used unchanged; its directory argument supports these phase names. To audit existing results without rerunning SQL: inspect every Execution Time line and compare its five-sample mean/median to summary.csv. `report_cp3.py` validates these before regenerating the report; it also requires the measured database online to capture sizes/settings.
