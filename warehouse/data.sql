\copy customer FROM 'warehouse/data/customer.csv' WITH (FORMAT csv, DELIMITER '|');
\copy lineitem FROM 'warehouse/data/lineitem.csv' WITH (FORMAT csv, DELIMITER '|');
\copy nation FROM 'warehouse/data/nation.csv' WITH (FORMAT csv, DELIMITER '|');
\copy orders FROM 'warehouse/data/orders.csv' WITH (FORMAT csv, DELIMITER '|');
\copy part FROM 'warehouse/data/part.csv' WITH (FORMAT csv, DELIMITER '|');
\copy partsupp FROM 'warehouse/data/partsupp.csv' WITH (FORMAT csv, DELIMITER '|');
\copy region FROM 'warehouse/data/region.csv' WITH (FORMAT csv, DELIMITER '|');
\copy supplier FROM 'warehouse/data/supplier.csv' WITH (FORMAT csv, DELIMITER '|');
ANALYZE;
