CREATE TABLE "mediafiles_albums"
(
    "id"           BIGSERIAL NOT NULL,
    "mediafile_id" BIGINT    NOT NULL,
    "album_id"     BIGINT    NOT NULL,
    PRIMARY KEY ("id")
);

CREATE TABLE "mediafiles"
(
    "id"                 BIGSERIAL NOT NULL,
    "user_id"            BIGINT    NOT NULL,
    "object_storage_url" TEXT      NOT NULL UNIQUE,
    "is_favorite"        BOOLEAN   NOT NULL DEFAULT FALSE,
    "trashed_datetime"   TIMESTAMPTZ        DEFAULT NULL,
    PRIMARY KEY ("id")
);

CREATE TABLE "albums"
(
    "id"               BIGSERIAL   NOT NULL,
    "user_id"          BIGINT      NOT NULL,
    "name"             TEXT        NOT NULL,
    "created_datetime" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_datetime" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "viewed_datetime"  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id")
);

CREATE TABLE "tags"
(
    "id"               BIGSERIAL   NOT NULL,
    "user_id"          BIGINT      NOT NULL,
    "name"             TEXT        NOT NULL,
    "created_datetime" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_datetime" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "viewed_datetime"  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id")
);

CREATE TABLE "mediafiles_tags"
(
    "id"           BIGSERIAL NOT NULL,
    "mediafile_id" BIGINT    NOT NULL,
    "tag_id"       BIGINT    NOT NULL,
    PRIMARY KEY ("id")
);

CREATE TABLE "users"
(
    "id"           BIGSERIAL NOT NULL,
    "email"        TEXT      NOT NULL UNIQUE,
    "display_name" TEXT      NOT NULL,
    PRIMARY KEY ("id")
);

CREATE TABLE "duplicates"
(
    "id"             BIGSERIAL NOT NULL,
    "mediafile_1_id" BIGINT    NOT NULL,
    "mediafile_2_id" BIGINT    NOT NULL,
    PRIMARY KEY ("id")
);

CREATE TABLE "user_preferences"
(
    "id"            BIGSERIAL NOT NULL,
    "user_id"       BIGINT    NOT NULL UNIQUE,
    "is_dark_theme" BOOLEAN   NOT NULL DEFAULT TRUE,
    "is_ai_allowed" BOOLEAN   NOT NULL DEFAULT FALSE,
    PRIMARY KEY ("id")
);

ALTER TABLE "mediafiles_albums"
    ADD FOREIGN KEY ("mediafile_id") REFERENCES "mediafiles" ("id")
        ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE "mediafiles_albums"
    ADD FOREIGN KEY ("album_id") REFERENCES "albums" ("id")
        ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE "mediafiles_albums"
    ADD CONSTRAINT unique_mediafiles_albums UNIQUE (mediafile_id, album_id);

ALTER TABLE "mediafiles_tags"
    ADD FOREIGN KEY ("tag_id") REFERENCES "tags" ("id")
        ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE "mediafiles_tags"
    ADD CONSTRAINT unique_mediafiles_tags UNIQUE (mediafile_id, tag_id);

ALTER TABLE "mediafiles"
    ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id")
        ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE "user_preferences"
    ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id")
        ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE "duplicates"
    ADD FOREIGN KEY ("mediafile_1_id") REFERENCES "mediafiles" ("id")
        ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE "duplicates"
    ADD FOREIGN KEY ("mediafile_2_id") REFERENCES "mediafiles" ("id")
        ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE "mediafiles_tags"
    ADD FOREIGN KEY ("mediafile_id") REFERENCES "mediafiles" ("id")
        ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE "albums"
    ADD CONSTRAINT "unique_user_tag_name" UNIQUE ("user_id", "name");

ALTER TABLE "tags"
    ADD CONSTRAINT "unique_user_tag_name" UNIQUE ("user_id", "name");

ALTER TABLE "duplicates"
    ADD CONSTRAINT check_duplicates_order CHECK (mediafile_1_id < mediafile_2_id);

ALTER TABLE "duplicates"
    ADD CONSTRAINT unique_duplicates_pair UNIQUE (mediafile_1_id, mediafile_2_id);