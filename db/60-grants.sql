-- ###################################################
-- Grant permissions to the outgestion user
-- ###################################################

GRANT USAGE ON SCHEMA public TO outgestion;
GRANT SELECT ON public.dataset_table to outgestion;
GRANT SELECT ON public.dataset_file_table TO outgestion;
GRANT SELECT ON public.file_table TO outgestion;
GRANT SELECT ON public.user_table to outgestion;
GRANT SELECT ON public.user_key_table to outgestion;
GRANT SELECT ON public.header_keys to outgestion;

GRANT USAGE ON SCHEMA private TO outgestion;
GRANT SELECT ON private.file_table TO outgestion;
GRANT SELECT ON private.username_file_header to outgestion;
GRANT SELECT ON private.dataset_permission_table to outgestion;

GRANT USAGE ON SCHEMA fs TO outgestion;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA fs TO outgestion;
