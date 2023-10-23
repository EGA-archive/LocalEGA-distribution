

-- ################################################
-- Rebuild the users cache
-- ################################################
CREATE OR REPLACE FUNCTION fs.make_nss_users()
RETURNS void
LANGUAGE plpgsql
AS $BODY$
DECLARE
	_query text;
BEGIN
	RAISE NOTICE 'Updating users in %', current_setting('nss.users');
	_query := format('
	COPY (SELECT username,
	     	     ''x'', -- no password
	             uid,
		     gid,
		     gecos,
		     homedir,
		     shell
	       FROM public.requesters
        )
	TO ''%s''
	WITH DELIMITER '':''
	     NULL '''';', current_setting('nss.users'));
	EXECUTE _query;
        
END;
$BODY$;

CREATE OR REPLACE FUNCTION fs.trigger_nss_users()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $BODY$
BEGIN
	PERFORM * FROM fs.make_nss_users();
	RETURN NULL; -- result is ignored since this is an AFTER trigger
END;
$BODY$;


-- ################################################
-- Rebuild the passwords cache (ie shadow)
-- ################################################
CREATE OR REPLACE FUNCTION fs.make_nss_passwords()
RETURNS void
LANGUAGE plpgsql VOLATILE
AS $BODY$
DECLARE
	_query text;
BEGIN
	RAISE NOTICE 'Updating passwords in %', current_setting('nss.passwords');
	_query := format('
	COPY (SELECT DISTINCT
	             u.username,
  		     COALESCE(upt.password_hash, ''*''),
		     ''0'',''0'',''99999'',''7'', '''', '''', ''''
	      FROM public.requesters u
	      LEFT JOIN private.user_password_table upt ON upt.user_id = u.db_uid AND upt.is_enabled
	)
	TO ''%s''
	WITH DELIMITER '':''
	     NULL '''';', current_setting('nss.passwords'));
        EXECUTE _query;
END;
$BODY$;

CREATE OR REPLACE FUNCTION fs.trigger_nss_passwords()
RETURNS TRIGGER
LANGUAGE plpgsql VOLATILE
AS $BODY$
BEGIN
	PERFORM * FROM fs.make_nss_passwords();
	RETURN NULL; -- result is ignored since this is an AFTER trigger
END;
$BODY$;

-- ################################################
-- Rebuild the groups cache
-- ################################################
CREATE VIEW public.groups AS
SELECT name  AS groupname,
       id    AS gid
FROM public.group_table
WHERE is_enabled = true;

CREATE OR REPLACE FUNCTION fs.make_nss_groups()
RETURNS void
LANGUAGE plpgsql
AS $BODY$
DECLARE
	_query text;
BEGIN
	RAISE NOTICE 'Updating groups in %', current_setting('nss.groups');
	_query := format('
	COPY (
            WITH mems AS (SELECT r.gid, ugt.group_id, r.username AS username
                          FROM public.requesters r
                          LEFT JOIN public.user_group_table ugt ON r.db_uid = ugt.user_id 
                      )
	SELECT g.groupname,
	       ''x'', -- no password 
	       g.gid, 
               string_agg(DISTINCT mems.username::text, '','') AS members
	FROM public.groups g
	LEFT JOIN mems ON mems.gid=g.gid OR mems.group_id=g.gid
	GROUP BY g.groupname, g.gid
	)
	TO ''%s''
	DELIMITER '':'' NULL '''';', current_setting('nss.groups'));
	EXECUTE _query;
END;
$BODY$;



CREATE OR REPLACE FUNCTION fs.trigger_nss_groups()
RETURNS TRIGGER
LANGUAGE plpgsql VOLATILE
AS $BODY$
BEGIN
	PERFORM * FROM fs.make_nss_groups();
	RETURN NULL; -- result is ignored since this is an AFTER trigger
END;
$BODY$;



-- ################################################
-- Rebuild the keys cache
-- ################################################

CREATE OR REPLACE FUNCTION fs.make_authorized_keys(_user_id bigint)
RETURNS void
LANGUAGE plpgsql
AS $BODY$
DECLARE
	_username text := NULL;
	_query text;
	_uid bigint;
	_dir text;
BEGIN
	-- SELECT username, posix_id INTO _username, _posix_uid
	-- FROM public.user_table
	-- WHERE id=_user_id;
	SELECT username, uid INTO _username, _uid
	FROM public.requesters
	WHERE db_uid=_user_id;

	IF _username IS NULL THEN
	   RAISE EXCEPTION 'User % not found', _user_id;
	END IF;

	_dir := rtrim(current_setting('nss.authorized_keys'), '/');

	IF EXISTS (SELECT 1 FROM public.ssh_keys WHERE uid = _user_id) THEN
	   _query := format('COPY (SELECT key FROM public.ssh_keys WHERE uid = %s)
	                     TO ''%s/%s'';', _user_id, _dir, _uid::text);
	   RAISE NOTICE 'Updating keys for %/% (%)', _dir, _uid, _username;
	   EXECUTE _query;
	END IF;
END;
$BODY$;


CREATE OR REPLACE FUNCTION fs.trigger_authorized_keys()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $BODY$
DECLARE
	_user_id bigint;
BEGIN

	IF TG_OP='DELETE' THEN
		_user_id= OLD.user_id; -- should remove the file, no?
	ELSE -- if insert or update
		_user_id = NEW.user_id;
	END IF;

	PERFORM * FROM fs.make_authorized_keys(_user_id);

	IF TG_OP='DELETE' THEN
		RETURN OLD; -- https://www.postgresql.org/docs/14/plpgsql-trigger.html
		            -- See: 'The usual idiom in DELETE triggers is to return OLD'
	ELSE
		RETURN NEW;
	END IF;
END;
$BODY$;

