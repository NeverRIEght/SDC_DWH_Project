CREATE TEMPORARY TABLE IF NOT EXISTS temp_albums_tags_import
(
    object_storage_url TEXT,
    album_names        TEXT,
    tag_names          TEXT
);

COPY temp_albums_tags_import
    (object_storage_url, album_names, tag_names)
    FROM '/var/lib/postgresql/csv_imports/albums_tags.csv' -- Modify if needed
    DELIMITER ','
    CSV HEADER;


CREATE TEMPORARY TABLE IF NOT EXISTS temp_parsed_albums
(
    object_storage_url TEXT NOT NULL,
    album_name         TEXT NOT NULL
);

INSERT INTO temp_parsed_albums (object_storage_url, album_name)
SELECT
    t.object_storage_url,
    TRIM(unnested_album_name.name)
FROM temp_albums_tags_import t
         LEFT JOIN LATERAL UNNEST(STRING_TO_ARRAY(t.album_names, ',')) AS unnested_album_name(name) ON TRUE
WHERE unnested_album_name.name IS NOT NULL AND TRIM(unnested_album_name.name) != '';

INSERT INTO albums (user_id, name)
SELECT DISTINCT
    mf.user_id,
    tpa.album_name
FROM temp_parsed_albums tpa
         JOIN mediafiles mf ON tpa.object_storage_url = mf.object_storage_url
ON CONFLICT (user_id, name) DO NOTHING;

INSERT INTO mediafiles_albums (mediafile_id, album_id)
SELECT DISTINCT
    mf.id AS mediafile_id,
    a.id  AS album_id
FROM temp_parsed_albums tpa
         JOIN mediafiles mf ON tpa.object_storage_url = mf.object_storage_url
         JOIN albums a ON tpa.album_name = a.name AND mf.user_id = a.user_id
ON CONFLICT (mediafile_id, album_id) DO NOTHING;

DROP TABLE IF EXISTS temp_parsed_albums;


CREATE TEMPORARY TABLE IF NOT EXISTS temp_parsed_tags
(
    object_storage_url TEXT NOT NULL,
    tag_name           TEXT NOT NULL
);

INSERT INTO temp_parsed_tags (object_storage_url, tag_name)
SELECT
    t.object_storage_url,
    TRIM(unnested_tag_name.name)
FROM temp_albums_tags_import t
         LEFT JOIN LATERAL UNNEST(STRING_TO_ARRAY(t.tag_names, ',')) AS unnested_tag_name(name) ON TRUE
WHERE unnested_tag_name.name IS NOT NULL AND TRIM(unnested_tag_name.name) != '';

INSERT INTO tags (user_id, name)
SELECT DISTINCT
    mf.user_id,
    tpt.tag_name
FROM temp_parsed_tags tpt
         JOIN mediafiles mf ON tpt.object_storage_url = mf.object_storage_url
ON CONFLICT (user_id, name) DO NOTHING;

INSERT INTO mediafiles_tags (mediafile_id, tag_id)
SELECT DISTINCT
    mf.id AS mediafile_id,
    tg.id AS tag_id
FROM temp_parsed_tags tpt
         JOIN mediafiles mf ON tpt.object_storage_url = mf.object_storage_url
         JOIN tags tg ON tpt.tag_name = tg.name AND mf.user_id = tg.user_id
ON CONFLICT (mediafile_id, tag_id) DO NOTHING;

DROP TABLE IF EXISTS temp_parsed_tags;


DROP TABLE IF EXISTS temp_albums_tags_import;