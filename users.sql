
-- =====================================================
-- COMPANY       : SALES APPLICATION
-- DATABASE      : sales
-- ENVIRONMENT   : PRODUCTION
-- PURPOSE       : USER / TEAM / ROLE PROVISIONING
-- =====================================================

\set ON_ERROR_STOP on

-- =====================================================
-- STEP 1: CREATE GROUP ROLES
-- Run as PostgreSQL administrator
-- =====================================================

DO $$
DECLARE
    r TEXT;
BEGIN
    FOREACH r IN ARRAY ARRAY[
        'sales_owner',
        'sales_dba',
        'sales_developer',
        'sales_devops',
        'sales_support',
        'sales_readonly'
    ]
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_roles WHERE rolname = r
        ) THEN
            EXECUTE format('CREATE ROLE %I NOLOGIN', r);
        END IF;
    END LOOP;
END $$;

-- =====================================================
-- STEP 2: CREATE EMPLOYEE LOGIN ACCOUNTS
-- =====================================================

DO $$
DECLARE
    u TEXT;
BEGIN
    FOREACH u IN ARRAY ARRAY[
        'shubham_dba',
        'karan_dba',
        'rahul_backend',
        'amit_backend',
        'neha_frontend',
        'priya_frontend',
        'akash_devops',
        'rohit_devops',
        'sneha_l1',
        'vikram_l1',
        'ankit_l2',
        'pooja_l2',
        'raj_bi',
        'anjali_bi'
    ]
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_roles WHERE rolname = u
        ) THEN
            EXECUTE format(
                'CREATE ROLE %I LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT CONNECTION LIMIT 5',
                u
            );
        END IF;
    END LOOP;
END $$;

-- =====================================================
-- STEP 3: ASSIGN EMPLOYEES TO GROUP ROLES
-- =====================================================

GRANT sales_dba TO shubham_dba, karan_dba;

GRANT sales_developer TO
rahul_backend, amit_backend,
neha_frontend, priya_frontend;

GRANT sales_devops TO
akash_devops, rohit_devops;

GRANT sales_support TO
sneha_l1, vikram_l1,
ankit_l2, pooja_l2;

GRANT sales_readonly TO
raj_bi, anjali_bi;

-- =====================================================
-- STEP 4: CONNECT TO SALES DATABASE
-- =====================================================

\connect sales

-- =====================================================
-- STEP 5: DATABASE PERMISSIONS
-- =====================================================

REVOKE ALL ON DATABASE sales FROM PUBLIC;

GRANT CONNECT ON DATABASE sales TO
sales_owner,
sales_dba,
sales_developer,
sales_devops,
sales_support,
sales_readonly;

-- =====================================================
-- STEP 6: CREATE APPLICATION SCHEMA
-- =====================================================

CREATE SCHEMA IF NOT EXISTS sales_app
AUTHORIZATION sales_owner;

REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- =====================================================
-- STEP 7: SCHEMA PERMISSIONS
-- =====================================================

GRANT USAGE ON SCHEMA sales_app TO
sales_dba,
sales_developer,
sales_devops,
sales_support,
sales_readonly;

GRANT CREATE ON SCHEMA sales_app TO
sales_dba;

-- =====================================================
-- STEP 8: TABLE PERMISSIONS
-- =====================================================

-- DBA full object access
GRANT ALL PRIVILEGES
ON ALL TABLES IN SCHEMA sales_app
TO sales_dba;

-- Development read/write
GRANT SELECT, INSERT, UPDATE, DELETE
ON ALL TABLES IN SCHEMA sales_app
TO sales_developer;

-- DevOps monitoring access
GRANT SELECT
ON ALL TABLES IN SCHEMA sales_app
TO sales_devops;

-- Support read-only
GRANT SELECT
ON ALL TABLES IN SCHEMA sales_app
TO sales_support;

-- Reporting read-only
GRANT SELECT
ON ALL TABLES IN SCHEMA sales_app
TO sales_readonly;

