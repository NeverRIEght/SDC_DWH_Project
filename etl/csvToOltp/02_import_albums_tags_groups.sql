CREATE TEMPORARY TABLE IF NOT EXISTS temp_albums_tags_groups_import
(
    user_email         TEXT,
    object_storage_url TEXT,
    album_names        TEXT,
    tag_names          TEXT,
    group_paths        TEXT
);

COPY temp_albums_tags_groups_import
    (user_email, object_storage_url, album_names, tag_names, group_paths)
    FROM '/var/lib/postgresql/csv_imports/albums_tags_groups.csv' -- Modify if needed
    DELIMITER ','
    CSV HEADER;
