#!/bin/bash

set -ue

export INPUT_DIR=database

echo ".headers on" > query.txt
echo "$QUERY" >> query.txt

# run the query save the output as a csv file
sqlite3 $INPUT_DIR/database.db < query.txt > results/report.csv
cat results/report.txt | column -t -n -s'|' > results/report.txt
cat results/report.txt
exit 1
