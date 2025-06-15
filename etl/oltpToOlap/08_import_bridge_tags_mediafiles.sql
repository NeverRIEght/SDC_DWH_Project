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

DROP FOREIGN TABLE IF EXISTS oltp_tags CASCADE;
CREATE FOREIGN TABLE oltp_tags (
    id BIGINT,
    user_id BIGINT,
    name TEXT,
    created_datetime TIMESTAMP
    )
    SERVER oltp_server
    OPTIONS (schema_name 'public', table_name 'tags');

DROP FOREIGN TABLE IF EXISTS oltp_mediafiles_tags CASCADE;
CREATE FOREIGN TABLE oltp_mediafiles_tags (
    id BIGINT,
    mediafile_id BIGINT NOT NULL,
    tag_id BIGINT NOT NULL
    )
    SERVER oltp_server
    OPTIONS (schema_name 'public', table_name 'mediafiles_tags');

DO $$
    DECLARE
        _rows_closed INT := 0;
        _rows_inserted INT := 0;
        _current_etl_date DATE := CURRENT_DATE;
    BEGIN
        -- Links from oltp
        WITH source_links AS (
            SELECT
                omt.id AS mediafiles_tags_id,
                dm.id AS mediafile_key,
                dt.id AS tag_key
            FROM
                oltp_mediafiles_tags omt
                    JOIN
                dim_mediafile dm ON omt.mediafile_id = dm.mediafile_id
                    JOIN
                oltp_mediafiles om ON dm.mediafile_id = om.id
                    JOIN
                dim_tag dt ON omt.tag_id = dt.tag_id
            WHERE
                (om.trashed_datetime IS NULL OR om.trashed_datetime >= (_current_etl_date + INTERVAL '1 day'))
        ),
             -- Active links from olap
             current_bridge_links AS (
                 SELECT
                     btm.mediafile_key,
                     btm.tag_key
                 FROM
                     bridge_tags_mediafiles btm
                 WHERE
                     btm.is_current = TRUE
             )

        -- Step 1: Close outdated records
        UPDATE bridge_tags_mediafiles btm
        SET
            is_current = FALSE,
            end_date = _current_etl_date
        WHERE
            btm.is_current = TRUE
          AND NOT EXISTS (
            SELECT 1
            FROM source_links sl
            WHERE
                sl.mediafile_key = btm.mediafile_key AND
                sl.tag_key = btm.tag_key
        );

        GET DIAGNOSTICS _rows_closed = ROW_COUNT;
        RAISE NOTICE 'Closed % outdated records in bridge_tags_mediafiles.', _rows_closed;



        WITH source_links AS (
            SELECT
                omt.id AS mediafiles_tags_id,
                dm.id AS mediafile_key,
                dt.id AS tag_key
            FROM
                oltp_mediafiles_tags omt
                    JOIN
                dim_mediafile dm ON omt.mediafile_id = dm.mediafile_id
                    JOIN
                oltp_mediafiles om ON dm.mediafile_id = om.id
                    JOIN
                dim_tag dt ON omt.tag_id = dt.tag_id
            WHERE
                (om.trashed_datetime IS NULL OR om.trashed_datetime >= (_current_etl_date + INTERVAL '1 day'))
        ),
             current_bridge_links AS (
                 SELECT
                     btm.mediafile_key,
                     btm.tag_key
                 FROM
                     bridge_tags_mediafiles btm
                 WHERE
                     btm.is_current = TRUE
             )

        -- Step 2: Insert new records
        INSERT INTO bridge_tags_mediafiles (
            mediafiles_tags_id,
            mediafile_key,
            tag_key,
            start_date,
            end_date,
            is_current
        )
        SELECT
            sl.mediafiles_tags_id,
            sl.mediafile_key,
            sl.tag_key,
            _current_etl_date AS start_date,
            NULL AS end_date,
            TRUE AS is_current
        FROM
            source_links sl
        WHERE
            NOT EXISTS (
                SELECT 1
                FROM current_bridge_links cbl
                WHERE
                    cbl.mediafile_key = sl.mediafile_key AND
                    cbl.tag_key = sl.tag_key
            );

        GET DIAGNOSTICS _rows_inserted = ROW_COUNT;
        RAISE NOTICE 'Added/Updated % records in bridge_tags_mediafiles.', _rows_inserted;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error while populating bridge_tags_mediafiles: %', SQLERRM;
    END $$;