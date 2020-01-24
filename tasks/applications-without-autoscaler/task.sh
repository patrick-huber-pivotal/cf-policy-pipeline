#!/bin/bash

set -uex

source source-repo/scripts/init.sh
source source-repo/scripts/install-cf.sh
source source-repo/scripts/install-yq.sh

echo $EXCLUDE_ORGS