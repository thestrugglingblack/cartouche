#!/bin/bash

###
# Uploads the current state of a long-running import to a persistent volume so
# that it can be resumed after cycling.
#
# Arguments:
#
#     - location: full URL or filepath of the file being imported
#     - startByte: byte position of the next block to be imported
#
# The server will check for the import status file when booting. If the file
# exists, the import will be resumed from that point automatically.
###

echo "$1	$2" > $IMPORT_STAUS_FILE