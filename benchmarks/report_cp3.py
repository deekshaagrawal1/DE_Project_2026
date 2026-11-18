#!/usr/bin/env python3
"""Validate raw measurements, capture DB evidence and generate the CP3 report."""
import csv, hashlib, json, platform, re
from datetime import datetime, timezone
from pathlib import Path
from test_cp3 import ROOT, sql
RESULTS=ROOT/'benchmarks/results'

def measured(phase):
 rows=list(csv.DictReader((RESULTS/phase/'summary.csv').read_text().splitlines()))
 assert [r['query_id'] for r in rows]==[f'R{i:02}' for i in range(1,26)]+[f'W{i:02}' for i in range(1,6)]
 for row in rows:
  raw=(RESULTS/phase/(row['query_id']+'.txt')).read_text()
  times=[float(t) for t in re.findall(r'^Execution Time: ([0-9.]+) ms$',raw,re.M)]
  assert len(times)==5,(phase,row['query_id'])
  assert abs(sum(times)/5-float(row['avg_ms']))<=0.000501,(phase,row['query_id'])
  assert abs(sorted(times)[2]-float(row['median_ms']))<0.000001
 return rows

def main():
 before=measured('cp3_baseline'); after=measured('optimized')
 cp2={r['query_id']:r for r in csv.DictReader((RESULTS/'baseline/summary.csv').read_text().splitlines())}
 proof=json.loads((RESULTS/'optimized/equivalence.json').read_text())
 indexes=json.loads(sql("""SELECT json_agg(t) FROM (SELECT indexname,tablename,
 pg_relation_size(quote_ident(schemaname)||'.'||quote_ident(indexname)) AS index_bytes,
 pg_relation_size(quote_ident(schemaname)||'.'||quote_ident(tablename)) AS table_bytes,indexdef
 FROM pg_indexes WHERE schemaname='duolingo' AND indexname LIKE 'idx_%' ORDER BY indexname) t;"""))
 environment=json.loads(sql("""SELECT json_build_object('version',version(),'timezone',current_setting('TimeZone'),
 'collation',(SELECT datcollate FROM pg_database WHERE datname=current_database()),'settings',(SELECT json_object_agg(name,setting) FROM pg_settings
 WHERE name IN ('work_mem','shared_buffers','effective_cache_size','jit','max_parallel_workers_per_gather',
 'enable_seqscan','enable_indexscan','random_page_cost','seq_page_cost')));"""))
 environment.update(captured_at_utc=datetime.now(timezone.utc).isoformat(),machine=platform.platform(),
  repository_base='8450262ff251c5c2bb920e3218bd8cc8f9cb64f3',runs_per_query=5,
  indexes=indexes,table_counts={},sha256={})
 for name in ['languages','courses','units','lessons','learners','achievements','enrollments','lesson_attempts','daily_activity','league_memberships','learner_achievements']:
  environment['table_counts'][name]=int(sql(f'SELECT count(*) FROM {name};'))
 for p in [ROOT/'seed_data.zip',ROOT/'queries/workload_30.sql',ROOT/'sql/01_schema.sql',ROOT/'sql/05_indexes.sql',ROOT/'sql/06_optimized_queries.sql',* (RESULTS/'cp3_baseline').glob('*.txt'),* (RESULTS/'optimized').glob('*.txt')]:
  if p.exists(): environment['sha256'][str(p.relative_to(ROOT))]=hashlib.sha256(p.read_bytes()).hexdigest()
 (RESULTS/'optimized/environment.json').write_text(json.dumps(environment,indent=2)+'\n')
 changes={
 'R04':'Learner/date covering index; replace DATE(timestamp) with local-midnight half-open range.',
 'R05':'Week/cohort covering index narrows the leaderboard cohort.',
 'R06':'Learner-leading attempt index narrows the anti-join.',
 'R07':'Lesson covering index supports curriculum joins.',
 'R09':'Date-leading activity index supports June filtering.',
 'R13':'Correct NOT IN NULL bug using NOT EXISTS; referral partial index.',
 'R14':'Week-leading league index supports date range.',
 'R15':'Joined-at covering index narrows January learners.',
 'R19':'Aggregate attempts once, LEFT JOIN; preserve zero count and NULL average.',
 'R20':'Half-open timestamp range with covering time index.',
 'R21':'Date-leading activity index supports range and absence lookup.',
 'R22':'Covering timestamp index avoids sorting; retains OFFSET and same page.',
 'R23':'Date-leading activity index narrows recent rows.',
 'W01':'Unchanged INSERT; maintains new attempt indexes.',
 'W02':'Unfinished-only descending-ID index covers timestamp filter and max ID.',
 'W03':'Unchanged upsert; maintains activity index.',
 'W04':'Unchanged UPDATE; week/cohort index helps selection but adds maintenance.',
 'W05':'Unchanged bulk INSERT; no new index on target table.'}
 lines=['# CP3 — Optimization report','',
 '## Measurement provenance','',
 'Measured on 18 November 2026 using PostgreSQL 18.6 (Postgres.app), macOS/Apple Silicon, in an isolated local database loaded from the repository seed archive. '
 'The existing CP2 results were measured on another machine/server version and are preserved unchanged. '
 'For a fair speed comparison, `cp3_baseline/` contains a fresh untuned run on this same machine; the table also shows the committed CP2 averages for reference.', '',
 'Five consecutive runs per query in both local phases; PostgreSQL `EXPLAIN (ANALYZE, BUFFERS)` Execution Time excludes planning/client startup and includes instrumentation overhead. '
 'Every write ran inside BEGIN/ROLLBACK. Time zone Asia/Kolkata, default server settings, no performance configuration overrides, no materialized caches and no dataset edits. '
 'Only constraint indexes existed before CP3. The database was ANALYZEd after loading and creating indexes. '
 'This is a sequential cache-dependent benchmark; correctness checks warm caches before the baseline and index creation affects cache state. No cold-cache or concurrent-load claim is made. '
 'Rollback does not reverse physical work, dead tuples, WAL or cache effects. Small differences may be noise; no repeated statistical trial establishes causality.', '',
 'Raw plans contain all 150 samples per phase. `optimized/environment.json` records settings, row counts, index sizes and input/plan SHA-256 hashes.', '',
 '## All 30 queries','',
 '| Query | CP2 (ms) | Local before (ms) | Problem in before plan | Optimization | After (ms) | Improvement | Same result? |',
 '|---|---:|---:|---|---|---:|---|---|']
 improvements=[]
 for b,a in zip(before,after):
  q=b['query_id']; bv=float(b['avg_ms']);av=float(a['avg_ms']);pct=(bv-av)/bv*100
  improvements.append((pct,q,bv,av))
  same='Intentional NULL fix' if q=='R13' else ('Unchanged SQL; rollback' if q.startswith('W') else 'Yes, EXCEPT ALL')
  problem=b['scan_nodes'].replace('|','; ')
  change=changes.get(q,'SQL unchanged; broad aggregation or already selective access. No demonstrated targeted gain.')
  lines.append(f"| {q} | {cp2[q]['avg_ms']} | {bv:.3f} | {problem} | {change} | {av:.3f} | {pct:.2f}% ({bv/av:.2f}×) | {same} |")
 bt=sum(float(b['avg_ms']) for b in before);at=sum(float(a['avg_ms']) for a in after)
 lines += [f'| **Total** | {sum(float(r["avg_ms"]) for r in cp2.values()):.3f} | **{bt:.3f}** | Sum of query averages | | **{at:.3f}** | **{(bt-at)/bt*100:.2f}% ({bt/at:.2f}×)** | See R13 exception |','',
 'Totals are sums of rounded averages, not wall-clock benchmark duration. R13 changes the work performed, so the total is not a fully semantics-identical workload comparison.', '',
 '## Correctness proof','',
 'R04, R19 and R20 pass bidirectional `EXCEPT ALL` comparisons (duplicates included) and ordered SHA-256 checksums. '
 'All other reads except R13 also pass bidirectional `EXCEPT ALL` on the seed data. '
 'For unchanged queries with nonunique ORDER BY keys, tied rows have unspecified relative order; R22 retains OFFSET rather than changing to keyset pagination. '
 'The five write SQL statements are unchanged; every measured execution rolls back. A separate full-data dump audit confirms 514,378 INSERT rows and the same SHA-256 before/final (see optimized/data_integrity.json); this audit is recorded for this run, not performed by the wrapper. See `optimized/equivalence.json` and `benchmarks/verify_cp3.py`.', '',
 f"R13 originally returns **{proof['R13']['canonical_buggy_rows']} rows**, but the corrected anti-join returns **{sql('SELECT count(*) FROM learners l WHERE NOT EXISTS (SELECT 1 FROM learners r WHERE r.referred_by=l.learner_id);')} rows**. "
 'A NULL in referred_by makes NOT IN evaluate to unknown for nonmatches, which WHERE discards. '
 'NOT EXISTS expresses the requested learners who have referred nobody. This is an intentional correctness exception, not an equivalence claim. '
 'A separate three-row fixture tests NULL handling. [PostgreSQL NULL semantics](https://www.postgresql.org/docs/18/functions-subquery.html).', '',
 'R19 keeps lessons without attempts: COALESCE supplies count zero while the average remains NULL. '
 'R04/R20 use local dates converted to timestamptz, retaining the session time-zone semantics of the original casts.','',
 '## Five biggest percentage improvements — first-run plans','']
 for pct,q,bv,av in sorted([x for x in improvements if x[1]!='R13'],reverse=True)[:5]:
  lines += [f'### {q}: {bv:.3f} → {av:.3f} ms ({pct:.2f}%)','']
  for title,phase in [('Before','cp3_baseline'),('After','optimized')]:
   raw=(RESULTS/phase/(q+'.txt')).read_text().split(f'=== {q} run 2 ===')[0]
   lines += [title,'','```text',raw.strip(),'```','']
 lines += ['## Write overhead','', '| Query | Before (ms) | After (ms) | Delta (ms) | Delta (%) |','|---|---:|---:|---:|---:|']
 for b,a in zip(before[-5:],after[-5:]):
  bv=float(b['avg_ms']);av=float(a['avg_ms'])
  lines.append(f"| {b['query_id']} | {bv:.3f} | {av:.3f} | {av-bv:+.3f} | {(av-bv)/bv*100:+.2f}% |")
 lines += ['', 'Additional attempt/activity/league indexes add write maintenance. The table reports measured regressions rather than hiding them; '
 'sub-millisecond absolute increases are acceptable for this seed workload given the read gains. '
 'W05 has no new index on its target, so changes there should be treated as execution variability. '
 'These measurements exclude commit/fsync latency and do not establish production write capacity.','',
 '## Index storage','', '| Index | Table | Index bytes | Table heap bytes | Index / heap |','|---|---|---:|---:|---:|']
 for i in indexes: lines.append(f"| {i['indexname']} | {i['tablename']} | {i['index_bytes']} | {i['table_bytes']} | {i['index_bytes']/i['table_bytes']*100:.2f}% |")
 lines += ['',f"Total new index storage: **{sum(i['index_bytes'] for i in indexes):,} bytes**. Table sizes use pg_relation_size (heap main fork), excluding existing indexes/TOAST. "
 'Equality-leading columns and INCLUDE payloads support selective covering access; partial indexes omit irrelevant NULL/finished rows. '
 '[PostgreSQL multicolumn indexes](https://www.postgresql.org/docs/18/indexes-multicolumn.html).','',
 '## Limits and queries without a convincing speedup','',
 'R08/R10/R17/R18/R24/R25 aggregate or join broad portions of the dataset and retain sequential scans. '
 'R16 still filters an ordered username index for ILIKE; no selective prefix index was added. '
 'R11/R12 were already tiny key lookups. Treat minor gains/regressions on unchanged plans as noise. '
 'R22 still reads/discards 100,000 index entries; eliminating its sort does not remove deep-offset scaling costs. '
 'No claim is made that each index independently causes each improvement; this compares the combined change set.', '',
 '## Reproduce','',
 'Use PostgreSQL 15+ and the repository root. Set PGHOST/PGPORT/PGUSER as needed and add PostgreSQL binaries to PATH. '
 'Choose a fresh disposable database name; seed CSV files stay uncommitted. Index SQL is intentionally applied once.', '',
 '```bash','unzip seed_data.zip','createdb cp3',
 'psql -X -v ON_ERROR_STOP=1 -1 -d cp3 -f sql/01_schema.sql',
 'psql -X -v ON_ERROR_STOP=1 -1 -d cp3 -f sql/02_load_data.sql',
 './benchmarks/run_cp3.sh cp3','```','',
 'Archive the existing cp3_baseline and optimized directories before rerunning (the wrapper refuses to overwrite them). '
 'The committed benchmark script is used unchanged; its directory argument supports these phase names. '
 'To audit existing results without rerunning SQL: inspect every Execution Time line and compare its five-sample mean/median to summary.csv. '
 '`report_cp3.py` validates these before regenerating the report; it also requires the measured database online to capture sizes/settings.','']
 (ROOT/'docs/04_optimization_report.md').write_text('\n'.join(lines))
 print(f'Validated 300 measurements; total {bt:.3f} -> {at:.3f} ms; report generated')
if __name__=='__main__': main()
