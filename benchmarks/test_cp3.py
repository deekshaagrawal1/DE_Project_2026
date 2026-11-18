"""Integration tests: run against a freshly seeded disposable database."""
import os, re, subprocess, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def sql(s):
 r=subprocess.run(['psql','-X','-qAt','-v','ON_ERROR_STOP=1','-d',os.environ.get('PGDATABASE','cp3')],input="SET search_path TO duolingo; SET TIME ZONE 'Asia/Kolkata';\n"+s,text=True,capture_output=True)
 if r.returncode: raise AssertionError(r.stderr)
 return r.stdout.strip()
def queries(p):
 text=Path(p).read_text()
 return {m[1]:m[2].strip().rstrip(';') for m in re.finditer(r'^-- @([RW]\d+)\n(.*?)(?=^-- @)',text,re.M|re.S)}
class Equivalence(unittest.TestCase):
 def test_read_results(self):
  original=queries(ROOT/'queries/workload_30.sql'); optimized=queries(ROOT/'sql/06_optimized_queries.sql')
  self.assertEqual(len(optimized),30)
  for q in [f'R{i:02}' for i in range(1,26)]:
   with self.subTest(query=q):
    ref=original[q] if q!='R13' else 'SELECT l.learner_id,l.username FROM learners l WHERE NOT EXISTS (SELECT 1 FROM learners r WHERE r.referred_by=l.learner_id)'
    result=sql(f'WITH a AS ({ref}), b AS ({optimized[q]}) SELECT count(*) FROM ((TABLE a EXCEPT ALL TABLE b) UNION ALL (TABLE b EXCEPT ALL TABLE a)) d;')
    self.assertEqual(result,'0')
 def test_null_regression(self):
  query=queries(ROOT/'sql/06_optimized_queries.sql')['R13']
  fixture="WITH learners(learner_id,username,referred_by) AS (VALUES (1,'a',NULL::int),(2,'b',1),(3,'c',NULL::int)) "
  self.assertEqual(sql(fixture+'SELECT count(*) FROM ('+query+') t;'),'2')

if __name__=='__main__': unittest.main()
