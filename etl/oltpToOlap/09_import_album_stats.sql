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

DROP FOREIGN TABLE IF EXISTS oltp_albums CASCADE;
CREATE FOREIGN TABLE oltp_albums (
    id BIGINT,
    user_id BIGINT,
    name TEXT,
    created_datetime TIMESTAMP
    )
    SERVER oltp_server
    OPTIONS (schema_name 'public', table_name 'albums');

DROP FOREIGN TABLE IF EXISTS oltp_mediafiles_albums CASCADE;
CREATE FOREIGN TABLE oltp_mediafiles_albums (
    id BIGINT,
    mediafile_id BIGINT,
    album_id BIGINT
    )
    SERVER oltp_server
    OPTIONS (schema_name 'public', table_name 'mediafiles_albums');

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

        INSERT INTO fact_album_stats (album_key, date_key, mediafile_count, favorites_count, trashed_count)
        SELECT
            da.id AS album_key,
            _date_key AS date_key,
            COALESCE(album_stats.mediafile_count, 0) AS mediafile_count,
            COALESCE(album_stats.favorites_count, 0) AS favorites_count,
            COALESCE(album_stats.trashed_count, 0) AS trashed_count
        FROM
            dim_album da
                LEFT JOIN
            (
                SELECT
                    mfa.album_id,
                    COUNT(mf.id) AS mediafile_count,
                    COUNT(CASE WHEN mf.is_favorite = TRUE THEN mf.id END) AS favorites_count,
                    COUNT(CASE WHEN mf.trashed_datetime IS NOT NULL THEN mf.id END) AS trashed_count
                FROM
                    oltp_mediafiles_albums mfa
                        JOIN
                    oltp_mediafiles mf ON mfa.mediafile_id = mf.id
                WHERE
                    mf.uploaded_datetime < (_current_etl_date + INTERVAL '1 day')
                GROUP BY
                    mfa.album_id
            ) album_stats ON da.album_id = album_stats.album_id
        WHERE
            da.is_deleted = FALSE -- only active albums
        ON CONFLICT (album_key, date_key) DO UPDATE SET -- if record exists, update stats
                                                        mediafile_count = EXCLUDED.mediafile_count,
                                                        favorites_count = EXCLUDED.favorites_count,
                                                        trashed_count = EXCLUDED.trashed_count;

        GET DIAGNOSTICS _rows_processed = ROW_COUNT;
        RAISE NOTICE 'Added/Updated % records in fact_album_stats', _rows_processed;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error populating fact_album_stats: %', SQLERRM;
    END $$;