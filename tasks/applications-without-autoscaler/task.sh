#!/bin/bash

set -uex

source source-repo/scripts/init.sh
source source-repo/scripts/install-cf.sh
source source-repo/scripts/install-yq.sh
source source-repo/scripts/install-jq.sh

cf api $CF_TARGET --skip-ssl-validation
cf login -u $CF_USERNAME -p $CF_PASSWORD < /dev/null
cf curl /v2/apps > apps.json
cat apps.json