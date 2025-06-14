CREATE TABLE "bridge_tags_mediafiles"
(
    "id"            BIGSERIAL PRIMARY KEY,
    "mediafile_key" BIGINT NOT NULL,
    "tag_key"       BIGINT NOT NULL,
    CONSTRAINT unique_mediafile_tag_link UNIQUE (mediafile_key, tag_key)
);

CREATE TABLE "dim_date"
(
    "id"          BIGSERIAL PRIMARY KEY,
    "full_date"   DATE     NOT NULL,
    "day_of_week" SMALLINT NOT NULL CHECK (day_of_week >= 1 AND day_of_week <= 7),
    "day_name"    TEXT     NOT NULL,
    "month"       SMALLINT NOT NULL CHECK (month >= 1 AND month <= 12),
    "month_name"  TEXT     NOT NULL,
    "year"        SMALLINT NOT NULL CHECK (year >= 1900 AND year <= 2100)
);

CREATE TABLE "fact_mediafile_activity"
(
    "id"                       BIGSERIAL PRIMARY KEY,
    "date_key"                 BIGINT NOT NULL,
    "user_key"                 BIGINT NOT NULL,
    "num_files_uploaded_today" BIGINT NOT NULL CHECK (num_files_uploaded_today >= 0),
    "total_files"              BIGINT NOT NULL CHECK (total_files >= 0),
    "total_trashed_files"      BIGINT NOT NULL CHECK (total_trashed_files >= 0)
);

CREATE TABLE "dim_user"
(
    "id"           BIGSERIAL PRIMARY KEY,
    "user_id"      BIGINT NOT NULL UNIQUE,
    "email"        TEXT   NOT NULL UNIQUE,
    "display_name" TEXT   NOT NULL
);

CREATE TABLE "dim_mediafile"
(
    "id"                BIGSERIAL   PRIMARY KEY,
    "mediafile_id"      BIGINT      NOT NULL UNIQUE,
    "uploaded_datetime" TIMESTAMPTZ NOT NULL
);

CREATE TABLE "dim_user_preferences"
(
    "id"                  BIGSERIAL PRIMARY KEY,
    "user_preferences_id" BIGINT  NOT NULL,
    "user_key"            BIGINT  NOT NULL,
    "start_date"          DATE    NOT NULL,
    "end_date"            DATE             DEFAULT NULL,
    "is_current"          BOOLEAN NOT NULL DEFAULT TRUE,
    "is_dark_theme"       BOOLEAN NOT NULL,
    "is_ai_allowed"       BOOLEAN NOT NULL,
    CONSTRAINT check_dates_order CHECK (end_date IS NULL OR end_date >= start_date),
    CONSTRAINT check_is_current CHECK ((is_current = TRUE AND end_date IS NULL) OR
                                       (is_current = FALSE AND end_date IS NOT NULL))
);

CREATE TABLE "fact_album_stats"
(
    "id"              BIGSERIAL PRIMARY KEY,
    "album_key"       BIGINT NOT NULL,
    "date_key"        BIGINT NOT NULL,
    "mediafile_count" BIGINT NOT NULL CHECK (mediafile_count >= 0),
    "favorites_count" BIGINT NOT NULL CHECK (favorites_count >= 0),
    "trashed_count"   BIGINT NOT NULL CHECK (trashed_count >= 0)
);

CREATE TABLE "dim_album"
(
    "id"       BIGSERIAL PRIMARY KEY,
    "album_id" BIGINT NOT NULL UNIQUE,
    "user_key" BIGINT NOT NULL
);

CREATE TABLE "fact_duplicate_mediafiles"
(
    "id"                   BIGSERIAL PRIMARY KEY,
    "date_key"             BIGINT NOT NULL,
    "user_key"             BIGINT NOT NULL,
    "mediafile1_key"       BIGINT NOT NULL,
    "mediafile2_key"       BIGINT NOT NULL,
    "duplicate_pair_count" BIGINT NOT NULL DEFAULT 1 CHECK (duplicate_pair_count >= 1),
    CONSTRAINT check_mediafile_order CHECK (mediafile1_key < mediafile2_key),
    CONSTRAINT unique_duplicate_pair_per_date UNIQUE (date_key, mediafile1_key, mediafile2_key)
);

CREATE TABLE "dim_tag"
(
    "id"       BIGSERIAL PRIMARY KEY,
    "tag_id"   BIGINT NOT NULL UNIQUE,
    "user_key" BIGINT NOT NULL,
    "name"     TEXT   NOT NULL
);

CREATE TABLE "fact_tagging_activity"
(
    "id"             BIGSERIAL PRIMARY KEY,
    "date_key"       BIGINT NOT NULL,
    "bridge_tag_key" BIGINT NOT NULL,
    "event_type_key" BIGINT NOT NULL,
    "event_count"    BIGINT NOT NULL DEFAULT 1 CHECK (event_count >= 1)
);

CREATE TABLE "dim_event_type"
(
    "id"             BIGSERIAL PRIMARY KEY,
    "event_name"     TEXT NOT NULL UNIQUE CHECK (LENGTH(event_name) > 0),
    "event_category" TEXT NOT NULL CHECK (LENGTH(event_category) > 0)
);

ALTER TABLE "fact_mediafile_activity"
    ADD FOREIGN KEY ("user_key") REFERENCES "dim_user" ("id")
        ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE "fact_mediafile_activity"
    ADD FOREIGN KEY ("date_key") REFERENCES "dim_date" ("id")
        ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE "fact_album_stats"
    ADD FOREIGN KEY ("date_key") REFERENCES "dim_date" ("id")
        ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE "dim_album"
    ADD FOREIGN KEY ("user_key") REFERENCES "dim_user" ("id")
        ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE "fact_duplicate_mediafiles"
    ADD FOREIGN KEY ("date_key") REFERENCES "dim_date" ("id")
        ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE "fact_duplicate_mediafiles"
    ADD FOREIGN KEY ("mediafile1_key") REFERENCES "dim_mediafile" ("id")
        ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE "fact_duplicate_mediafiles"
    ADD FOREIGN KEY ("mediafile2_key") REFERENCES "dim_mediafile" ("id")
        ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE "dim_tag"
    ADD FOREIGN KEY ("user_key") REFERENCES "dim_user" ("id")
        ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE "fact_duplicate_mediafiles"
    ADD FOREIGN KEY ("user_key") REFERENCES "dim_user" ("id")
        ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE "fact_tagging_activity"
    ADD FOREIGN KEY ("date_key") REFERENCES "dim_date" ("id")
        ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE "dim_user_preferences"
    ADD FOREIGN KEY ("user_key") REFERENCES "dim_user" ("id")
        ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE "fact_album_stats"
    ADD FOREIGN KEY ("album_key") REFERENCES "dim_album" ("id")
        ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE "bridge_tags_mediafiles"
    ADD FOREIGN KEY ("mediafile_key") REFERENCES "dim_mediafile" ("id")
        ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE "bridge_tags_mediafiles"
    ADD FOREIGN KEY ("tag_key") REFERENCES "dim_tag" ("id")
        ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE "fact_tagging_activity"
    ADD FOREIGN KEY ("bridge_tag_key") REFERENCES "bridge_tags_mediafiles" ("id")
        ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE "fact_tagging_activity"
    ADD FOREIGN KEY ("event_type_key") REFERENCES "dim_event_type" ("id")
        ON UPDATE NO ACTION ON DELETE NO ACTION;