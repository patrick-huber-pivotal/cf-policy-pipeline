#!/bin/bash

set -uex

export INPUT_DIR=database

echo ".headers on" > query.txt
echo $QUERY >> query.txt

# run the query
sqlite3 $INPUT_DIR/database.db < query.txt 