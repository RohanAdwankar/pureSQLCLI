# Purely SQL Task Management CLI

## Features
- saves tasks in PostgreSQL
- neat table views
- easy and concise functions
    - List all tasks : SELECT * FROM list_tasks();

    - Add task: SELECT add_task(''task: YYYY-MM-DD'');

    - Complete task: SELECT complete_task(''task'');

    - Delete task: SELECT delete_task(''task'');

    - Search tasks: SELECT search_tasks(''term'');

    - Update task: SELECT update_task(''Old Task -> New Task: YYYY-MM-DD'');

    - Current week view: SELECT week();

    - Specific week view: SELECT week_view('YYY-MM-DD');

    - Quit: \q enter enter  

    - Enter to scroll downwards                                         

## How to Run:
1. Have psql (comes with PostgreSQL installer or you can use homebrew etc.)
2. Run: cat task.sql - | psql -d task_manager

## why was this made???
- to improve my SQL skills
- i needed a quick task manager
- i thought it would be funny to have a fully functional CLI entirely in SQL