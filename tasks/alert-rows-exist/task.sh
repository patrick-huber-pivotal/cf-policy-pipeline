#!/bin/bash

set -ue

INPUT_DIR=results

# The count threshold. 
# If the count is greater than this number, alert by exiting with non zero
THRESHOLD=0

if [ "$SKIP_HEADER" == true ]; then
    THRESHOLD=1
fi

FILE_PATH=$INPUT_DIR/$FILE
if [ ! -f "$FILE_PATH"]; then
    >&2 echo "file $FILE_PATH does not exist"
    exit 1
fi

COUNT=$(wc -l < $FILE_PATH)
if [ $COUNT -gt $THRESHOLD ]; then
    >&2 echo "count $COUNT has exceeded the threshold $THRESHOLD"
    exit 1
fi

echo "count $COUNT is below threshold $THRESHOLD"
exit 1