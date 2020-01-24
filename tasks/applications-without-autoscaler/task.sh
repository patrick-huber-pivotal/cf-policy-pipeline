#!/bin/bash

set -uex

source source-repo/scripts/init.sh
source source-repo/scripts/install-sqlite.sh

export INPUT_DIR=database

cat > query.txt <<EOF
SELECT * 
FROM APPS a
LEFT JOIN SERVICE_BINDINGS sb
  on sb.APP_ID = a.ID
INNER JOIN SERVICE_INSTANCES si
  on si.ID = sb.SERVICE_INSTANCE_ID
INNER JOIN SERVICES s
  on  s.ID = si.SERVICE_ID
  and s.NAME = 'app-autoscaler'
WHERE sb.ID is null;
EOF

# run the query
sqlite3 $INPUT_DIR/database.db < query.txt 
exit 1