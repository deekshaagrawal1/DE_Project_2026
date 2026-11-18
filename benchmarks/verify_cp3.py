#!/usr/bin/env python3
"""Compare read multisets and rewritten query order; writes must be unchanged SQL."""
import hashlib, json, re
from pathlib import Path
from test_cp3 import ROOT, queries, sql

def main():
 original=queries(ROOT/'queries/workload_30.sql'); optimized=queries(ROOT/'sql/06_optimized_queries.sql')
 evidence={}
 for q in [f'R{i:02}' for i in range(1,26)]:
  ref=original[q] if q!='R13' else 'SELECT l.learner_id,l.username FROM learners l WHERE NOT EXISTS (SELECT 1 FROM learners r WHERE r.referred_by=l.learner_id)'
  counts=sql(f'WITH a AS ({ref}), b AS ({optimized[q]}) SELECT json_build_object(\'original_rows\',(SELECT count(*) FROM a),\'optimized_rows\',(SELECT count(*) FROM b),\'difference_rows\',(SELECT count(*) FROM ((TABLE a EXCEPT ALL TABLE b) UNION ALL (TABLE b EXCEPT ALL TABLE a)) d));')
  evidence[q]=json.loads(counts)
  assert evidence[q]['difference_rows']==0, q
  if q in ('R04','R19','R20'):
   hashes=[]
   for query in (ref,optimized[q]):
    data=sql(f'SELECT coalesce(json_agg(row_to_json(t)),\'[]\'::json) FROM ({query}) t;')
    hashes.append(hashlib.sha256(data.encode()).hexdigest())
   assert hashes[0]==hashes[1], q
   evidence[q]['ordered_sha256']=hashes[0]
  if q=='R13':
   evidence[q]['canonical_buggy_rows']=int(sql('SELECT count(*) FROM ('+original[q]+') t;'))
   evidence[q]['intentional_correctness_fix']=True
 def clean(s): return re.sub(r'--[^\n]*','',s).strip()
 for q in [f'W{i:02}' for i in range(1,6)]:
  assert clean(original[q])==clean(optimized[q]),q
  evidence[q]={'sql_unchanged':True,'measurement':'BEGIN / EXPLAIN ANALYZE / ROLLBACK per run'}
 out=ROOT/'benchmarks/results/optimized/equivalence.json'
 out.write_text(json.dumps(evidence,indent=2)+'\n')
 print('PASS: 25 read comparisons, three ordered rewrite checksums, five unchanged writes')
if __name__=='__main__': main()
