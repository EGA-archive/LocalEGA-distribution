-- if depends on 51 for: fs.decrypted_filesize and fs.header_size

CREATE TABLE sqlite_fs.boxes_generated(
	id serial NOT NULL PRIMARY KEY,
	username text NOT NULL,
	user_id int8,
	datasets text[] NOT NULL,
	files text[],
	reset_box bool NOT NULL,
	created_by_db_user text NOT NULL DEFAULT CURRENT_USER,
        created_at timestamptz(6) NOT NULL DEFAULT now(),
	edited_by_db_user text NOT NULL DEFAULT CURRENT_USER,
	edited_at timestamptz(6) NOT NULL DEFAULT now(),
	edited_cnt int4 NOT NULL DEFAULT 0
);

CREATE OR REPLACE FUNCTION sqlite_fs.generate_box_checks(_username text, _datasets text[], _files text  [], _reset_box bool)
  RETURNS void AS $BODY$
  DECLARE
     _user_id int8;
     _error_ids text[];
     _datasets_non_existing text[];
     _missing_permissions text[];
     _has_files bool;
     _files_non_existing text[];
     _num_files_in_petition int8;
     _data_query text;
     _missing_files text[];
  BEGIN
      _has_files:= false;

	IF (_username IS NULL) THEN
	     RAISE EXCEPTION 'Username cannot be null';
	END IF;

	IF (_username ='') THEN
	     RAISE EXCEPTION 'Username cannot be empty';
	END IF;

	IF (REPLACE(_username, ' ', '' ) = '') THEN
       	    RAISE EXCEPTION 'username not valid';
        END IF;

	SELECT id INTO _user_id	FROM public.user_table where username=_username;

	IF (_user_id IS NULL) THEN
		RAISE EXCEPTION 'Could not find user id of user %', _username;
	END IF;

	IF (_datasets IS NULL) THEN
		RAISE EXCEPTION 'datasets are mandatory';
	END IF;
	IF (CARDINALITY(_datasets) = 0) THEN
		RAISE EXCEPTION 'datasets cannot be empty';
	END IF;

	SELECT ARRAY_AGG(sq.id) INTO _error_ids from unnest(_datasets) sq(id)
          WHERE sq.id NOT SIMILAR TO 'EGAD[0-9]{11}';

       IF (CARDINALITY(_error_ids) > 0) THEN
       	 RAISE EXCEPTION 'These are not valid dataset ids %', _error_ids;
       END IF;

       SELECT ARRAY_AGG(sq.id) INTO _error_ids from unnest(_files) sq(id)
         WHERE sq.id NOT SIMILAR TO 'EGAF[0-9]{11}';

       IF (CARDINALITY(_error_ids) > 0) THEN
         RAISE EXCEPTION 'These are not valid file ids %', _error_ids;
       END IF;

	RAISE NOTICE '_username is %', _username;
	RAISE NOTICE '_user_id is %', _user_id;
	RAISE NOTICE '_reset_box value is %', _reset_box;

	IF NOT EXISTS (
		SELECT * FROM public.user_key_table ukt
		WHERE ukt.user_id=_user_id AND ukt.type IN ('ssh-ed25519'::public.key_type, 'c4gh-v1'::public.key_type)
	) THEN
		RAISE EXCEPTION 'This user does not have keys';
	END IF;

	SELECT ARRAY_AGG(sq.id) INTO _datasets_non_existing
	FROM ( SELECT unnest(_datasets) AS id) sq
	LEFT JOIN public.dataset_table dt ON dt.stable_id=sq.id
	WHERE  dt.stable_id IS NULL;

	IF (CARDINALITY(_datasets_non_existing) != 0) THEN
		RAISE EXCEPTION 'These datasets do not exist: %' , _datasets_non_existing;
        END IF;

	--Check that all the datasets requested are on the cega partition
	--Right now this is not possible to fail because we only replicate
	-- cega partition to the vault
	SELECT ARRAY_AGG(sq.id) INTO _datasets_non_existing
	FROM ( SELECT unnest(_datasets) AS id) sq
	LEFT JOIN public.dataset_table dt ON dt.stable_id=sq.id
	WHERE  dt.stable_id IS NULL;

	IF (CARDINALITY(_datasets_non_existing) != 0) THEN
		RAISE EXCEPTION 'These datasets do not belong to cega: %' , _datasets_non_existing;
  END IF;

	--check permissions
	SELECT ARRAY_AGG(sq.id) INTO _missing_permissions
	FROM ( SELECT unnest(_datasets) AS id) sq
	LEFT JOIN private.dataset_permission_table dpt ON dpt.dataset_stable_id=sq.id AND dpt.user_id=_user_id
	WHERE dpt.id IS NULL;

	IF (CARDINALITY(_missing_permissions) != 0) THEN
		RAISE EXCEPTION 'The user does not have permissions for datasets: %' , _missing_permissions;
  END IF;

	--check if they are asking for just some files of the datasets
	IF ( _files IS NOT NULL AND CARDINALITY(_files) > 0 ) THEN
	   	_has_files:= true;

			SELECT ARRAY_AGG(sq.id) INTO _files_non_existing
			FROM ( SELECT unnest(_files) AS id) sq
			LEFT JOIN public.file_table ft ON ft.stable_id=sq.id
			WHERE  ft.stable_id IS NULL;
			IF (CARDINALITY(_missing_files) != 0) THEN
				RAISE EXCEPTION 'These files do not exist at the EGA, (typo?): %' , _missing_files;
			END IF;
	END IF;

	--check if the petition is empty
	_data_query:= '
	WITH sq AS (
	 SELECT unnest($1) AS id
	)
	SELECT COUNT(DISTINCT ft.stable_id)
	FROM sq
	INNER JOIN public.dataset_table dt ON dt.stable_id=sq.id
	INNER JOIN public.dataset_file_table dft ON dft.dataset_stable_id=dt.stable_id
	INNER JOIN public.file_table ft ON ft.stable_id=dft.file_stable_id';

	IF (_has_files = true) THEN
		_data_query:= _data_query || '
	INNER JOIN (
	 SELECT unnest($2) AS id
	) fq ON fq.id=ft.stable_id
	';
	END IF;

	EXECUTE _data_query INTO _num_files_in_petition USING _datasets, _files;

	RAISE NOTICE 'Number of files in the petition is %' , _num_files_in_petition;

	IF (_num_files_in_petition = 0) THEN
		RAISE EXCEPTION 'This petition is empty.';
	END IF;

	IF NOT EXISTS (
		SELECT * FROM public.user_key_table ukt
		WHERE ukt.user_id=_user_id AND ukt.type IN ('ssh-ed25519'::public.key_type, 'c4gh-v1'::public.key_type)
	) THEN
		RAISE EXCEPTION 'This user does not have keys';
	END IF;

