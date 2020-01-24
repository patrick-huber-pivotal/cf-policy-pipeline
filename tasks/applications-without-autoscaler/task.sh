#!/bin/bash

set -uex

source source-repo/scripts/init.sh
source source-repo/scripts/install-cf.sh
source source-repo/scripts/install-yq.sh
source source-repo/scripts/install-jq.sh

# login to cf api 
cf api $CF_TARGET --skip-ssl-validation
cf login -u $CF_USERNAME -p $CF_PASSWORD < /dev/null

# get autoscaler guid
cf curl /v2/services > services.json 
export AUTOSCALER_GUID = `cat services.json | jq '.resources[] | select(.entity.label == "app-autoscaler") | .metadata.guid' -r`

# get service plan for service (usually only one)
cf curl /v2/services/$AUTOSCALER_GUID/service_plans > autoscaler_service_plans.json
export AUTOSCALER_SERVICE_PLAN_GUID=`cat data/autoscaler_service_plans.json | jq .resources[0].metadata.guid -r`

# get all service instances for the autoscaler plan
cf curl /v2/service_plans/$AUTOSCALER_SERVICE_PLAN_GUID/service_instances > autoscaler_service_instances.json

# get all service bindings
cf curl /v2/service_bindings > service_bindings.json

# get orgs
cf curl /v2/orgs > orgs.json

# write the org exclusion as json
echo $EXCLUDE_ORGS | yq r --to-json > exclude_orgs.json

# get list of org guids filtered by exclusion list
# form a comma delimited list for the organization_guids query parameter
export ORGANIZATION_GUIDS=`cat orgs.json \
| jq --slurpfile filter exclude_orgs.json \
'[.resources[] | select( .name as $name | $filter[] | index($name) | not )] | [.[].guid] | join(",")' \
-r`

# use the list of org guids to filter the app list
cf curl /v3/apps?organization_guids=$ORGANIZATION_GUIDS > apps.json

# form a query :
## SELECT * 
## FROM APPS a
## LEFT JOIN ServiceBindings sb
##   on sb.AppId = a.AppId
## INNER JOIN ServiceInstances si
##   on si.ServiceInstanceId = sb.ServiceInstanceId
## INNER JOIN ServicePlans sp
##   on sp.ServicePlanId = si.ServicePlanId
## INNER JOIN Services s
##   on s.ServiceId = sp.ServiceId
## WHERE a.OrgId not in
## ( 
##   SELECT OrgId 
##   FROM Organizations
##   WHERE Name not in ("system")
## ) 
## and s.ServiceName = 'app-autoscaler'
## and sb.ServiceBindingId is null