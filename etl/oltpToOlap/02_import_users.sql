CREATE OR REPLACE VIEW v_dim_user AS
SELECT id AS user_id,
       email,
       display_name
FROM oltp_users;

INSERT INTO dim_user (user_id, email, display_name)
SELECT vdu.user_id,
       vdu.email,
       vdu.display_name
FROM v_dim_user vdu
ON CONFLICT (user_id) DO UPDATE SET email        = EXCLUDED.email,
                                    display_name = EXCLUDED.display_name;