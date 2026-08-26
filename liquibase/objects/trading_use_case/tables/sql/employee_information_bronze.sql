-- The database name is supplied by Liquibase at deployment time.
create table ${database_name}.trading_use_case.employee_information_bronze (
    day_id number(38,0),
    emp_id number(38,0),
    emp_email varchar(16777216),
    emp_name varchar(16777216),
    emp_salary number(38,0),
    dept_id number(38,0),
    dept_name varchar(16777216),
    dept_code varchar(16777216),
    creation_dt timestamp_ltz(9) default current_timestamp()
);
