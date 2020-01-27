#!/bin/bash

set -uex

source source-repo/scripts/init.sh
source source-repo/scripts/install-sqlite.sh

export INPUT_DIR=database

# run the query
sqlite3 $INPUT_DIR/database.db < echo $QUERY