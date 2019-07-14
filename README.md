# postgres-auditing
Simple example of triggers and functions to create table auditing without having to get specific on columns and tables.

#### A series of psql statements that:
  * Create tables of a sample table and audit
  * Trigger procedure to audit the sample
  * A set of functions to query the audit table by feeding in a column name and table name
  * A sample query that takes the results of a query to information_schema.columns table (so you don't need to know the column name to query).
  * Sample data is included as well

#### Example query:
```
select table_name, column_name, retrievecolumndifferences(column_name, table_name)
from information_schema.columns where table_schema = 'public';
```

#### The differences are presented in json format.

```
table_name|column_name|retrievecolumndifferences                                                  |
----------|-----------|---------------------------------------------------------------------------|
test_table|lname      |{"operation":"UPDATE","id_in_table":5,"oldval":"campbell","newval":"brown"}|
```

I broke what I was trying to do into 3 goals:
* GOAL 1: Create a trigger that audits a table.
* GOAL 2: Create a function that will return the differences and the columns in which they occur.
* GOAL 3: Create a function that will iterate through all columns of a table and return the differences for the columns.

Next steps:
* Add time parameters
* Filter by operation
* Other options