END;
 $BODY$
 LANGUAGE plpgsql VOLATILE
 COST 100;


  CREATE OR REPLACE FUNCTION sqlite_fs.generate_box(_username text, _datasets text[], _files text  [], _reset_box bool default false)
  RETURNS text AS $BODY$
	DECLARE
	_user_id int8;
	_error_message text;
BEGIN

	IF (_username IS NULL) THEN
	     RAISE EXCEPTION 'Username cannot be null';
	END IF;
	RAISE NOTICE '_username is %', _username;

	IF (_datasets IS NULL) THEN
		RAISE EXCEPTION 'datasets are mandatory';
	END IF;
	IF (CARDINALITY(_datasets) =0) THEN
		RAISE EXCEPTION 'datasets cannot be empty';
	END IF;

	RAISE NOTICE '_reset_box value is %', _reset_box;

	BEGIN
	    PERFORM * FROM sqlite_fs.generate_box_checks(_username, _datasets, _files, _reset_box);
	EXCEPTION
	    WHEN raise_exception THEN
	        GET STACKED DIAGNOSTICS _error_message = message_text;
	    RETURN _error_message;
        END;

        SELECT id INTO _user_id	FROM public.user_table where username=_username;

	IF (_user_id IS NULL) THEN
		RAISE EXCEPTION 'Could not find user id of user %', _username;
	END IF;
	RAISE NOTICE '_user_id is %', _user_id;

	PERFORM * FROM sqlite_fs.generate_sqlite_box(_user_id, _datasets , _files, _reset_box);

	RETURN 'OK';

 END;
 $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


  CREATE OR REPLACE FUNCTION sqlite_fs.generate_sqlite_box(_user_id int8, _datasets text[], _files text  [], _reset_box bool)
  RETURNS void AS $BODY$
  --do not call directly
  DECLARE
   _box_path text;
   _keys bytea[];
   _data_query text;
   _has_files bool;
  BEGIN
  	_has_files:=false;

	IF (_user_id IS NULL) THEN
		RAISE EXCEPTION 'user id is mandatory';
	END IF;

	IF (_datasets IS NULL) THEN
		RAISE EXCEPTION 'datasets are mandatory';
	END IF;

	IF (CARDINALITY(_datasets) = 0) THEN
		RAISE EXCEPTION 'datasets cannot be empty';
	END IF;

	IF (_reset_box IS NULL) THEN
		RAISE EXCEPTION 'reset_box parameter is mandatory';
	END IF;

	IF (CARDINALITY(_files) > 0) THEN
		_has_files:=true;
	END IF;

 	_box_path:=(SELECT current_setting('dbox.location')) || '/' || _user_id || '.sqlite';


	RAISE NOTICE 'path for box is %', _box_path;


 	IF (_reset_box) THEN
 		PERFORM sqlite_fs.remove(_box_path); --maybe better just truncate
 	END IF;

 	--create box
 	PERFORM sqlite_fs.make(_box_path);

	--create entries:
	SELECT ARRAY_AGG(ukt.pubkey) INTO _keys
	FROM public.user_key_table ukt
	WHERE ukt.user_id=_user_id AND ukt.type IN ('ssh-ed25519'::public.key_type, 'c4gh-v1'::public.key_type);

	IF _keys IS NULL THEN
		RAISE EXCEPTION 'We could not get the parsed keys for the user';
	END IF;

	IF CARDINALITY(_keys) IS NULL THEN
		RAISE EXCEPTION 'There are no parsed keys for the user';
	END IF;

        --save petition
	INSERT INTO sqlite_fs.boxes_generated(username, user_id,datasets, files, reset_box)
	SELECT username, _user_id, _datasets, _files, _reset_box
	FROM public.user_table WHERE id=_user_id;

	--create files
	_data_query:= '
	WITH sq AS (
 		 SELECT unnest($3) AS id
 	)
 	 	SELECT DISTINCT ON (ft.stable_id)
		dbox.insert_file($1,
		REPLACE(ft.stable_id, ''EGAF'',''2'')::int8, --inode
		priv_ft.mount_point || ''/'' || priv_ft.relative_path,
		crypt4gh.header_reencrypt(priv_ft.header, $2)
		)
 	FROM sq
 	INNER JOIN public.dataset_table dt ON dt.stable_id=sq.id
 	INNER JOIN public.dataset_file_table dft ON dft.dataset_stable_id=dt.stable_id
 	INNER JOIN public.file_table ft ON ft.stable_id=dft.file_stable_id ';

	IF (_has_files = true) THEN
		_data_query:= _data_query || '
	INNER JOIN (
	 SELECT unnest($4) AS id
	) fq ON fq.id=ft.stable_id
	';
	END IF;

	_data_query:= _data_query || ' INNER JOIN private.file_table priv_ft ON priv_ft.stable_id=ft.stable_id ORDER BY ft.stable_id asc;';

	EXECUTE _data_query USING _box_path, _keys, _datasets, _files;

	--insert entries
	--insert directories
	--insert directory entries
	PERFORM (
		WITH dir_entries AS (
			SELECT DISTINCT dt.stable_id,
						REPLACE(dt.stable_id, 'EGAD', '1')::int8 as inode,
						dt.created_at,
						dt.edited_at
			FROM ( SELECT unnest(_datasets) AS id) sq
			INNER JOIN public.dataset_table dt ON dt.stable_id=sq.id
		), do_job AS (
			SELECT sqlite_fs.insert_entry(
				_box_path,
				dir_entries.inode,
				dir_entries.stable_id, --name
				1::int8, --parent_inode,
				NULL::text, --decrypted size
				extract(epoch from dir_entries.created_at)::int8,
				extract(epoch from dir_entries.edited_at)::int8,
				1,
				0,
				true)
			FROM dir_entries
			) SELECT COUNT(*) from do_job
	);

	--insert file entries

	_data_query:= '
 	WITH sq AS (
 	 SELECT unnest($2) AS id
 	)
 	SELECT DISTINCT ON (dt.stable_id, ft.stable_id)
		dbox.insert_entry($1,
			REPLACE(ft.stable_id, ''EGAF'',''2'')::int8, --inode
			ft.display_name,
			REPLACE(dt.stable_id, ''EGAD'', ''1'')::int8, --parent_inode
			fs.decrypted_filesize(priv_ft.payload_size)::text,
			extract(epoch from ft.created_at)::int8,
			extract(epoch from ft.edited_at)::int8,
			1,
			priv_ft.payload_size + fs.header_size(octet_length(priv_ft.header), $4::int),
			false --is_dir
		)
 	FROM sq
 	INNER JOIN public.dataset_table dt ON dt.stable_id=sq.id
 	INNER JOIN public.dataset_file_table dft ON dft.dataset_stable_id=dt.stable_id
 	INNER JOIN public.file_table ft ON ft.stable_id=dft.file_stable_id';


	IF (_has_files = true) THEN
		_data_query:= _data_query || '
	INNER JOIN (
	 SELECT unnest($3) AS id
	) fq ON fq.id=ft.stable_id
	';
	END IF;

	_data_query:= _data_query || ' INNER JOIN private.file_table priv_ft ON priv_ft.stable_id=ft.stable_id ORDER BY dt.stable_id asc, ft.stable_id asc;';

	EXECUTE _data_query USING _box_path, _datasets, _files, CARDINALITY(_keys);

 END;
 $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
