# Benchmarking for Hydra Columnar

A test runner for multiple testing frameworks.

Tests currently:

- clickbench - Clickbench tests
- warehouse - TPC-H like warehouse tests

Existing variants:

- cached - Caching enabled
- zstd - Columnar with zstd
- uncompressed - Columnar with no compression

## Running Against Multiple Tags/Commits

The cleanest option for running against multiple tags or commits is to use
`run-all-for-tags.sh` which will set up a Docker container and run the tests
automatically for all tags listed in the arguments.

This will build a Hydra Columnar container, run `zstd` and `warehouse`, create
an analysis file for each, and clean up when complete. Note that this only
runs for a single variant, but does all benchmarks for each tag:

```sh
./run-all-for-tags.sh -c 4 -m 8000m -u postgres -v zstd main e973247
```

### Command Line Options

There are a few options that can be set depending on environment:

| Option | Description                                                           | Default           |
| ------ | --------------------------------------------------------------------- | ----------------- |
| `-c`   | Number of CPUs to allocate for Docker                                 | `4`               |
| `-m`   | Amount of memory to allocate for Docker (in units Docker understands) | `8000m`           |
| `-u`   | User to execute `psql` and related as                                 | `postgres`        |
| `-v`   | Variant to run (`zstd`, `cached`, `uncompressed`)                     | `zstd`            |
| `-i`   | Image name for Docker                                                 | `hydra-benchmark` |

## Running Locally

In addition, you can use the test runner to run locally, as long as you have
a local Postgres server running.

```sh
./run-benchmark.sh -b warehouse -v zstd -u postgres
```

There are options available for running the benchmarks directly:

| Option | Description                                       | Default      |
| ------ | ------------------------------------------------- | ------------ |
| `-u`   | User to execute `psql` and related as             | `postgres`   |
| `-v`   | Variant to run (`zstd`, `cached`, `uncompressed`) | `zstd`       |
| `-b`   | Benchmark to run (`clickbench`, `warehouse`)      | `clickbench` |
| `-t`   | Optional tag for output                           | none         |
| `-n`   | Disables loading and deleting of data             | off          |

## Output

Output is contained in `results` and provides both the raw output of the
queries, as well as the distilled analysis as a `JSON` file.

Example:

```
{
  "1": 3380.205,
  "2": 1360.2433333333333,
  "3": 7114.064333333333,
  "4": 4684.049,
  "5": 37294.54833333333,
  "6": 108155.71833333332,
  "7": 4568.693,
  "8": 1487.924,
  "9": 70272.64433333334,
  "10": 69788.21733333333,
  "11": 6776.053,
  "12": 7436.084333333333,
  "13": 14073.636666666667,
  "14": 63197.85966666666,
  "15": 31899.24,
  "16": 27652.075,
  "17": 33861.602333333336,
  "18": 18979.334666666666,
  "19": 64205.616,
  "20": 1164.5026666666665,
  "21": 13006.078,
  "22": 14150.306666666665,
  "23": 18111.629666666664,
  "24": 77786.32933333334,
  "25": 5333.8606666666665,
  "26": 4264.0216666666665,
  "27": 5610.453333333334,
  "28": 22776.928,
  "29": 426145.38066666666,
  "30": 35977.91066666666,
  "31": 13859.798666666667,
  "32": 18122.944,
  "33": 87419.71933333333,
  "34": 240912.29166666666,
  "35": 249790.05899999998,
  "36": 31738.910999999996,
  "37": 5908.362,
  "38": 7451.537,
  "39": 5263.214,
  "40": 12530.239333333331,
  "41": 5300.29,
  "42": 4922.1140000000005,
  "43": 4120.791333333334,
  "data": 1543743.404,
  "setup": 17.099
}
```

## Prerequisites

There are some prerequisites that need to be installed if you run via Docker:

- docker

If you are running locally, in addition to Postgres itself:

- nodejs

The nodejs requirement is for analysis (see `analyze.js`).
