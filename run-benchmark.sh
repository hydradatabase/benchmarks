#!/bin/bash

RUNTIME=`date "+%Y-%m-%d.%H:%M:%S"`
TRIES=3

LOAD=true
DIRNAME=$(dirname -- "$0")

while getopts 'b:v:u:t:nh' OPTION; do
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
    t)
      TAG="$OPTARG"
      ;;
    h)
      echo "run-benchmark.sh [-b benchmark] [-v variant] [-n]"
      echo "   -b benchmark to run: clickbench, tpc-h, or pgbench"
      echo "   -v variant to use: cached, uncompressed, or zstd"
      echo "   -n disables loading and deleting of data"
      echo "   -u user to run psql as"
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


if [ "$LOAD" = true ] ; then
  createdb -U $USER $BENCHMARK
fi


psql -U $USER $BENCHMARK -f variants/$VARIANT/setup.sql -f $BENCHMARK/setup.sql >$PATHNAME/setup.out
psql -U $USER $BENCHMARK -f variants/$VARIANT/data.sql -f $BENCHMARK/data.sql >$PATHNAME/data.out

for query in $BENCHMARK/queries/*; do
  sync
  echo 3 | tee /proc/sys/vm/drop_caches
  file=`echo $query | cut -f 3 -d '/'`
  for i in $(seq 1 $TRIES); do
    psql -U $USER $BENCHMARK -f variants/$VARIANT/query.sql -f $query >$PATHNAME/$file-$i.out
  done
done

./analyze.js $PATHNAME > $ANALYZED

if [ "$LOAD" = true ] ; then
  dropdb -U $USER $BENCHMARK
fi
