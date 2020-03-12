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
cat $OUTPUT_DIR/apps.json | jq '.resources[].guid' -r | while read -r app
do
  cf curl /v2/apps/$app/summary >> $OUTPUT_DIR/app-summaries-temp.json
  cf curl /v3/apps/$app/routes | jq --arg app "$app" '{app: $app, route: .resources[].guid}' -r >> $OUTPUT_DIR/route-mappings-temp.json 
done  
jq -s . $OUTPUT_DIR/app-summaries-temp.json > $OUTPUT_DIR/app-summaries.json
jq -s . $OUTPUT_DIR/route-mappings-temp.json > $OUTPUT_DIR/route-mappings.json
rm $OUTPUT_DIR/app-summaries-temp.json
rm $OUTPUT_DIR/route-mappings-temp.json

export CF_OAUTH_TOKEN=$(cf oauth-token)
# loop over each space and query the autoscaler apps for that space
touch $OUTPUT_DIR/app-autoscalers-temp.json
cat $OUTPUT_DIR/spaces.json | jq '.resources[].guid' -r | while read -r space
do
   curl -k "https://autoscale.$CF_SYS_DOMAIN/api/v2/apps?space_guid=$space" \
        -H "Authorization: $CF_OAUTH_TOKEN" \
        | jq '.resources[] | .' >> $OUTPUT_DIR/app-autoscalers-temp.json
done
jq -s . $OUTPUT_DIR/app-autoscalers-temp.json > $OUTPUT_DIR/app-autoscalers.json
rm $OUTPUT_DIR/app-autoscalers-temp.json

# export app autoscaler information for each app
# loop over each app and pull its autoscaler rules

cat $OUTPUT_DIR/app-autoscalers.json | jq '.[].guid' -r | while read -r app
do
   curl -k "https://autoscale.$CF_SYS_DOMAIN/api/v2/apps/$app/rules" -H "Authorization: $CF_OAUTH_TOKEN" \
   | jq '.resources[]' >> $OUTPUT_DIR/app-autoscaler-rules-temp.json
done
jq -s . $OUTPUT_DIR/app-autoscaler-rules-temp.json >> $OUTPUT_DIR/app-autoscaler-rules.json
rm $OUTPUT_DIR/app-autoscaler-rules-temp.json

