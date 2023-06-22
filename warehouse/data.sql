\copy customer FROM 'tpc-h/data/customer.csv' WITH (FORMAT csv, DELIMITER '|');

\copy lineitem FROM 'tpc-h/data/lineitem.csv' WITH (FORMAT csv, DELIMITER '|');

\copy nation FROM 'tpc-h/data/nation.csv' WITH (FORMAT csv, DELIMITER '|');

\copy orders FROM 'tpc-h/data/orders.csv' WITH (FORMAT csv, DELIMITER '|');

\copy part FROM 'tpc-h/data/part.csv' WITH (FORMAT csv, DELIMITER '|');

\copy partsupp FROM 'tpc-h/data/partsupp.csv' WITH (FORMAT csv, DELIMITER '|');

\copy region FROM 'tpc-h/data/region.csv' WITH (FORMAT csv, DELIMITER '|');

\copy supplier FROM 'tpc-h/data/supplier.csv' WITH (FORMAT csv, DELIMITER '|');

ANALYZE;
