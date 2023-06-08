#!/bin/bash

set -o nounset

RUNTIME=`date "+%Y-%m-%d.%H:%M:%S"`
TRIES=3

LOAD=true
BENCHMARK=clickbench
VARIANT=zstd

while getopts 'b:v:u:nh' OPTION; do
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
    h)
      echo "run.sh [-b benchmark] [-v variant] [-n]"
      echo "   -b benchmark to run: clickbench, tpc-h, or pgbench"
      echo "   -v variant to use: cached, uncompressed, or zstd"
      echo "   -n disables loading and deleting of data"
      echo "   -u user to run psql as"
      echo "   -h this help"
      exit 0
      ;;
    ?)
      echo "run.sh [-b benchmark] [-v variant] [-n]" >&2
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


# set up the output directory
mkdir -p results/$BENCHMARK/$VARIANT/$RUNTIME

if [ "$LOAD" = true ] ; then
  createdb -U $USER $BENCHMARK
fi


psql -U $USER $BENCHMARK -f variants/$VARIANT/setup.sql -f $BENCHMARK/setup.sql >results/$BENCHMARK/$VARIANT/$RUNTIME/setup.out
psql -U $USER $BENCHMARK -f variants/$VARIANT/data.sql -f $BENCHMARK/data.sql >results/$BENCHMARK/$VARIANT/$RUNTIME/data.out

for query in $BENCHMARK/queries/*; do
  sync
  echo 3 | tee /proc/sys/vm/drop_caches
  file=`echo $query | cut -f 3 -d '/'`
  for i in $(seq 1 $TRIES); do
    psql -U $USER $BENCHMARK -f variants/$VARIANT/query.sql -f $query >results/$BENCHMARK/$VARIANT/$RUNTIME/$file-$i.out
  done
done

./analyze.js results/$BENCHMARK/$VARIANT/$RUNTIME > results/$BENCHMARK-$VARIANT-$RUNTIME.json

if [ "$LOAD" = true ] ; then
  dropdb -U $USER $BENCHMARK
fi
