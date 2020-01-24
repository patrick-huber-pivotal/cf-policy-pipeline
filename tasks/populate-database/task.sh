#!/bin/bash

set -uex

source source-repo/scripts/init.sh
source source-repo/scripts/install-sqlite.sh
source source-repo/scripts/install-yq.sh
source source-repo/scripts/install-jq.sh

export OUTPUT_DIR=database
export INPUT_DIR=cf-data

# Create Database
sqlite3 -cmd '.databases' $OUTPUT_DIR/database.db </dev/null

cat > commands.txt <<EOF
CREATE TABLE APPS(
    ID      CHAR(37)    NOT NULL    PRIMARY KEY,
    NAME    TEXT        NOT NULL
);

CREATE TABLE SERVICES(
    ID      CHAR(37)    NOT NULL    PRIMARY KEY,
    NAME    TEXT        NOT NULL
);

CREATE TABLE SERVICE_INSTANCES(
    ID          CHAR(37)    NOT NULL    PRIMARY KEY,
    NAME        TEXT        NOT NULL,
    SERVICE_ID  CHAR(37)    NOT NULL
);

CREATE TABLE SERVICE_PLANS(
    ID          CHAR(37)    NOT NULL    PRIMARY KEY,
    NAME        TEXT        NOT NULL,
    SERVICE_ID  CHAR(37)    NOT NULL
);

CREATE TABLE ORGANIZATIONS(
    ID      CHAR(37)    NOT NULL    PRIMARY KEY,
    NAME    TEXT        NOT NULL
);

CREATE TABLE SERVICE_BINDINGS(
    ID                      CHAR(37)    NOT NULL    PRIMARY KEY,
    APP_ID                  CHAR(37)    NOT NULL,
    SERVICE_INSTANCE_ID     CHAR(37)    NOT NULL 
);
EOF

# Create Schema
sqlite3 $OUTPUT_DIR/database.db < commands.txt

# create csv files
cat $INPUT_DIR/apps.json | jq '.resources[] | .guid+"|"+.name' -r > $INPUT_DIR/apps.csv
cat $INPUT_DIR/orgs.json | jq '.resources[] | .guid+"|"+.name' -r > $INPUT_DIR/orgs.csv
cat $INPUT_DIR/services.json | jq '.resources[] | .metadata.guid+"|"+.entity.label' -r > $INPUT_DIR/services.csv
cat $INPUT_DIR/service-plans.json | jq '.resources[] | .metadata.guid+"|"+.entity.name+"|"+.entity.service_guid' -r > $INPUT_DIR/service-plans.csv
cat $INPUT_DIR/service-instances.json | jq '.resources[] | .metadata.guid+"|"+.entity.name+"|"+.entity.service_guid' -r > $INPUT_DIR/service-instances.csv
cat $INPUT_DIR/service-bindings.json | jq '.resources[] | .metadata.guid+"|"+.entity.app_guid+"|"+.entity.service_instance_guid' -r > $INPUT_DIR/service-bindings.csv

# populate database
cat > bulk_insert.txt <<EOF
.separator |
.import $INPUT_DIR/apps.csv APPS
.import $INPUT_DIR/services.csv SERVICES
.import $INPUT_DIR/service-instances.csv SERVICE_INSTANCES
.import $INPUT_DIR/service-plans.csv SERVICE_PLANS
.import $INPUT_DIR/orgs.csv ORGANIZATIONS
.import $INPUT_DIR/service-bindings.csv SERVICE_BINDINGS
EOF

sqlite3 $OUTPUT_DIR/database.db < bulk_insert.txt