#!/bin/bash

$OSMOSIS_PATH/osmosis \
  --read-pbf file=$1 \
  --log-progress interval=30 \
  --write-apidb \
    host="$DB_HOST" \
    database="$DB_NAME" \
    user="$DB_USER" \
    password="$DB_PASS" \
    validateSchemaVersion="no"