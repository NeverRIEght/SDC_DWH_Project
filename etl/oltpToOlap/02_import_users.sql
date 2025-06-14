DROP FOREIGN TABLE IF EXISTS oltp_users CASCADE;
CREATE FOREIGN TABLE oltp_users (
    id BIGINT,
    email TEXT,
    display_name TEXT
    )
    SERVER oltp_server
    OPTIONS (schema_name 'public', table_name 'users');

INSERT INTO dim_user (user_id, email, display_name)
SELECT ou.id AS user_id,
       ou.email,
       ou.display_name
FROM oltp_users ou
ON CONFLICT (user_id) DO UPDATE SET email        = EXCLUDED.email,
                                    display_name = EXCLUDED.display_name;