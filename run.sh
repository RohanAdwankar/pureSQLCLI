#!/bin/bash

psql -d task_manager -f task.sql

psql -d task_manager \
    -P pager=off \
    -P null='(null)' \
    -P footer=off \
    --set PROMPT1='task_manager> ' \
    --set QUIET=1