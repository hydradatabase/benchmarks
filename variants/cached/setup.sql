CREATE EXTENSION IF NOT EXISTS columnar;
SET columnar.compression = 'zstd';
SET columnar.compression_level = 3;
SET default_table_access_method = 'columnar';

\timing on