#!/bin/bash

set -uex

export OUTPUT_DIR=database
export INPUT_DIR=cf-data

# Create Database
sqlite3 -cmd '.databases' $OUTPUT_DIR/database.db </dev/null

cat > commands.txt <<EOF
CREATE TABLE APPS(
    ID          CHAR(37)    NOT NULL    PRIMARY KEY,
    NAME        TEXT        NOT NULL,
    SPACE_ID    CHAR(37)    NOT NULL
);

CREATE TABLE SPACES(
    ID              CHAR(37)    NOT NULL    PRIMARY KEY,
    NAME            TEXT        NOT NULL,
    ORGANIZATION_ID CHAR(37)    NOT NULL
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

CREATE TABLE ORGANIZATION_ANNOTATIONS(
    ORGANIZATION_ID     CHAR(37)	NOT NULL,
    KEY                 TEXT            NOT NULL,
    VALUE               TEXT            NOT NULL
);

CREATE TABLE ORGANIZATION_LABELS(
    ORGANIZATION_ID     CHAR(37)	NOT NULL,
    KEY                 TEXT            NOT NULL,
    VALUE               TEXT            NOT NULL
);

CREATE TABLE SERVICE_BINDINGS(
    ID                      CHAR(37)    NOT NULL    PRIMARY KEY,
    APP_ID                  CHAR(37)    NOT NULL,
    SERVICE_INSTANCE_ID     CHAR(37)    NOT NULL 
);

CREATE TABLE CERTIFICATES(
    PRODUCT_ID		CHAR(37)	NOT NULL,
    VARIABLE_PATH	TEXT		NOT NULL,
    VALID_FROM		TEXT,
    VALID_UNTIL	TEXT,
    PROPERTY_REFERENCE	TEXT

);

CREATE TABLE CERTIFICATE_AUTHORITIES(
    ID                 CHAR(37) 	NOT NULL,
    ISSUER		TEXT,
    CREATED_ON		TEXT,
    EXPIRES_ON		TEXT,
    ACTIVE		INTEGER
);
EOF

# Create Schema
sqlite3 $OUTPUT_DIR/database.db < commands.txt

# create csv files
cat $INPUT_DIR/apps.json | jq '.resources[] | .guid+"|"+.name+"|"+.relationships.space.data.guid' -r > $INPUT_DIR/apps.csv
cat $INPUT_DIR/spaces.json | jq '.resources[] | .guid+"|"+.name+"|"+.relationships.organization.data.guid' -r > $INPUT_DIR/spaces.csv
cat $INPUT_DIR/orgs.json | jq '.resources[] | .guid+"|"+.name' -r > $INPUT_DIR/orgs.csv
eat $INPUT_DIR/orgs.json | jq '.resources[] | . as $parent | .metadata.labels | to_entries | select((. | length) > 0) | .[] | $parent.guid + "|" + .key + "|" + .value ' -r > $INPUT_DIR/org_labels.csv
eat $INPUT_DIR/orgs.json | jq '.resources[] | . as $parent | .metadata.annotations | to_entries | select((. | length) > 0) | .[] | $parent.guid + "|" + .key + "|" + .value ' -r > $INPUT_DIR/org_annotations.csv
cat $INPUT_DIR/services.json | jq '.resources[] | .metadata.guid+"|"+.entity.label' -r > $INPUT_DIR/services.csv
cat $INPUT_DIR/service-plans.json | jq '.resources[] | .metadata.guid+"|"+.entity.name+"|"+.entity.service_guid' -r > $INPUT_DIR/service-plans.csv
cat $INPUT_DIR/service-instances.json | jq '.resources[] | .metadata.guid+"|"+.entity.name+"|"+.entity.service_guid' -r > $INPUT_DIR/service-instances.csv
cat $INPUT_DIR/service-bindings.json | jq '.resources[] | .metadata.guid+"|"+.entity.app_guid+"|"+.entity.service_instance_guid' -r > $INPUT_DIR/service-bindings.csv
cat $INPUT_DIR/certificates.json | jq '.certificates[] | .product_guid+"|"+.variable_path+"|"+.valid_from+"|"+.valid_until+"|"+.property_reference' -r > $INPUT_DIR/certificates.csv
cat $INPUT_DIR/certificate_authorities.json | jq '.certificate_authorities[] | .guid + "|" + .issuer + "|" + .created_on + "|" + .expires_on + "|" + (.active | tostring)' > $INPUT_DIR/certificate_authorities.csv

# populate database
cat > bulk_insert.txt <<EOF
.separator |
.import $INPUT_DIR/apps.csv APPS
.import $INPUT_DIR/spaces.csv SPACES
.import $INPUT_DIR/services.csv SERVICES
.import $INPUT_DIR/service-instances.csv SERVICE_INSTANCES
.import $INPUT_DIR/service-plans.csv SERVICE_PLANS
.import $INPUT_DIR/orgs.csv ORGANIZATIONS
.import $INPUT_DIR/org_labels.csv ORGANIZATION_LABELS
.import $INPUT_DIR/org_annotations.csv ORGANIZATION_ANNOTATIONS
.import $INPUT_DIR/service-bindings.csv SERVICE_BINDINGS
.import $INPUT_DIR/certificates.csv CERTIFICATES
.import $INPUT_DIR/certificate_authorities.csv CERTIFICATE_AUTHORITIES
EOF

sqlite3 $OUTPUT_DIR/database.db < bulk_insert.txt
