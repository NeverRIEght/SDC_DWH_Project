-- This script populates date dimension table with dates from now to 5 years in the future.

DO $$
    DECLARE
        _initial_start_date DATE := '2020-01-01';
        _max_existing_date DATE;
        _generation_start_date DATE;
        _generation_end_date DATE := CURRENT_DATE + INTERVAL '5 year';
    BEGIN
        SELECT MAX(full_date) INTO _max_existing_date FROM dim_date;

        IF _max_existing_date IS NULL THEN
            _generation_start_date := _initial_start_date;
        ELSE
            _generation_start_date := _max_existing_date + INTERVAL '1 day';
        END IF;

        IF _generation_start_date > _generation_end_date THEN
            RETURN;
        END IF;

        INSERT INTO dim_date (full_date, day, day_of_week, day_name, month, month_name, year)
        SELECT
            gs.generated_date,
            EXTRACT(DAY FROM gs.generated_date),
            (EXTRACT(DOW FROM gs.generated_date) + 6) % 7 + 1, -- Start from 1 for Monday
            CASE (EXTRACT(DOW FROM gs.generated_date) + 6) % 7 + 1
                WHEN 1 THEN 'Monday'
                WHEN 2 THEN 'Tuesday'
                WHEN 3 THEN 'Wednesday'
                WHEN 4 THEN 'Thursday'
                WHEN 5 THEN 'Friday'
                WHEN 6 THEN 'Saturday'
                WHEN 7 THEN 'Sunday'
                END AS day_name,
            EXTRACT(MONTH FROM gs.generated_date),
            CASE EXTRACT(MONTH FROM gs.generated_date)
                WHEN 1 THEN 'January'
                WHEN 2 THEN 'February'
                WHEN 3 THEN 'March'
                WHEN 4 THEN 'April'
                WHEN 5 THEN 'May'
                WHEN 6 THEN 'June'
                WHEN 7 THEN 'July'
                WHEN 8 THEN 'August'
                WHEN 9 THEN 'September'
                WHEN 10 THEN 'October'
                WHEN 11 THEN 'November'
                WHEN 12 THEN 'December'
                END AS month_name,
            EXTRACT(YEAR FROM gs.generated_date)
        FROM
            GENERATE_SERIES(_generation_start_date, _generation_end_date, '1 day'::interval) AS gs(generated_date)
        ON CONFLICT (full_date) DO NOTHING;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE EXCEPTION 'Error while populating dim_date: %', SQLERRM;
    END $$;