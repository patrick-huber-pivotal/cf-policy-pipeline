#!/bin/bash

set -ue

export INPUT_DIR=database

echo ".headers on" > query.txt
echo "$QUERY" >> query.txt

# run the query
sqlite3 $INPUT_DIR/database.db < query.txt | column -t -n -s'|'
