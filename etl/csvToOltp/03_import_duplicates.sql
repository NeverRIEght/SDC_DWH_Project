CREATE TEMPORARY TABLE IF NOT EXISTS temp_duplicates_import
(
    object_storage_url_1 TEXT,
    object_storage_url_2 TEXT
);

COPY temp_duplicates_import
    (object_storage_url_1, object_storage_url_2)
    FROM '/var/lib/postgresql/csv_imports/mediafiles_duplicates.csv' -- Modify if needed
    DELIMITER ','
    CSV HEADER;

INSERT INTO duplicates (mediafile_1_id, mediafile_2_id)
SELECT
    CASE
        WHEN mf1.id < mf2.id THEN mf1.id
        ELSE mf2.id
        END
        AS mediafile_1_id,
    CASE
        WHEN mf1.id < mf2.id THEN mf2.id
        ELSE mf1.id
        END
        AS mediafile_2_id
FROM temp_duplicates_import tdi
         JOIN mediafiles mf1 ON tdi.object_storage_url_1 = mf1.object_storage_url
         JOIN mediafiles mf2 ON tdi.object_storage_url_2 = mf2.object_storage_url
ON CONFLICT (mediafile_1_id, mediafile_2_id) DO NOTHING;

DROP TABLE IF EXISTS temp_duplicates_import;