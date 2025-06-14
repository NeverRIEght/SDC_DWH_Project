DROP FOREIGN TABLE IF EXISTS oltp_user_preferences CASCADE;
CREATE FOREIGN TABLE oltp_user_preferences (
    id BIGINT,
    user_id BIGINT,
    is_dark_theme BOOLEAN,
    is_ai_allowed BOOLEAN
    )
    SERVER oltp_server
    OPTIONS (schema_name 'public', table_name 'user_preferences');

DO $$
    DECLARE
        _rows_closed INT := 0;
        _rows_inserted INT := 0;
        _current_etl_date DATE := CURRENT_DATE;
    BEGIN
        -- Step 1: Close old versions of user preferences in dim_user_preferences.
        -- get current preferences from source (oltp)
        WITH source_preferences AS (
            SELECT
                oup.id AS user_preferences_id,
                du.id AS user_key,
                oup.is_dark_theme,
                oup.is_ai_allowed
            FROM
                oltp_user_preferences oup
                    JOIN
                dim_user du ON oup.user_id = du.user_id
        )
        UPDATE dim_user_preferences dup
        SET
            is_current = FALSE,
            end_date = _current_etl_date
        WHERE
            dup.is_current = TRUE
          AND EXISTS (
            SELECT 1
            FROM source_preferences sp
            WHERE
                sp.user_key = dup.user_key
              AND (
                sp.is_dark_theme <> dup.is_dark_theme OR
                sp.is_ai_allowed <> dup.is_ai_allowed
                )
        );

        GET DIAGNOSTICS _rows_closed = ROW_COUNT;

        RAISE NOTICE 'Closed % outdated records in dim_user_preferences.', _rows_closed;

        -- Step 2: Insert new and updated user preferences into dim_user_preferences.
        WITH source_preferences AS (
            SELECT
                oup.id AS user_preferences_id,
                du.id AS user_key,
                oup.is_dark_theme,
                oup.is_ai_allowed
            FROM
                oltp_user_preferences oup
                    JOIN
                dim_user du ON oup.user_id = du.user_id
        )
        INSERT INTO dim_user_preferences (
            user_preferences_id,
            user_key,
            start_date,
            end_date,
            is_current,
            is_dark_theme,
            is_ai_allowed
        )
        SELECT
            sp.user_preferences_id,
            sp.user_key,
            _current_etl_date AS start_date,
            NULL AS end_date,
            TRUE AS is_current,
            sp.is_dark_theme,
            sp.is_ai_allowed
        FROM
            source_preferences sp
        WHERE
            NOT EXISTS (
                SELECT 1
                FROM dim_user_preferences dup_check
                WHERE
                    dup_check.user_key = sp.user_key
                  AND dup_check.is_current = TRUE
            );

        GET DIAGNOSTICS _rows_inserted = ROW_COUNT;
        RAISE NOTICE 'Added/Updated % records in dim_user_preferences.', _rows_inserted;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error while importing dim_user_preferences: %', SQLERRM;
    END $$;