CREATE TEMPORARY TABLE IF NOT EXISTS temp_user_preferences_import
(
    user_email TEXT,
    dark_theme BOOLEAN,
    is_ai      BOOLEAN
);

COPY temp_user_preferences_import
    (user_email, dark_theme, is_ai)
    FROM '/var/lib/postgresql/csv_imports/user_preferences.csv' -- Modify if needed
    DELIMITER ','
    CSV HEADER;

INSERT INTO user_preferences (user_id, is_dark_theme, is_ai_allowed)
SELECT
    u.id,
    t.dark_theme,
    t.is_ai
FROM temp_user_preferences_import t
         JOIN users u ON t.user_email = u.email
    ON CONFLICT (user_id) DO NOTHING;

DROP TABLE IF EXISTS temp_user_preferences_import;