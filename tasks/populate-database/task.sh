#!/bin/bash

source source-repo/scripts/init.sh
source source-repo/scripts/install-sqlite.sh
source source-repo/scripts/install-yq.sh
source source-repo/scripts/install-jq.sh

export OUTPUT_DIR=database
export INPUT_DIR=cf-data

# Create Database
sqlite3 -cmd '.databases' $OUTPUT_DIR/database.db

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
    NAME                    TEXT        NOT NULL,
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
touch $INPUT_DIR/service_instances.csv
touch $INPUT_DIR/service_plans.csv
touch $INPUT_DIR/service_bindings.csv

# populate database
cat > bulk_insert.txt <<EOF
.separator |
.import $INPUT_DIR/apps.csv APPS
.import $INPUT_DIR/services.csv SERVICES
.import $INPUT_DIR/service_instances.csv SERVICE_INSTANCES
.import $INPUT_DIR/service_plans.csv SERVICE_PLANS
.import $INPUT_DIR/orgs.csv ORGANIZATIONS
.import $INPUT_DIR/service_bindings.csv SERVICE_BINDINGS
EOF

sqlite3 $OUTPUT_DIR/database.db < bulk_insert.txt

sqllite3 -cmd 'SELECT * FROM APPS; SELECT* FROM ORGANIZATIONS; SELECT * FROM SERVICES;' $OUTPUT_DIR/database.db