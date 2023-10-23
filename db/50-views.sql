
CREATE VIEW public.groups AS
SELECT name  AS groupname,
       id    AS gid
FROM public.group_table
WHERE is_enabled = true;

--
-- We return SSH keys only if at least one crypt4gh key exists for the given user
--
CREATE VIEW public.ssh_keys AS
SELECT --DISTINCT 
	ut.id 	AS uid,
       ut.username  AS username,
       uk.key       AS key
FROM public.user_key_table uk
INNER JOIN public.user_table ut ON ut.id = uk.user_id
WHERE (-- uk.is_enabled = true
       -- AND
       uk.key IS NOT NULL
       AND
       uk.type IN ('ssh'::public.key_type, 'ssh-ed25519'::public.key_type)
      );


CREATE VIEW public.header_keys AS
SELECT --DISTINCT 
       ut.id        AS user_id,
       ut.username  AS username,
       uk.key       AS key
FROM public.user_key_table uk
INNER JOIN public.user_table ut ON ut.id = uk.user_id
WHERE (-- uk.is_enabled = true
       -- AND
       uk.key IS NOT NULL
       AND
       uk.type IN ('c4gh-v1'::public.key_type, 'ssh-ed25519'::public.key_type)
       AND CASE
                WHEN uk.expires_at IS NULL THEN TRUE -- doesn't expire
                ELSE now()::date < uk.expires_at -- just comparing the day
 	   END
      );


--
-- We use the ID (and not the username) for the home directory, in case the username changes
-- We hard-code the group as requesters: 10000
-- We don't show the passwords
--
CREATE VIEW public.requesters AS
SELECT DISTINCT
       db2sys_user_id(ut.posix_id)               AS uid,
       ut.id                                     AS db_uid,
       10000                                     AS gid,
       ut.username                               AS username,
       --(concat('/home/', ut.id))::varchar        AS homedir,
       (concat('/home/', ut.username))::varchar  AS homedir,
       'EGA Requester'::varchar                  AS gecos,
       '/bin/bash'::varchar                      AS shell
FROM public.user_table ut
INNER JOIN public.user_key_table uk ON ut.id = uk.user_id
WHERE ( ut.is_enabled = true
        AND
	uk.key IS NOT NULL
	AND
        uk.type IN ('c4gh-v1'::public.key_type, 'ssh-ed25519'::public.key_type)
      );

-- Only accessible from the nssshadow user
-- and only called by the ega-nss library using /etc/ega/nss-shadow.conf (owned by root _only_).
CREATE OR REPLACE VIEW private.passwords AS
SELECT DISTINCT
        u.username              AS username,
	u.db_uid                AS uid,
        upt.password_hash       AS pwdh,
	0::int8                 AS lstchg,
	0::int8             	AS sp_min,
	99999::int8             AS sp_max,  -- or  0 ?
	7::int8              	AS sp_warn, -- or -1 ?
	(-1)::int8 		AS sp_inact,
	(-1)::int8 		AS sp_expire
FROM public.requesters u
--INNER JOIN private.user_password_table upt ON upt.user_id = u.uid AND upt.is_enabled
LEFT JOIN private.user_password_table upt ON upt.user_id = u.db_uid AND upt.is_enabled
;
