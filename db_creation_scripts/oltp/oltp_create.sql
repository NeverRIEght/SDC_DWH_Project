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
    "object_storage_url" TEXT      NOT NULL,
    "is_favorite"        BOOLEAN   NOT NULL,
    "trashed_datetime"   TIMESTAMPTZ,
    PRIMARY KEY ("id")
);

CREATE TABLE "albums"
(
    "id"               BIGSERIAL   NOT NULL,
    "name"             TEXT        NOT NULL,
    "created_datetime" TIMESTAMPTZ NOT NULL,
    "updated_datetime" TIMESTAMPTZ NOT NULL,
    "viewed_datetime"  TIMESTAMPTZ NOT NULL,
    "user_id" BIGINT NOT NULL,
    PRIMARY KEY ("id")
);

CREATE TABLE "tags"
(
    "id"               BIGSERIAL   NOT NULL,
    "name"             TEXT        NOT NULL,
    "created_datetime" TIMESTAMPTZ NOT NULL,
    "updated_datetime" TIMESTAMPTZ NOT NULL,
    "viewed_datetime"  TIMESTAMPTZ NOT NULL,
    "user_id" BIGINT NOT NULL,
    PRIMARY KEY ("id")
);

CREATE TABLE "mediafiles_tags"
(
    "id"           BIGSERIAL NOT NULL,
    "mediafile_id" BIGINT    NOT NULL,
    "tag_id"       BIGINT    NOT NULL,
    PRIMARY KEY ("id")
);

CREATE TABLE "groups"
(
    "id"               BIGSERIAL   NOT NULL,
    "name"             TEXT        NOT NULL,
    "subgroup_id"      BIGINT,
    "created_datetime" TIMESTAMPTZ NOT NULL,
    "updated_datetime" TIMESTAMPTZ NOT NULL,
    "viewed_datetime"  TIMESTAMPTZ NOT NULL,
    "user_id" BIGINT NOT NULL,
    PRIMARY KEY ("id")
);

CREATE TABLE "mediafiles_groups"
(
    "id"           BIGSERIAL NOT NULL,
    "mediafile_id" BIGINT    NOT NULL,
    "group_id"     BIGINT    NOT NULL,
    PRIMARY KEY ("id")
);

CREATE TABLE "users"
(
    "id"   BIGSERIAL NOT NULL,
    "name" TEXT      NOT NULL,
    "email" TEXT      NOT NULL,
    PRIMARY KEY ("id")
);

ALTER TABLE "mediafiles_albums"
    ADD FOREIGN KEY ("mediafile_id") REFERENCES "mediafiles" ("id")
        ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE "mediafiles_albums"
    ADD FOREIGN KEY ("album_id") REFERENCES "albums" ("id")
        ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE "mediafiles_tags"
    ADD FOREIGN KEY ("mediafile_id") REFERENCES "mediafiles" ("id")
        ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE "mediafiles_tags"
    ADD FOREIGN KEY ("tag_id") REFERENCES "tags" ("id")
        ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE "mediafiles_groups"
    ADD FOREIGN KEY ("group_id") REFERENCES "groups" ("id")
        ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE "mediafiles_groups"
    ADD FOREIGN KEY ("mediafile_id") REFERENCES "mediafiles" ("id")
        ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE "groups"
    ADD FOREIGN KEY ("subgroup_id") REFERENCES "groups" ("id")
        ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE "mediafiles"
    ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id")
        ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE "albums"
    ADD FOREIGN KEY("user_id") REFERENCES "users"("id")
        ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE "tags"
    ADD FOREIGN KEY("user_id") REFERENCES "users"("id")
        ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE "groups"
    ADD FOREIGN KEY("user_id") REFERENCES "users"("id")
        ON UPDATE NO ACTION ON DELETE CASCADE;

ALTER TABLE "albums"
    ADD CONSTRAINT "uq_album_name_user" UNIQUE ("name", "user_id");

ALTER TABLE "tags"
    ADD CONSTRAINT "uq_tag_name_user" UNIQUE ("name", "user_id");

ALTER TABLE "groups"
    ADD CONSTRAINT "uq_group_name_user" UNIQUE ("name", "user_id");

ALTER TABLE "users"
    ADD CONSTRAINT "uq_email" UNIQUE ("email");

ALTER TABLE "mediafiles"
    ADD CONSTRAINT "uq_object_storage_url" UNIQUE ("object_storage_url");