SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;
SET default_tablespace = '';


-- Foreign Data Wrapper
CREATE EXTENSION IF NOT EXISTS postgres_fdw WITH SCHEMA public;
COMMENT ON EXTENSION postgres_fdw IS 'foreign-data wrapper for remote PostgreSQL servers';


CREATE USER outgestion WITH LOGIN ENCRYPTED PASSWORD 'change-me';





CREATE FUNCTION public.sys2db_user_id(_sys_uid bigint)
RETURNS bigint
LANGUAGE SQL
AS $_$
   SELECT _sys_uid - 10000;
$_$;

CREATE FUNCTION public.db2sys_user_id(_db_uid bigint)
RETURNS bigint
LANGUAGE SQL
AS $_$
   SELECT _db_uid + 10000;
$_$;
