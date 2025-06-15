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

        INSERT INTO fact_mediafile_activity (date_key, user_key, num_files_uploaded_today, total_files, total_trashed_files)
        SELECT
            _date_key AS date_key,
            du.id AS user_key, -- Используем user_key из dim_user
            COALESCE(user_activity_stats.num_files_uploaded_today, 0) AS num_files_uploaded_today,
            COALESCE(user_activity_stats.total_files, 0) AS total_files,
            COALESCE(user_activity_stats.total_trashed_files, 0) AS total_trashed_files
        FROM
            dim_user du
                LEFT JOIN
            (
                SELECT
                    om.user_id,
                    COUNT(CASE
                              WHEN om.uploaded_datetime >= _current_etl_date
                                  AND om.uploaded_datetime < (_current_etl_date + INTERVAL '1 day')
                                  THEN om.id
                        END) AS num_files_uploaded_today,
                    COUNT(CASE
                              WHEN om.uploaded_datetime < (_current_etl_date + INTERVAL '1 day')
                                  AND (om.trashed_datetime IS NULL
                                      OR om.trashed_datetime >= (_current_etl_date + INTERVAL '1 day'))
                                  THEN om.id
                        END) AS total_files,
                    COUNT(CASE
                              WHEN om.uploaded_datetime < (_current_etl_date + INTERVAL '1 day')
                                  AND om.trashed_datetime IS NOT NULL
                                  AND om.trashed_datetime < (_current_etl_date + INTERVAL '1 day')
                                  THEN om.id
                        END) AS total_trashed_files
                FROM
                    oltp_mediafiles om
                WHERE
                    om.uploaded_datetime < (_current_etl_date + INTERVAL '1 day')
                GROUP BY
                    om.user_id
            ) user_activity_stats ON du.user_id = user_activity_stats.user_id
        ON CONFLICT (date_key, user_key) DO UPDATE SET
                                                       num_files_uploaded_today = EXCLUDED.num_files_uploaded_today,
                                                       total_files = EXCLUDED.total_files,
                                                       total_trashed_files = EXCLUDED.total_trashed_files;

        GET DIAGNOSTICS _rows_processed = ROW_COUNT;

        RAISE NOTICE 'Added/Updated % records in fact_mediafile_activity', _rows_processed;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error while populating fact_mediafile_activity: %', SQLERRM;
    END $$;