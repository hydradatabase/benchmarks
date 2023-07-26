#!/bin/bash

set -x

if [ -z "${RUNTIME}" ] ; then
  RUNTIME=`date "+%Y-%m-%d.%H:%M:%S"`
fi
TRIES=${TRIES:-3}

ANALYZE=true
LOAD=true
DIRNAME=$(dirname -- "$0")

while getopts 'b:v:u:t:znh' OPTION; do
  case "$OPTION" in
    b)
      BENCHMARK="$OPTARG"
      ;;
    v)
      VARIANT="$OPTARG"
      ;;
    u)
      USER="$OPTARG"
      ;;
    n)
      LOAD=false
      ;;
    z)
      ANALYZE=false
      ;;
    t)
      TAG="$OPTARG"
      ;;
    h)
      echo "run-benchmark.sh [-b benchmark] [-v variant] [-n]"
      echo "   -b benchmark to run: clickbench, warehouse, or pgbench"
      echo "   -v variant to use: cached, uncompressed, or zstd"
      echo "   -n disables loading and deleting of data"
      echo "   -u user to run psql as"
      echo "   -z disables analyzing data"
      echo "   -t tag"
      echo "   -h this help"
      exit 0
      ;;
    ?)
      echo "run-benchmark.sh [-b benchmark] [-v variant] [-n]" >&2
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"

if [ -z "${BENCHMARK-}" ] ; then
  echo "ERROR: you must provide a benchmark"
  exit 1
fi

if [ -z "${VARIANT-}" ] ; then
  echo "ERROR: you must provide a variant"
  exit 1
fi

cd $DIRNAME

if [ -z "${TAG}" ] ; then
  PATHNAME=results/$BENCHMARK/$VARIANT/$RUNTIME
  ANALYZED=results/$BENCHMARK-$VARIANT-$RUNTIME.json
else
  PATHNAME=results/$BENCHMARK/$VARIANT/$TAG/$RUNTIME
  ANALYZED=results/$BENCHMARK-$VARIANT-$TAG-$RUNTIME.json
fi

# set up the output directory
mkdir -p $PATHNAME


if [ -z "$DATABASE_URL" ]; then
  PSQL="psql -U $USER"
else
  PSQL="psql $DATABASE_URL"
fi

if [ "$LOAD" = true ] ; then
  $PSQL -c "CREATE DATABASE \"$BENCHMARK\""
fi

$PSQL $BENCHMARK -f variants/$VARIANT/setup.sql -f $BENCHMARK/setup.sql >$PATHNAME/setup.out 2>$PATHNAME/setup.err
$PSQL $BENCHMARK -f variants/$VARIANT/data.sql -f $BENCHMARK/data.sql >$PATHNAME/data.out 2>$PATHNAME/data.err

if [ "$(cat $PATHNAME/*.err | grep -v NOTICE | wc -l)" != "0" ]; then
  echo Error detected:
  cat $PATHNAME/*.err
  exit 1
fi

for query in $BENCHMARK/queries/*; do
  if [ -z "$DATABASE_URL" ]; then
    sync
    echo 3 | tee /proc/sys/vm/drop_caches
  fi
  file="$(basename $query)"
  for i in $(seq 1 $TRIES); do
    $PSQL $BENCHMARK -f variants/$VARIANT/query.sql -f $query >$PATHNAME/$file-$i.out
  done
done

if [ "$ANALYZE" = true ] ; then
  ./analyze.js $PATHNAME > $ANALYZED
fi

if [ "$LOAD" = true ] ; then
  $PSQL -c "DROP DATABASE \"$BENCHMARK\""
fi
