#!/bin/bash

set -e

# The upstream repo has some optional toggles for configuration meant to
# balance import performance with backups, which we don't need for a local
# stack.
BASECONF=$SCRIPT_PATH/conf/pg_hba.conf.base
cat $BASECONF > $PGCONF


# The stop command will exit with an error code if the server isn't running,
#  which we can safely ignore.
$PGPATH/pg_ctl -w stop 2> /dev/null || true

$PGPATH/pg_ctl -o '--config-file=$PGCONF' -w -D $PGDATA -l $PGLOGS start