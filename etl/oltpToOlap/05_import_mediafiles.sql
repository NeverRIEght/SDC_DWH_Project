CREATE FOREIGN TABLE oltp_mediafiles (
    id BIGINT,
    user_id BIGINT,
    object_storage_url TEXT,
    is_favorite BOOLEAN,
    trashed_datetime TIMESTAMPTZ,
    uploaded_datetime TIMESTAMPTZ
)
    SERVER oltp_server
    OPTIONS (schema_name 'public', table_name 'mediafiles');

DO $$
    DECLARE
        _last_loaded_mediafile_id BIGINT;
        _rows_inserted INT := 0;
    BEGIN
        SELECT COALESCE(MAX(mediafile_id), 0) -- Select max mediafile_id or 0 if no records exist
        INTO _last_loaded_mediafile_id
        FROM dim_mediafile;

        INSERT INTO dim_mediafile (mediafile_id, uploaded_datetime)
        SELECT
            om.id AS mediafile_id,
            om.uploaded_datetime
        FROM
            oltp_mediafiles om
        WHERE
            om.id > _last_loaded_mediafile_id -- Only select mediafiles with id greater than the last loaded one
        ON CONFLICT (mediafile_id) DO NOTHING;

        GET DIAGNOSTICS _rows_inserted = ROW_COUNT;

        RAISE NOTICE 'Inserted % new records into dim_mediafile.', _rows_inserted;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error while populating dim_mediafile: %', SQLERRM;
    END $$;