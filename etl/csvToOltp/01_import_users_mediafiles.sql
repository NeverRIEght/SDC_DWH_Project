CREATE TEMPORARY TABLE IF NOT EXISTS temp_users_mediafiles_import
(
    user_name          TEXT,
    user_email          TEXT,
    object_storage_url TEXT,
    is_favorite        TEXT,
    trashed_datetime   TEXT,
    uploaded_datetime TEXT
);

COPY temp_users_mediafiles_import
    (user_name, user_email, object_storage_url, is_favorite, trashed_datetime, uploaded_datetime)
    FROM '/var/lib/postgresql/csv_imports/users_mediafiles.csv' -- Modify if needed
    DELIMITER ','
    CSV HEADER;

-- Import users, without duplicates
INSERT INTO users (display_name, email)
SELECT DISTINCT t.user_name, t.user_email
FROM temp_users_mediafiles_import t
WHERE NOT EXISTS (
    SELECT 1
    FROM users u
    WHERE u.email = t.user_email
);

-- Import mediafiles, without duplicates
INSERT INTO mediafiles (user_id, object_storage_url, is_favorite, trashed_datetime, uploaded_datetime)
SELECT
    u.id AS user_id,
    t.object_storage_url,
    t.is_favorite::BOOLEAN,
    NULLIF(t.trashed_datetime, '')::TIMESTAMPTZ,
    NULLIF(t.uploaded_datetime, '')::TIMESTAMPTZ
FROM temp_users_mediafiles_import t
         JOIN users u ON t.user_email = u.email
ON CONFLICT (object_storage_url) DO NOTHING;

-- Clean up temporary table
DROP TABLE IF EXISTS temp_users_mediafiles_import;