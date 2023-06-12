# Benchmarking for Hydra Columnar

A test runner for multiple testing frameworks.

Currently:

- Clickbench
- TPC-H

## Running

`./run.sh -b tpc-h -b zstd -u postgres`

Tests currently:

- clickbench - Clickbench tests
- tpc-h - TPC-H tests

Existing variants:

- cached - Caching enabled
- zstd - Columnar with zstd
- uncompressed - Columnar with no compression

## Running with Docker

```sh
docker build . --progress=plain --build-arg CHECKOUT_VERSION=main -t bm
docker run -e POSTGRES_HOST_AUTH_METHOD=trust -v .:/benchmarks --name bm  bm
```
