#!/bin/bash

# this is designed for the GH Action, but can be run locally. it assumes you
# are logged into AWS and Docker as needed (for S3 download/upload or ECR
# access), and have `aws` and `docker` in your path and Docker is running.

set -eux

# inputs
: "${BENCHMARK:=warehouse-1G}"
: "${REPO:=ghcr.io/hydradatabase/hydra}"
: "${TAG:=latest}"
: "${VARIANT:=zstd}"

# settings
: "${CONTAINER_NAME:=hydra-benchmark}"
: "${RUNTIME:=now}"
: "${BASE_IMAGE:=$( [[ $REPO =~ "ghcr.io" ]] && echo "postgres" || echo "spilo" )}"
: "${BENCHER_PROJECT:=hydra-$BASE_IMAGE}"
: "${BENCHER_TESTBED:=localhost}"
# required to be manually set or passed in if you want to use bencher
# BENCHER_API_TOKEN=

# features
: "${DOWNLOAD_DATA:=true}"
: "${UPLOAD_RESULTS_TO_S3:=true}"
: "${UPLOAD_RESULTS_TO_BENCHER:=true}"
: "${CLEANUP_FILES:=false}"
: "${USE_BENCHER_BACKDATE:=false}"

# internal settings
BENCHER_ADAPTER=json
if [ "$(uname -s)" = Darwin ]; then
  # need gnu date for consistency; 'brew install date'
  DATE=gdate
else
  DATE=date
fi


setup_data_dir() {
  if [ ! -e "$BENCHMARK" ]; then
    benchmark_src="$(echo $BENCHMARK | cut -f 1 -d -)"
    if [ "$BENCHMARK" != "$benchmark_src" ]; then
      ln -s $benchmark_src $BENCHMARK
    fi
  fi
  mkdir -p $BENCHMARK/data
}

prepare_data() {
  pushd $BENCHMARK/data
  for f in *.gz; do
    target="$(basename $f .gz)"
    if [ ! -e $target ]; then
      mkfifo $target
    fi
    if [ -p $target ]; then
      gzip -d -c $f >$target &
    fi
  done
  popd
}

download_data() {
  aws s3 cp --no-progress --recursive s3://hydra-benchmarks/data/$BENCHMARK ./$BENCHMARK/data
}

upload_result_to_s3() {
  aws s3 cp --no-progress ./results.json s3://hydra-benchmarks/results/$BASE_IMAGE-$BENCHMARK-$VARIANT-$TAG.json
  aws s3 cp --no-progress ./bencher-with-metadata.json s3://hydra-benchmarks/bencher-results/$BASE_IMAGE-$BENCHMARK-$VARIANT-$TAG.json
}

upload_result_to_bencher() {
  set +u
  if [ $USE_BENCHER_BACKDATE = true ]; then
    bencher run \
      --if-branch "$GITHUB_REF_NAME" \
      --else-if-branch "$GITHUB_BASE_REF" \
      --else-if-branch main \
      --backdate $(cat unix-timestamp.txt)000 \
      --project "$BENCHER_PROJECT" \
      --adapter "$BENCHER_ADAPTER" \
      "cat ./analyze-bencher.json"
  else
    bencher run \
      --if-branch "$GITHUB_REF_NAME" \
      --else-if-branch "$GITHUB_BASE_REF" \
      --else-if-branch main \
      --project "$BENCHER_PROJECT" \
      --adapter "$BENCHER_ADAPTER" \
      "cat ./analyze-bencher.json"
  fi
  set -u
}

run_benchmark() {
  docker run -d -e POSTGRES_HOST_AUTH_METHOD=trust -v $PWD:/benchmarks -m 12288m --cpus=4 --shm-size=1024m --name=$CONTAINER_NAME $REPO:$TAG
  trap "stop_docker; exit 1" SIGINT ERR
  sleep 15
  docker exec $CONTAINER_NAME /bin/sh -c "RUNTIME=$RUNTIME /benchmarks/run-benchmark.sh -z -b $BENCHMARK -v $VARIANT -u postgres"
  stop_docker
  trap - SIGINT ERR
}

stop_docker() {
  docker stop $CONTAINER_NAME
  docker rm $CONTAINER_NAME
}

analyze_results() {
  docker inspect $REPO:$TAG | jq ".[0] | { metadata: { timestamp: .Created, repo: \"$REPO\", tag: \"$TAG\", benchmark: \"$BENCHMARK\", testbed: \"$BENCHER_TESTBED\" } }" >./metadata.json
  $DATE -d $(jq -r .metadata.timestamp ./metadata.json) +%s >./unix-timestamp.txt
  ./analyze.js ./results/$BENCHMARK/$VARIANT/$RUNTIME > ./analyze.json
  ./analyze-bencher.js ./results/$BENCHMARK/$VARIANT/$RUNTIME $BENCHMARK >./analyze-bencher.json
  jq -s '.[0] * .[1]' ./analyze.json ./metadata.json >./results.json
  jq -s '.[0] * .[1]' ./analyze-bencher.json ./metadata.json >./bencher-with-metadata.json
}

cleanup_files() {
  rm -f analyze.json analyze-bencher.json results.json bencher-with-metadata.json unix-timestamp.txt metadata.json

  # cleanup pipes
  for f in $BENCHMARK/data/*; do
    if [ -p $f ]; then
      rm $f
    fi
  done
  # cleanup symlink
  if [ -L $BENCHMARK ]; then
    rm $BENCHMARK
  fi
}

run() {
  setup_data_dir
  [ $DOWNLOAD_DATA = true ] && download_data || true
  prepare_data
  run_benchmark
  analyze_results
  [ $UPLOAD_RESULTS_TO_S3 = true ] && upload_result_to_s3 || true
  [ $UPLOAD_RESULTS_TO_BENCHER = true ] && upload_result_to_bencher || true
  [ $CLEANUP_FILES = true ] && cleanup_files || true
}

${1:-run}
