DO $$
    BEGIN
        INSERT INTO dim_event_type (event_name, event_category)
        VALUES
            ('Tag added', 'Tagging'),
            ('Tag removed', 'Tagging')
        ON CONFLICT (event_name) DO NOTHING;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error while populating dim_event_type: %', SQLERRM;
    END $$;