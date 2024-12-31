# Pure SQL Task Management CLI
![demo](https://github.com/user-attachments/assets/dff94cf2-86cd-4624-aabb-d2d8a70b58c7)
## Features
### View Tasks
    - View all tasks : SELECT * FROM list_tasks();

    - Current week view: SELECT week();

    - Specific week view: SELECT week('YYYY-MM-DD');

    - Current month view: SELECT month();

    - Specific month view: SELECT month('YYYY-MM-DD');

    - Search tasks: SELECT search('term');

    - See stats and a burndown chart: SELECT stat();

### Edit Tasks
    - Add task: SELECT add('task: YYYY-MM-DD');

    - Complete task: SELECT done('task');

    - Delete task: SELECT delete('task');

    - Update task: SELECT change('Old Task -> New Task: YYYY-MM-DD');

### General Editor Commands
    - Quit: \q enter enter  

    - Scroll Downwards: enter                                         

## Installation:
1. Install psql (comes with PostgreSQL or you can use homebrew etc.)
2. ```git clone https://github.com/RohanAdwankar/pureSQLCLI.git```
3. ```cat pureSQLCLI/task.sql - | psql -d task_manager```

## why was this made???
- i wanted to improve my sql fluency as in the past ive only written small queries. well to learn a new language i usually make a CLI. so I guess SQL is no exception :)
- i needed a quick task manager that didn't have all the excess features and bloat
- i thought it would be funny to have a fully functional CLI entirely in SQL

## next steps
- i added all the features i needed but if you want something else feel free to open an issue and ill get to it!
