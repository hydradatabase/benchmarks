CREATE EXTENSION IF NOT EXISTS columnar;
SET columnar.compression = 'none';
SET default_table_access_method = 'columnar';

\timing on