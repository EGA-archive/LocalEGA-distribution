-- ###################################################
-- Grant permissions to the outgestion user
-- ###################################################

GRANT USAGE ON SCHEMA public TO distribution;
GRANT SELECT ON public.dataset_table to distribution;
GRANT SELECT ON public.dataset_file_table TO distribution;
GRANT SELECT ON public.file_table TO distribution;
GRANT SELECT ON public.user_table to distribution;
GRANT SELECT ON public.user_key_table to distribution;
GRANT SELECT ON public.header_keys to distribution;

GRANT USAGE ON SCHEMA private TO distribution;
GRANT SELECT ON private.file_table TO distribution;
GRANT SELECT ON private.username_file_header to distribution;
GRANT SELECT ON private.dataset_permission_table to distribution;

GRANT USAGE ON SCHEMA fs TO distribution;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA fs TO distribution;

GRANT USAGE     ON SCHEMA crypt4gh                                      TO distribution;
GRANT EXECUTE   ON FUNCTION crypt4gh.header_reencrypt(bytea,bytea)      TO distribution;
GRANT EXECUTE   ON FUNCTION crypt4gh.header_reencrypt(bytea,bytea[])    TO distribution;

-- #####################################################
-- Grant permissions for the NSS system
-- #####################################################

GRANT USAGE ON SCHEMA fs TO lega;
GRANT EXECUTE ON FUNCTION fs.trigger_nss_users() TO lega;
GRANT EXECUTE ON FUNCTION fs.make_nss_users() TO lega;
GRANT EXECUTE ON FUNCTION fs.trigger_nss_passwords() TO lega;
GRANT EXECUTE ON FUNCTION fs.make_nss_passwords() TO lega;
GRANT EXECUTE ON FUNCTION fs.make_nss_groups() TO lega;
GRANT EXECUTE ON FUNCTION fs.trigger_authorized_keys() TO lega;
GRANT EXECUTE ON FUNCTION fs.make_authorized_keys TO lega;
