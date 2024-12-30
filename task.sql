\set QUIET 1
\pset footer off
\pset null '(null)'
\pset pager off

-- create tables if dne
DO $$ 
BEGIN
    -- task_status type
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_status') THEN
        CREATE TYPE task_status AS ENUM ('pending', 'completed');
    END IF;
    
    -- tasks table
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

-- welcome
\echo '\n=== Task Manager ==='
\echo 'Commands:'
\echo '  SELECT * FROM list_tasks();           - List all tasks'
\echo '  SELECT add_task(''task: YYYY-MM-DD'');  - Add task'
\echo '  SELECT complete_task(''task'');         - Complete task'
\echo '  \q                                    - Quit'
\echo '\nExample usage:'
\echo '  SELECT add_task(''Buy groceries: 2024-12-24'');'
\echo '  SELECT complete_task(''Buy groceries'');'
\echo '\nCurrent tasks:'

SELECT * FROM list_tasks();