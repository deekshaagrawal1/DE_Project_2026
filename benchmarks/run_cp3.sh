#!/usr/bin/env bash
# Disposable, freshly seeded database only. Existing CP2 artifacts remain untouched.
set -euo pipefail
DB="${1:?Usage: benchmarks/run_cp3.sh disposable_database}"
cd "$(dirname "$0")/.."
export PGOPTIONS="${PGOPTIONS:-} -c timezone=Asia/Kolkata"
for phase in cp3_baseline optimized; do
  if [[ -e "benchmarks/results/$phase" ]]; then
    echo "Archive benchmarks/results/$phase before rerunning." >&2; exit 1
  fi
done
# A previous optimization must not contaminate the local baseline.
SECONDARY=$(psql -X -qAt -v ON_ERROR_STOP=1 -d "$DB" -c "SELECT count(*) FROM pg_index i JOIN pg_class t ON t.oid=i.indrelid JOIN pg_namespace n ON n.oid=t.relnamespace WHERE n.nspname='duolingo' AND NOT EXISTS (SELECT 1 FROM pg_constraint c WHERE c.conindid=i.indexrelid)")
if [[ "$SECONDARY" != 0 ]]; then
  echo "Use a freshly seeded database with constraint indexes only." >&2; exit 1
fi
PGDATABASE="$DB" python3 benchmarks/test_cp3.py
./benchmarks/run_benchmark.sh "$DB" cp3_baseline 5
psql -X -v ON_ERROR_STOP=1 -1 -d "$DB" -f sql/05_indexes.sql
./benchmarks/run_benchmark.sh "$DB" optimized 5 sql/06_optimized_queries.sql
PGDATABASE="$DB" python3 benchmarks/test_cp3.py
PGDATABASE="$DB" python3 benchmarks/verify_cp3.py
PGDATABASE="$DB" python3 benchmarks/report_cp3.py
