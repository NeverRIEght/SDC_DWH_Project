CREATE EXTENSION IF NOT EXISTS postgres_fdw;

DROP SERVER IF EXISTS oltp_server CASCADE;

CREATE SERVER oltp_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'oltp', port '5432', dbname 'oltp_db');

CREATE USER MAPPING FOR CURRENT_USER
    SERVER oltp_server
    OPTIONS (user 'oltp_user', password 'oltp_password');

CREATE FOREIGN TABLE oltp_users (
    id BIGINT,
    email TEXT,
    display_name TEXT
    )
    SERVER oltp_server
    OPTIONS (schema_name 'public', table_name 'users');

DO
$$
    BEGIN
        PERFORM 1
        FROM oltp_users
        LIMIT 1;

        RAISE NOTICE 'OLTP server connection successful.';

    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Error while connecting OLTP server using FDW: %', SQLERRM;
    END;
$$;