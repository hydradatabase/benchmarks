#!/bin/bash

MEMORY=8000m
CPU=4
IMAGENAME=hydra-benchmark
VARIANT=zstd
DIRNAME=$(dirname -- "$0")
USER=postgres

declare -a BENCHMARKS=("clickbench" "warehouse")

while getopts 'c:m:u:i:v:h' OPTION; do
  case "$OPTION" in
    c)
      CPU="$OPTARG"
      ;;
    m)
      MEMORY="$OPTARG"
      ;;
    u)
      USER="$OPTARG"
      ;;
    v)
      VARIANT="$OPTARG"
      ;;
    i)
      IMAGENAME="$OPTARG"
      ;;
    h)
      echo "run-all-for-tags.sh [-c cpus] [-m memory] [-i imagename] [-u user] tag [...]"
      echo "   -c number of cpus to allocate for docker"
      echo "   -m amount of memory to allocate for docker"
      echo "   -i imagename for docker"
      echo "   -u user to run psql as"
      echo "   -v variant to use: cached, uncompressed, or zstd"
      echo "   -h this help"
      exit 0
      ;;
    ?)
      echo "run-all-for-tags.sh [-c cpus] [-m memory] [-i imagename] [-u user] tag [...]" >&2
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"

cd $DIRNAME

for tag in $@; do
  for benchmark in "${BENCHMARKS[@]}"; do
    echo "Running benchmark $benchmark for tag $tag"
    docker rm $IMAGENAME
    docker build --build-arg CHECKOUT_VERSION=$tag -t $IMAGENAME .
    docker run -d -e POSTGRES_HOST_AUTH_METHOD=trust -v $PWD:/benchmarks -m $MEMORY --cpus=$CPU --shm-size=256m --name=$IMAGENAME $IMAGENAME
    sleep 10
    docker exec -it $IMAGENAME sh -c "/benchmarks/run-benchmark.sh -b $benchmark -v $VARIANT -u $USER -t $tag"
    docker stop $IMAGENAME
    docker rm $IMAGENAME
  done
done
