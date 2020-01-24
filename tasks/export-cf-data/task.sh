#!/bin/bash

set -uex

source source-repo/scripts/init.sh
source source-repo/scripts/install-cf.sh
source source-repo/scripts/install-yq.sh
source source-repo/scripts/install-jq.sh

export OUTPUT_DIR=cf-data

# login to cf api 
cf api $CF_TARGET --skip-ssl-validation
cf login -u $CF_USERNAME -p $CF_PASSWORD < /dev/null

cf curl /v3/organizations > $OUTPUT_DIR/orgs.json
cf curl /v3/apps > $OUTPUT_DIR/apps.json
cf curl /v2/service_instances > $OUTPUT_DIR/service-instances.json
cf curl /v2/service_bindings > $OUTPUT_DIR/service-bindings.json
cf curl /v2/service_plans > $OUTPUT_DIR/service-plans.json
cf curl /v2/services > $OUTPUT_DIR/services.json