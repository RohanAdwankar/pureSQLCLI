\set QUIET 1
\pset footer off
\pset null '(null)'
\pset pager off

DROP FUNCTION IF EXISTS week();

-- create tables if dne
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_status') THEN
        CREATE TYPE task_status AS ENUM ('pending', 'completed');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'tasks') THEN
        CREATE TABLE tasks (
            id SERIAL PRIMARY KEY,
            title TEXT NOT NULL,
            deadline DATE,
            status task_status DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        -- examples
        INSERT INTO tasks (title, deadline) VALUES
            ('Setup development environment', '2024-12-25'),
            ('Write documentation', '2024-12-31');
    END IF;
END
$$;

-- view
CREATE OR REPLACE VIEW tasks_view AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY status, deadline) as "#",
    title,
    deadline,
    status,
    CASE 
        WHEN deadline < CURRENT_DATE AND status != 'completed' 
        THEN '(OVERDUE)' 
        ELSE ''
    END as notes
FROM tasks 
ORDER BY 
    CASE status WHEN 'pending' THEN 0 ELSE 1 END,
    deadline;

-- functions
-- Weekly view
CREATE OR REPLACE FUNCTION week() RETURNS TEXT AS $$
DECLARE
    start_of_week DATE;
    end_of_week DATE;
    result TEXT;
    row_data TEXT[];
    max_tasks INTEGER := 0;
BEGIN
    start_of_week := current_date - EXTRACT(DOW FROM current_date - 1)::INTEGER;
    end_of_week := start_of_week + 6;

    result := E'\n';
    result := result || E'+------------+------------+------------+------------+------------+------------+------------+\n';
    result := result || E'|   Monday   |  Tuesday   | Wednesday  |  Thursday  |   Friday   |  Saturday  |   Sunday   |\n';
    result := result || E'+------------+------------+------------+------------+------------+------------+------------+\n';

    SELECT COALESCE(MAX(task_count), 0) INTO max_tasks
    FROM (
        SELECT COUNT(*) as task_count
        FROM tasks
        WHERE deadline BETWEEN start_of_week AND end_of_week
        GROUP BY DATE(deadline)
    ) counts;

    FOR i IN 1..GREATEST(max_tasks, 1) LOOP
        SELECT array_agg(COALESCE(task_text, '            '))
        INTO row_data
        FROM (
            SELECT 
                day,
                MAX(CASE 
                    WHEN task_num = i THEN
                        CASE 
                            WHEN t.status = 'completed' THEN 
                                RPAD('[✓] ' || substring(t.title, 1, 7), 12, ' ')
                            ELSE 
                                RPAD('[ ] ' || substring(t.title, 1, 7), 12, ' ')
                        END
                    ELSE NULL
                END) as task_text
            FROM generate_series(start_of_week, end_of_week, '1 day'::interval) day
            LEFT JOIN (
                SELECT 
                    title,
                    status,
                    deadline,
                    ROW_NUMBER() OVER (PARTITION BY deadline ORDER BY created_at) as task_num
                FROM tasks
                WHERE deadline BETWEEN start_of_week AND end_of_week
            ) t ON DATE(t.deadline) = day
            GROUP BY day
            ORDER BY day
        ) daily_tasks;

        result := result || '|' || array_to_string(row_data, '|') || E'|\n';
    END LOOP;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION list_tasks() RETURNS SETOF tasks_view AS $$
BEGIN
    RETURN QUERY SELECT * FROM tasks_view;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_task(task_desc TEXT) RETURNS SETOF tasks_view AS $$
DECLARE
    title_part TEXT;
    date_part TEXT;
BEGIN
    title_part := split_part(task_desc, ':', 1);
    date_part := trim(split_part(task_desc, ':', 2));
    
    INSERT INTO tasks (title, deadline) 
    VALUES (trim(title_part), date_part::DATE);
    
    RAISE NOTICE 'Added: % (due: %)', trim(title_part), date_part;
    RETURN QUERY SELECT * FROM tasks_view;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION complete_task(task_title TEXT) RETURNS SETOF tasks_view AS $$
BEGIN
    UPDATE tasks SET status = 'completed' 
    WHERE title ILIKE task_title 
    AND status = 'pending';
    
    IF FOUND THEN
        RAISE NOTICE 'Completed: %', task_title;
    ELSE
        RAISE NOTICE 'No pending task found: %', task_title;
    END IF;

    RETURN QUERY SELECT * FROM tasks_view;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_task(task_title TEXT) RETURNS SETOF tasks_view AS $$
BEGIN
    DELETE FROM tasks 
    WHERE title ILIKE task_title;
    
    IF FOUND THEN
        RAISE NOTICE 'Deleted: %', task_title;
    ELSE
        RAISE NOTICE 'No task found: %', task_title;
    END IF;

    RETURN QUERY SELECT * FROM tasks_view;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION search_tasks(search_term TEXT) RETURNS SETOF tasks_view AS $$
BEGIN
    RETURN QUERY 
    SELECT * FROM tasks_view 
    WHERE title ILIKE '%' || search_term || '%';

    IF NOT FOUND THEN
        RAISE NOTICE 'No tasks found matching: %', search_term;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_task(task_desc TEXT) RETURNS SETOF tasks_view AS $$
DECLARE
    title_part TEXT;
    date_part TEXT;
    old_title TEXT;
    new_title TEXT;
BEGIN
    old_title := split_part(task_desc, ' -> ', 1);
    title_part := split_part(task_desc, ' -> ', 2);
    
    IF title_part = '' THEN
        RAISE EXCEPTION 'Usage: update_task(''Old Title -> New Title: YYYY-MM-DD'')';
    END IF;
    
    new_title := split_part(title_part, ':', 1);
    date_part := trim(split_part(title_part, ':', 2));
    
    UPDATE tasks 
    SET title = trim(new_title),
        deadline = date_part::DATE
    WHERE title ILIKE old_title;
    
    IF FOUND THEN
        RAISE NOTICE 'Updated: % -> % (due: %)', old_title, new_title, date_part;
    ELSE
        RAISE NOTICE 'No task found: %', old_title;
    END IF;

    RETURN QUERY SELECT * FROM tasks_view;
END;
$$ LANGUAGE plpgsql;

-- welcome
\echo '\n=== Task Manager ==='
\echo 'Commands:'
\echo '  SELECT * FROM list_tasks();                              - List all tasks'
\echo '  SELECT add_task(''task: YYYY-MM-DD'');                     - Add task'
\echo '  SELECT complete_task(''task'');                            - Complete task'
\echo '  SELECT delete_task(''task'');                             - Delete task'
\echo '  SELECT search_tasks(''term'');                            - Search tasks'
\echo '  SELECT update_task(''Old Task -> New Task: YYYY-MM-DD''); - Update task'
\echo '  \\q enter enter                                           - Quit'
\echo '\nExample usage:'
\echo '  SELECT add_task(''Buy groceries: 2024-12-24'');'
\echo '  SELECT complete_task(''Buy groceries'');'
\echo '  SELECT search_tasks(''groceries'');'
\echo '  SELECT update_task(''Buy groceries -> Buy food: 2024-12-25'');'
\echo '\nCurrent tasks:'

SELECT * FROM list_tasks();