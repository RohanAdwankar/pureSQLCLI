# Purely SQL Task Management CLI

## Features
### View Tasks
    - View all tasks : SELECT * FROM list_tasks();

    - Current week view: SELECT week();

    - Specific week view: SELECT week('YYYY-MM-DD');

    - Current month view: SELECT month();

    - Specific month view: SELECT month('YYYY-MM-DD');

    - Search tasks: SELECT search('term');

### Edit Tasks
    - Add task: SELECT add('task: YYYY-MM-DD');

    - Complete task: SELECT done('task');

    - Delete task: SELECT delete('task');

    - Update task: SELECT change('Old Task -> New Task: YYYY-MM-DD');

### General Editor Commands
    - Quit: \q enter enter  

    - Scroll Downwards: enter                                         

## Installation:
1. Install psql (comes with PostgreSQL installer or you can use homebrew etc.)
2. ```git clone https://github.com/RohanAdwankar/pureSQLCLI.git```
3. ```cat pureSQLCLI/task.sql - | psql -d task_manager```

## why was this made???
- to improve my SQL skills
- i needed a quick task manager
- i thought it would be funny to have a fully functional CLI entirely in SQL