-- =====================================================
-- STEP 9: SEQUENCE PERMISSIONS
-- =====================================================

GRANT ALL PRIVILEGES
ON ALL SEQUENCES IN SCHEMA sales_app
TO sales_dba;

GRANT USAGE, SELECT
ON ALL SEQUENCES IN SCHEMA sales_app
TO sales_developer;

-- =====================================================
-- STEP 10: FUTURE TABLE PERMISSIONS
-- Applies to objects created by sales_owner
-- =====================================================

ALTER DEFAULT PRIVILEGES FOR ROLE sales_owner
IN SCHEMA sales_app
GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLES TO sales_developer;

ALTER DEFAULT PRIVILEGES FOR ROLE sales_owner
IN SCHEMA sales_app
GRANT SELECT ON TABLES
TO sales_devops, sales_support, sales_readonly;

ALTER DEFAULT PRIVILEGES FOR ROLE sales_owner
IN SCHEMA sales_app
GRANT ALL PRIVILEGES ON TABLES
TO sales_dba;

ALTER DEFAULT PRIVILEGES FOR ROLE sales_owner
IN SCHEMA sales_app
GRANT USAGE, SELECT ON SEQUENCES
TO sales_developer;

ALTER DEFAULT PRIVILEGES FOR ROLE sales_owner
IN SCHEMA sales_app
GRANT ALL PRIVILEGES ON SEQUENCES
TO sales_dba;

-- =====================================================
-- STEP 11: DEFAULT SEARCH PATH
-- =====================================================

ALTER ROLE shubham_dba IN DATABASE sales
SET search_path = sales_app, public;

ALTER ROLE karan_dba IN DATABASE sales
SET search_path = sales_app, public;

ALTER ROLE rahul_backend IN DATABASE sales
SET search_path = sales_app, public;

ALTER ROLE amit_backend IN DATABASE sales
SET search_path = sales_app, public;

ALTER ROLE neha_frontend IN DATABASE sales
SET search_path = sales_app, public;

ALTER ROLE priya_frontend IN DATABASE sales
SET search_path = sales_app, public;

ALTER ROLE akash_devops IN DATABASE sales
SET search_path = sales_app, public;

ALTER ROLE rohit_devops IN DATABASE sales
SET search_path = sales_app, public;

ALTER ROLE sneha_l1 IN DATABASE sales
SET search_path = sales_app, public;

ALTER ROLE vikram_l1 IN DATABASE sales
SET search_path = sales_app, public;

ALTER ROLE ankit_l2 IN DATABASE sales
SET search_path = sales_app, public;

ALTER ROLE pooja_l2 IN DATABASE sales
SET search_path = sales_app, public;

ALTER ROLE raj_bi IN DATABASE sales
SET search_path = sales_app, public;

ALTER ROLE anjali_bi IN DATABASE sales
SET search_path = sales_app, public;

-- =====================================================
-- STEP 12: VALIDATION
-- =====================================================

-- All employee accounts
SELECT rolname, rolcanlogin, rolsuper, rolconnlimit
FROM pg_roles
WHERE rolname IN (
    'shubham_dba','karan_dba',
    'rahul_backend','amit_backend',
    'neha_frontend','priya_frontend',
    'akash_devops','rohit_devops',
    'sneha_l1','vikram_l1',
    'ankit_l2','pooja_l2',
    'raj_bi','anjali_bi'
)
ORDER BY rolname;

-- Employee and group role mapping
SELECT
    member_role.rolname AS employee,
    group_role.rolname AS assigned_group
FROM pg_auth_members m
JOIN pg_roles group_role ON group_role.oid = m.roleid
JOIN pg_roles member_role ON member_role.oid = m.member
WHERE group_role.rolname LIKE 'sales_%'
ORDER BY assigned_group, employee;

-- Schema permissions
SELECT
    grantee,
    privilege_type
FROM information_schema.schema_privileges
WHERE schema_name = 'sales_app'
ORDER BY grantee, privilege_type;

-- =====================================================
-- END OF SCRIPT
-- =====================================================
