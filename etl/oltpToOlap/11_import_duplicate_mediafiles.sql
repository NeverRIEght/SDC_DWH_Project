DROP FOREIGN TABLE IF EXISTS oltp_duplicates CASCADE;
CREATE FOREIGN TABLE oltp_duplicates (
    id BIGINT,
    mediafile_1_id BIGINT,
    mediafile_2_id BIGINT
    )
    SERVER oltp_server
    OPTIONS (schema_name 'public', table_name 'duplicates');

DROP FOREIGN TABLE IF EXISTS oltp_mediafiles CASCADE;
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
        _current_etl_date DATE := CURRENT_DATE;
        _date_key BIGINT;
        _rows_processed INT := 0;
    BEGIN
        SELECT id
        INTO _date_key
        FROM dim_date
        WHERE full_date = _current_etl_date;

        IF _date_key IS NULL THEN
            RAISE EXCEPTION 'date_key not found for date: %. Please, re-run 03_import_date.sql', _current_etl_date;
        END IF;

        INSERT INTO fact_duplicate_mediafiles (date_key, user_key, mediafile1_key, mediafile2_key, duplicate_pair_count)
        SELECT
            _date_key AS date_key,
            du.id AS user_key,
            dm1.id AS mediafile1_key,
            dm2.id AS mediafile2_key,
            1 AS duplicate_pair_count
        FROM
            oltp_duplicates od
                JOIN
            oltp_mediafiles om1 ON od.mediafile_1_id = om1.id
                JOIN
            dim_user du ON om1.user_id = du.user_id
                JOIN
            dim_mediafile dm1 ON od.mediafile_1_id = dm1.mediafile_id
                JOIN
            dim_mediafile dm2 ON od.mediafile_2_id = dm2.mediafile_id
        ON CONFLICT (date_key, mediafile1_key, mediafile2_key) DO UPDATE SET
            duplicate_pair_count = EXCLUDED.duplicate_pair_count;

        GET DIAGNOSTICS _rows_processed = ROW_COUNT;
        RAISE NOTICE 'Added/Updated % records in fact_duplicate_mediafiles', _rows_processed;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error while populating fact_duplicate_mediafiles: %', SQLERRM;
    END $$;