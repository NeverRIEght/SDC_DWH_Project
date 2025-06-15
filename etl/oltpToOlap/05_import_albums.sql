DROP FOREIGN TABLE IF EXISTS oltp_albums CASCADE;
CREATE FOREIGN TABLE oltp_albums (
    id BIGINT,
    user_id BIGINT,
    name TEXT,
    created_datetime TIMESTAMP
    )
    SERVER oltp_server
    OPTIONS (schema_name 'public', table_name 'albums');

-- Part 1: Populate new values
DO $$
    DECLARE
        _last_loaded_album_id BIGINT;
        _rows_affected INT := 0;
    BEGIN
        SELECT COALESCE(MAX(album_id), 0)
        INTO _last_loaded_album_id
        FROM dim_album;

        INSERT INTO dim_album (album_id, user_key, name, is_deleted)
        SELECT
            oa.id AS album_id,
            du.id AS user_key,
            oa."name" AS "name",
            FALSE AS is_deleted
        FROM
            oltp_albums oa
                JOIN
            dim_user du ON oa.user_id = du.user_id
        WHERE
            oa.id > _last_loaded_album_id;

        GET DIAGNOSTICS _rows_affected = ROW_COUNT;

        RAISE NOTICE 'Added % rows to dim_album.', _rows_affected;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error while populating dim_album: %', SQLERRM;
    END $$;

-- Part 2: Mark as deleted albums that no longer exist in oltp_albums
DO $$
    DECLARE
        _rows_marked_deleted INT := 0;
    BEGIN
        UPDATE dim_album da
        SET is_deleted = TRUE
        WHERE
            da.is_deleted = FALSE
          AND NOT EXISTS (
            SELECT 1
            FROM oltp_albums oa
            WHERE oa.id = da.album_id
        );

        GET DIAGNOSTICS _rows_marked_deleted = ROW_COUNT;

        RAISE NOTICE 'Marked as deleted: % albums in dim_album.', _rows_marked_deleted;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error while resolving deleted albums in dim_album: %', SQLERRM;
    END $$;