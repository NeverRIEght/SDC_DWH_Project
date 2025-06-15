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

DO
$$
    DECLARE
        _start_date_to_process DATE; -- First date to process (next day after the last processed date)
        _end_date_to_process   DATE := CURRENT_DATE; -- Last date to process (today)
        _processing_date       DATE;
        _date_key              BIGINT;
        _rows_processed        INT  := 0;
    BEGIN
        SELECT COALESCE(MAX(dd.full_date), '2020-01-01'::DATE) + INTERVAL '1 day'
        INTO _start_date_to_process
        FROM fact_mediafile_activity fma
                 JOIN dim_date dd ON fma.date_key = dd.id;

        _processing_date := _start_date_to_process;
        WHILE _processing_date <= _end_date_to_process
            LOOP
                SELECT id
                INTO _date_key
                FROM dim_date
                WHERE full_date = _processing_date;

                IF _date_key IS NULL THEN
                    RAISE WARNING 'date_key not found for date: %. Please, re-run 03_import_date.sql', _processing_date;
                    _processing_date := _processing_date + INTERVAL '1 day';
                    CONTINUE;
                END IF;

                INSERT INTO fact_mediafile_activity (date_key, user_key, num_files_uploaded_today, total_files,
                                                     total_trashed_files)
                SELECT _date_key                                                 AS date_key,
                       du.id                                                     AS user_key,
                       COALESCE(user_activity_stats.num_files_uploaded_today, 0) AS num_files_uploaded_today,
                       COALESCE(user_activity_stats.total_files, 0)              AS total_files,
                       COALESCE(user_activity_stats.total_trashed_files, 0)      AS total_trashed_files
                FROM dim_user du
                         LEFT JOIN
                     (SELECT om.user_id,
                             COUNT(CASE
                                       WHEN om.uploaded_datetime >= _processing_date AND
                                            om.uploaded_datetime < (_processing_date + INTERVAL '1 day')
                                           THEN om.id
                                 END) AS num_files_uploaded_today,
                             COUNT(CASE
                                       WHEN om.uploaded_datetime < (_processing_date + INTERVAL '1 day')
                                           AND (om.trashed_datetime IS NULL OR
                                                om.trashed_datetime >= (_processing_date + INTERVAL '1 day'))
                                           THEN om.id
                                 END) AS total_files,
                             COUNT(CASE
                                       WHEN om.uploaded_datetime < (_processing_date + INTERVAL '1 day')
                                           AND om.trashed_datetime IS NOT NULL
                                           AND om.trashed_datetime < (_processing_date + INTERVAL '1 day')
                                           THEN om.id
                                 END) AS total_trashed_files
                      FROM oltp_mediafiles om
                      WHERE om.uploaded_datetime < (_processing_date + INTERVAL '1 day')
                      GROUP BY om.user_id) user_activity_stats ON du.user_id = user_activity_stats.user_id
                ON CONFLICT (date_key, user_key) DO UPDATE SET num_files_uploaded_today = EXCLUDED.num_files_uploaded_today,
                                                               total_files              = EXCLUDED.total_files,
                                                               total_trashed_files      = EXCLUDED.total_trashed_files;


                _processing_date := _processing_date + INTERVAL '1 day';
            END LOOP;

        GET DIAGNOSTICS _rows_processed = ROW_COUNT;

        RAISE NOTICE 'Added/Updated % records in fact_mediafile_activity', _rows_processed;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error while populating fact_mediafile_activity: %', SQLERRM;
    END
$$;