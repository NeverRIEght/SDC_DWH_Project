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
        _last_loaded_oltp_link_id BIGINT;
        _rows_inserted INT := 0;
    BEGIN
        SELECT COALESCE(MAX(mediafiles_tags_id), 0)
        INTO _last_loaded_oltp_link_id
        FROM bridge_tags_mediafiles;

        INSERT INTO bridge_tags_mediafiles (mediafiles_tags_id, mediafile_key, tag_key)
        SELECT
            omt.id AS mediafiles_tags_id,
            dm.id AS mediafile_key,
            dt.id AS tag_key
        FROM
            oltp_mediafiles_tags omt
                JOIN
            dim_mediafile dm ON omt.mediafile_id = dm.mediafile_id
                JOIN
            dim_tag dt ON omt.tag_id = dt.tag_id
        WHERE
            omt.id > _last_loaded_oltp_link_id
        ON CONFLICT (mediafiles_tags_id) DO NOTHING;

        GET DIAGNOSTICS _rows_inserted = ROW_COUNT;

        RAISE NOTICE 'Inserted % new records into bridge_tags_mediafiles.', _rows_inserted;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error while populating bridge_tags_mediafiles: %', SQLERRM;
    END $$;