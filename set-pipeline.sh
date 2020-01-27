#!/bin/bash

# get the current script directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


# set the pipeline
fly -t dell set-pipeline -c $DIR/pipeline.yml -p cf-policies -l $DIR/vars.yml