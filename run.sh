#!/bin/bash

RUNTIME=`date "+%Y-%m-%d.%H:%M:%S"`
TRIES=3

BENCHMARK=$1
VARIANT=$2

# set up the output directory
mkdir -p results/$BENCHMARK/$VARIANT/$RUNTIME

createdb $BENCHMARK

psql $BENCHMARK -f variants/$VARIANT/setup.sql -f $BENCHMARK/setup.sql >results/$BENCHMARK/$VARIANT/$RUNTIME/setup.out
psql $BENCHMARK -f variants/$VARIANT/data.sql -f $BENCHMARK/data.sql >results/$BENCHMARK/$VARIANT/$RUNTIME/data.out

for query in $BENCHMARK/queries/*; do
  sync
  #echo 3 | sudo tee /proc/sys/vm/drop_caches
  file=`echo $query | cut -f 3 -d '/'`
  for i in $(seq 1 $TRIES); do
    psql $BENCHMARK -f variants/$VARIANT/query.sql -f $query >results/$BENCHMARK/$VARIANT/$RUNTIME/$file-$i.out
  done
done


dropdb $BENCHMARK
