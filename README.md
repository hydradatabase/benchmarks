# Benchmarking for Hydra Columnar

A test runner for multiple testing frameworks.

Currently:

- Clickbench
- TPC-H

## Running

`./run.sh test variant`

Tests currently:

- clickbench - Clickbench tests
- tpc-h - TPC-H tests

Existing variants:

- cached - Caching enabled
- zstd - Columnar with zstd
- uncompressed - Columnar with no compression
