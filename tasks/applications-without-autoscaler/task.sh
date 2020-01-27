#!/bin/bash

set -uex

source source-repo/scripts/init.sh
source source-repo/scripts/install-jq.sh
source source-repo/scripts/install-yq.sh
source source-repo/scripts/install-sqlite.sh

export INPUT_DIR=database
export ORGS=`echo $EXCLUDE_ORGS | yq r - --tojson | jq '. | @csv' -r`

cat > query.txt <<EOF
SELECT a.Name, sp.Name, o.Name 
FROM APPS a
LEFT JOIN SERVICE_BINDINGS sb
  on sb.APP_ID = a.ID
LEFT JOIN SERVICE_INSTANCES si
  on si.ID = sb.SERVICE_INSTANCE_ID
LEFT JOIN SERVICES s
  on  s.ID = si.SERVICE_ID
  and s.NAME = 'app-autoscaler'
LEFT JOIN SPACES sp
  on a.SPACE_ID = sp.ID
LEFT JOIN ORGANIZATIONS o
  on o.ID = sp.ORGANIZATION_ID
WHERE sb.ID is null
  and o.Name not in ($ORGS);
EOF

# run the query
sqlite3 $INPUT_DIR/database.db < query.txt 