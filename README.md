# postgres_data_modeling1
Execute in PostgreSQL
sudo -iu postgres

psql -d postgres


First ensure the database exists:
SELECT datname FROM pg_database WHERE datname = 'sales';


If it doesn't exist:
CREATE DATABASE sales;


Save the script at:
/opt/sales_production_access.sql


Execute:
psql -X \
-v ON_ERROR_STOP=1 \
-d postgres \
-f /opt/sales_production_access.sql


Set passwords for all employee accounts securely:
\password shubham_dba
\password karan_dba
\password rahul_backend
\password amit_backend
\password neha_frontend
\password priya_frontend
\password akash_devops
\password rohit_devops
\password sneha_l1
\password vikram_l1
\password ankit_l2
\password pooja_l2
\password raj_bi
\password anjali_bi


Use unique passwords for each account.
5. Test access like a production DBA
Account	Expected permission
shubham_dba	Full object access
rahul_backend	Read/write
neha_frontend	Read/write
akash_devops	Read-only
sneha_l1	Read-only
ankit_l2	Read-only
raj_bi	Read-only

Example:
psql -h localhost -U rahul_backend -d sales -W


SELECT current_user;

CREATE TABLE sales_app.orders (
    order_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_name VARCHAR(100),
    amount NUMERIC(12,2)
);


The CREATE TABLE operation should fail because the developer has no schema CREATE permission.

Important production detail: Existing-table permissions and future-table permissions are different. The script configures future privileges for objects created by sales_owner. Your DBA should create production tables as sales_owner or through a controlled migration process. The DBA role also needs explicit ownership/role-membership arrangements for any DDL operations it must perform.
6. How a DBA handles new team members
Suppose a new developer, sachin_backend, joins the backend team.

You don't need to create another permission structure.
CREATE ROLE sachin_backend
LOGIN
NOSUPERUSER
NOCREATEDB
NOCREATEROLE
NOINHERIT
CONNECTION LIMIT 5;

GRANT sales_developer TO sachin_backend;

ALTER ROLE sachin_backend IN DATABASE sales
SET search_path = sales_app, public;


Set the password:
\password sachin_backend


Now Sachin inherits the developer team's database permissions.

For employee exit, first revoke their team membership and disable login:
REVOKE sales_developer FROM sachin_backend;

ALTER ROLE sachin_backend NOLOGIN;


Terminate remaining sessions only after approval:
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE usename = 'sachin_backend'
  AND pid <> pg_backend_pid();
