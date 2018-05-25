#!/bin/bash

###
# Create database.
###

set -e

$SCRIPT_PATH/set-state.sh "INITIALIZE"

# We're gonna cheat a bit here because we don't want to share the build
# context between the rails and postgis container paths.
BASE_URL="https://raw.githubusercontent.com"
REPO="openstreetmap/openstreetmap-website"
SHA="f1e9dcc66af1945cc0b8847b4ccecde9f54520ba"
wget $BASE_URL/$REPO/$SHA/db/structure.sql

psql -U postgres -c "CREATE DATABASE $DB_NAME;"

echo " * Loading schema..."

cat $SCRIPT_PATH/structure.sql | psql -U $DB_USER -d $DB_NAME

psql -U postgres -c "SHOW data_directory;"

$SCRIPT_PATH/set-state.sh "READY"