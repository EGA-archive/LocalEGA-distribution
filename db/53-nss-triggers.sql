
-- ################################################
-- Rebuild the users cache
-- ################################################

CREATE OR REPLACE FUNCTION fs.trigger_nss_users()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $BODY$
BEGIN
	PERFORM * FROM fs.make_nss_users();
	RETURN NULL; -- result is ignored since this is an AFTER trigger
END;
$BODY$;

CREATE OR REPLACE TRIGGER build_nss_users
AFTER INSERT OR UPDATE OR DELETE
ON public.user_table
FOR EACH ROW
EXECUTE PROCEDURE fs.trigger_nss_users();

ALTER TABLE public.user_table ENABLE REPLICA TRIGGER build_nss_users;

-- ################################################
-- Rebuild the passwords cache (ie shadow)
-- ################################################

CREATE OR REPLACE FUNCTION fs.trigger_nss_passwords()
RETURNS TRIGGER
LANGUAGE plpgsql VOLATILE
AS $BODY$
BEGIN
	PERFORM * FROM fs.make_nss_passwords();
	RETURN NULL; -- result is ignored since this is an AFTER trigger
END;
$BODY$;

CREATE OR REPLACE TRIGGER build_nss_passwords
AFTER INSERT OR UPDATE OR DELETE
ON private.user_password_table
FOR EACH ROW
EXECUTE PROCEDURE fs.trigger_nss_passwords();

ALTER TABLE private.user_password_table ENABLE REPLICA TRIGGER build_nss_passwords;

-- ################################################
-- Rebuild the groups cache
-- ################################################

CREATE OR REPLACE FUNCTION fs.trigger_nss_groups()
RETURNS TRIGGER
LANGUAGE plpgsql VOLATILE
AS $BODY$
BEGIN
	PERFORM * FROM fs.make_nss_groups();
	RETURN NULL; -- result is ignored since this is an AFTER trigger
END;
$BODY$;

CREATE OR REPLACE TRIGGER build_nss_groups
AFTER INSERT OR UPDATE OR DELETE
ON public.group_table
FOR EACH ROW
EXECUTE PROCEDURE fs.trigger_nss_groups();

ALTER TABLE public.group_table ENABLE REPLICA TRIGGER build_nss_groups;


CREATE OR REPLACE TRIGGER build_nss_users_groups
AFTER INSERT OR UPDATE OR DELETE
ON public.user_group_table
FOR EACH ROW
EXECUTE PROCEDURE fs.trigger_nss_groups();

ALTER TABLE public.user_group_table ENABLE REPLICA TRIGGER build_nss_users_groups;


-- ################################################
-- Rebuild the keys cache
-- ################################################

CREATE OR REPLACE FUNCTION fs.trigger_authorized_keys()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $BODY$
DECLARE
	_user_id bigint;
BEGIN

	IF TG_OP='DELETE' THEN
		_user_id= OLD.user_id;
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

CREATE OR REPLACE TRIGGER build_authorized_keys
AFTER INSERT OR UPDATE OR DELETE
ON public.user_key_table
FOR EACH ROW
EXECUTE PROCEDURE fs.trigger_authorized_keys();

CREATE OR REPLACE TRIGGER build_users_from_authorized_keys
AFTER INSERT OR UPDATE OR DELETE
ON public.user_key_table
FOR EACH ROW
EXECUTE PROCEDURE fs.trigger_nss_users();

CREATE OR REPLACE TRIGGER build_groups_from_authorized_keys
AFTER INSERT OR UPDATE OR DELETE
ON public.user_key_table
FOR EACH ROW
EXECUTE PROCEDURE fs.trigger_nss_groups();


ALTER TABLE public.user_key_table ENABLE REPLICA TRIGGER build_authorized_keys;
ALTER TABLE public.user_key_table ENABLE REPLICA TRIGGER build_users_from_authorized_keys;
ALTER TABLE public.user_key_table ENABLE REPLICA TRIGGER build_groups_from_authorized_keys;
