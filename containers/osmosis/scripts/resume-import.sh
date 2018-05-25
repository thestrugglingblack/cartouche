#!/bin/bash

###
# Check to see if there's an active import by looking for the state
# file in the persistent volume.
#
# The state file is just a text file with the location of the PBF and the
# start byte of the next block to process.
###

# If there's no import status file, there's no import to resume.
if [ ! -f $IMPORT_STATUS_FILE ]; then
	exit 0
fi

PBF_LOC=$(cat $IMPORT_STAUS_FILE | cut -f1)
BLOCK_START=$(cat $IMPORT_STAUS_FILE | cut -f2)

echo "Resuming file $PBF_LOC at byte $BLOCK_START"

$SCRIPT_PATH/streamed-import.sh $PBF_LOC $BLOCK_START