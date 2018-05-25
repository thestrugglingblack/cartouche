#!/bin/bash

###
# Full alias for doing a streamed import using the Go utility.
#
# This could take a while, so you might want to run it in tmux,
# which should be installed on this container.
#
# Will put the entire stack into maintenance mode via a shared
# volume with nginx and provide a self-updating progress indicator
# at the main URL.
###

# In case the shared volume doesn't exist...
mkdir -p /usr/local/data/htdocs

cp $SCRIPT_PATH/templates/import.html /usr/local/data/htdocs/status.html

go run $SCRIPT_PATH/import.go -c=$SCRIPT_PATH/import-pbf.sh -i=$1 -b=${1:-0}

rm /usr/local/data/htdocs/status.html
rm $IMPORT_STAUS_FILE