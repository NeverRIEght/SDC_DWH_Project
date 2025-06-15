DROP FOREIGN TABLE IF EXISTS oltp_tags CASCADE;
CREATE FOREIGN TABLE oltp_tags (
    id BIGINT,
    user_id BIGINT,
    name TEXT,
    created_datetime TIMESTAMP
    )
    SERVER oltp_server
    OPTIONS (schema_name 'public', table_name 'tags');

DO $$
    DECLARE
        _last_loaded_tag_id BIGINT;
        _rows_inserted INT := 0;
    BEGIN
        SELECT COALESCE(MAX(tag_id), 0)
        INTO _last_loaded_tag_id
        FROM dim_tag;

        INSERT INTO dim_tag (tag_id, user_key, name, is_deleted)
        SELECT
            ot.id AS tag_id,
            du.id AS user_key,
            ot.name AS name,
            FALSE AS is_deleted
        FROM
            oltp_tags ot
                JOIN
            dim_user du ON ot.user_id = du.user_id
        WHERE
            ot.id > _last_loaded_tag_id
        ON CONFLICT (tag_id) DO NOTHING;

        GET DIAGNOSTICS _rows_inserted = ROW_COUNT;

        RAISE NOTICE 'Added % rows to dim_tag.', _rows_inserted;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error while populating dim_tag: %', SQLERRM;
    END $$;

DO $$
    DECLARE
        _rows_marked_deleted INT := 0;
    BEGIN

        UPDATE dim_tag dt
        SET is_deleted = TRUE
        WHERE
            dt.is_deleted = FALSE
          AND NOT EXISTS (
            SELECT 1
            FROM oltp_tags ot
            WHERE ot.id = dt.tag_id
        );

        GET DIAGNOSTICS _rows_marked_deleted = ROW_COUNT;

        RAISE NOTICE 'Marked as deleted: % tags in dim_tag.', _rows_marked_deleted;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error while resolving deleted tags in dim_tag: %', SQLERRM;
    END $$;