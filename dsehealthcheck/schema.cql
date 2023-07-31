CREATE KEYSPACE IF NOT EXISTS healthcheck WITH replication = {'class': 'SimpleStrategy', 'replication_factor':1};

CREATE TABLE IF NOT EXISTS healthcheck.search_table_a (
   col1_a text,
   col2_a text,
   col3_a text,
   col4_a text,
   PRIMARY KEY (col1_a));

CREATE TABLE IF NOT EXISTS healthcheck.search_table_b (
   col1_b text,
   col2_b text,
   col3_b text,
   col4_b text,
   PRIMARY KEY (col1_b));

insert into healthcheck.search_table_a (col1_a, col2_a, col3_a, col4_a) values ('val1', 'val2', 'val3', 'val4');
insert into healthcheck.search_table_b (col1_b, col2_b, col3_b, col4_b) values ('val1', 'val2', 'val3', 'val4');

CREATE SEARCH INDEX IF NOT EXISTS ON healthcheck.search_table_a WITH COLUMNS col3_a;
