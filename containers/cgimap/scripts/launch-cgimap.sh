#! /bin/bash

##
# The configuration for the API server can be set using environment
# variables: CGIMAP_HOST, CGIMAP_DBNAME, CGIMAP_USERNAME,
# CGIMAP_PASSWORD, CGIMAP_PIDFILE, CGIMAP_LOGFILE, CGIMAP_MEMCACHE,
# CGIMAP_RATELIMIT and CGIMAP_MAXDEBT.
##

/usr/local/bin/openstreetmap-cgimap --port=3001 --instances=30