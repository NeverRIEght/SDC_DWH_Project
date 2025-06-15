DO $$
    DECLARE
        _current_etl_date DATE := CURRENT_DATE;
        _date_key BIGINT;
        _rows_deleted INT := 0;
        _rows_inserted_tag_added INT := 0;
        _rows_inserted_tag_removed INT := 0;
    BEGIN
        SELECT id
        INTO _date_key
        FROM dim_date
        WHERE full_date = _current_etl_date;

        IF _date_key IS NULL THEN
            RAISE EXCEPTION 'date_key not found for date: %. Please, re-run 03_import_date.sql', _current_etl_date;
        END IF;

        -- In case it was uploaded before today
        DELETE FROM fact_tagging_activity
        WHERE date_key = _date_key;

        GET DIAGNOSTICS _rows_deleted = ROW_COUNT;
        RAISE NOTICE 'Closed % outdated records in fact_tagging_activity for date: %.', _rows_deleted, _current_etl_date;

        -- Step 1: "Tag added" events
        INSERT INTO fact_tagging_activity (date_key, bridge_tag_key, event_type, event_count)
        SELECT
            _date_key,
            btm.id AS bridge_tag_key,
            'Tag added' AS event_type,
            1 AS event_count
        FROM
            bridge_tags_mediafiles btm
        WHERE
            btm.start_date = _current_etl_date
          AND btm.is_current = TRUE;

        GET DIAGNOSTICS _rows_inserted_tag_added = ROW_COUNT;

        RAISE NOTICE 'Added/Updated % records "Tag added" in fact_tagging_activity.', _rows_inserted_tag_added;

        -- Step 2: "Tag removed" events
        INSERT INTO fact_tagging_activity (date_key, bridge_tag_key, event_type, event_count)
        SELECT
            _date_key,
            btm.id AS bridge_tag_key,
            'Tag removed' AS event_type,
            1 AS event_count
        FROM
            bridge_tags_mediafiles btm
        WHERE
            btm.end_date = _current_etl_date
          AND btm.is_current = FALSE; -- Make sure it is a removal event

        GET DIAGNOSTICS _rows_inserted_tag_removed = ROW_COUNT;
        RAISE NOTICE 'Added/Updated % records "Tag removed" in fact_tagging_activity.', _rows_inserted_tag_removed;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error while populating fact_tagging_activity: %', SQLERRM;
    END $$;