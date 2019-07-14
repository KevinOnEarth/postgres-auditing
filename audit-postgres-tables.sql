--GOAL 1: Create a trigger that audits a table.
--GOAL 2: Create a function that will return the differences and the columns in which they occur.
--GOAL 3: Create a function that will iterate through all columns of a table and return the differences for the columns.
--create table for testing
create table test_table(id serial primary key, fname varchar, lname varchar, age int4, state varchar(2));

--create audit table
create table audit_test_table(id serial primary key, table_name varchar, id_in_table int4, operation varchar, oldrecord json, newrecord json);

--GOAL 1: Create a trigger that audits a table.
--create procedure to audit the test table
create or replace function public.audit_table() returns trigger as
$$
	begin

		if (TG_OP = 'INSERT') then
			insert into audit_test_table(table_name, id_in_table, operation, newrecord) values
				(tg_table_name, new.id, tg_op, row_to_json(new));
	    elsif (TG_OP = 'DELETE') then
			insert into audit_test_table(table_name, id_in_table, operation, oldrecord) values
				(tg_table_name, old.id, tg_op, row_to_json(old));
		elsif (TG_OP = 'UPDATE') then
			insert into audit_test_table(table_name, id_in_table, operation, oldrecord, newrecord) values
				(tg_table_name, old.id, tg_op, row_to_json(old), row_to_json(new));
	   	end if;
		return null;
	END
$$ language plpgsql;

-- associate the trigger to the table
create trigger tr_audit_table
after insert or update or delete on test_table
  for each row execute function public.audit_table();

--insert some sample data
insert into test_table(fname, lname, age, state) values ('john','doe',25, 'IA');
insert into test_table(fname, lname, age, state) values ('joe','smith',28, 'CA');
insert into test_table(fname, lname, age, state) values ('jim','jones',27, 'OR');
insert into test_table(fname, lname, age, state) values ('joel','johnson',22, 'OH');
insert into test_table(fname, lname, age, state) values ('jack','campbell',31, 'OH');

-- perform some updates
update test_table set state = 'ID' where lname = 'doe';
update test_table set age = 30 where lname = 'doe';
update test_table set state = 'NV' where lname = 'smith';
update test_table set age = 31 where lname = 'jones';

--perform a delete
delete from test_table where lname = 'jones';

--insert more data
insert into test_table(fname, lname, age, state) values ('joel','johnson',22, 'OH');
insert into test_table(fname, lname, age, state) values ('jack','campbell',31, 'OH');

--check audit table
select * from audit_test_table;

--GOAL 2: Create a function that will return the differences and the columns in which they occur
--  (and the operation performed and id within the table the operation was executed).
-- create a procedure to retrieve a value from the old and new record (if they exist)
--  retrieve inserts and deletes explicitly -they are differences
create or replace function public.retrieveauditvalues(colname varchar, tablename varchar)
	returns table (operation varchar, id_in_table int4, oldval text, newval text) as
$$
	begin
		return query execute 'select operation, id_in_table, oldrecord ->> '
		          || '''' || colname ||''''
		          || ' as "oldval",'
		          || 'newrecord ->> '
		          || '''' || colname ||''''
		          || ' as "newval" '
		          || 'from audit_test_table where table_name = '
	              || '''' || tablename ||''' and (oldrecord ->>'
	              || '''' || colname ||''''
	              || ' <> newrecord ->>'
	              || '''' || colname ||''' or operation in ('
	              || '''INSERT'',''DELETE'')'
	              || ')';
	END
$$ language plpgsql;

--try out the function
select retrieveauditvalues('state', 'test_table');

--GOAL 3: Create a function that will iterate through all columns of a table and return the differences for the columns.
--
create or replace function public.retrievecolumndifferences(columnname varchar, tablename varchar)
	returns table(results json) as
$$
	begin
		return query select to_json(retrieveauditvalues(columnname, tablename));
	end;
$$ language plpgsql;

--try out the function
select retrievecolumndifferences('age','test_table');

--Now add it to a information_schema query to retrieve all differences for all tables.
select table_name, column_name, retrievecolumndifferences(column_name, table_name) from information_schema.columns where table_schema = 'public';

--Next Steps:
--  Add a timeframe option,
--  add all columns of audit table
