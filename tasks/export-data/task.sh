#!/bin/bash

set -uex

export OUTPUT_DIR=cf-data

# login to cf api 
cf api $CF_TARGET --skip-ssl-validation
cf login -u $CF_USERNAME -p $CF_PASSWORD < /dev/null

cf curl /v3/organizations > $OUTPUT_DIR/orgs.json
cf curl /v3/spaces > $OUTPUT_DIR/spaces.json
cf curl /v3/apps > $OUTPUT_DIR/apps.json
cf curl /v3/domains > $OUTPUT_DIR/domains.json
cf curl /v3/routes > $OUTPUT_DIR/routes.json
cf curl /v2/service_instances > $OUTPUT_DIR/service-instances.json
cf curl /v2/service_bindings > $OUTPUT_DIR/service-bindings.json
cf curl /v2/service_plans > $OUTPUT_DIR/service-plans.json
cf curl /v2/services > $OUTPUT_DIR/services.json
om curl --path /api/v0/deployed/certificates > $OUTPUT_DIR/certificates.json
om curl --path /api/v0/certificate_authorities > $OUTPUT_DIR/certificate_authorities.json

# export app summary data for each app
# export route mappings for each app
count=0
echo "[" > $OUTPUT_DIR/app-summaries.json
cat $OUTPUT_DIR/apps.json | jq '.resources[].guid' -r | while read -r app
do
  if [[ "$count" -gt 0 ]]; then
    echo "," >> $OUTPUT_DIR/app-summaries.json
  fi
  cf curl /v2/apps/$app/summary >> $OUTPUT_DIR/app-summaries.json
  cf curl /v3/apps/$app/routes | jq --arg app $app '{app: $app", route: .resources[].guid}' -r >> $OUTPUT_DIR/mapped-routes-temp.json 
  ((count = count + 1)) || true 
done  
echo "]" >> $OUTPUT_DIR/app-summaries.json
jq -s . $OUTPUT_DIR/mapped-routes-temp.json > $OUTPUT_DIR/mapped-routes.json
rm $OUTPUT_DIR/mapped-routes-temp.json
