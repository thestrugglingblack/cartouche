# !/bin/bash

set -e

touch $PGLOGS
chown -R postgres $PGLOGS

# Restore from backup, attach an existing volume, or create a new one.
if [ -z "$(ls -A $PGDATA)" ]; then
	echo " * Initializing data cluster in $PGDATA..."
	$PGPATH/initdb --pgdata=$PGDATA
	$SCRIPT_PATH/pg-start.sh
	$SCRIPT_PATH/pg-create.sh

else
	echo " * Attaching to existing data cluster..."
fi

chown -R postgres $PGDATA
chmod -R 700 $PGDATA

echo " * Starting database server..."

# Add data directory to conf, because pg_ctl ignores the -D flag if we pass
# a configuration file, which we need for allowing all hosts.
echo "data_directory = '$PGDATA'" >> $SCRIPT_PATH/conf/pg_hba.conf.base

# Access controls.
echo "" >> $(dirname $PGCONF)/pg_hba.conf
echo "host all all all md5" >> $(dirname $PGCONF)/pg_hba.conf

$SCRIPT_PATH/pg-start.sh

psql -U postgres -c "ALTER USER $DB_USER WITH PASSWORD '$DB_PASS';"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

$SCRIPT_PATH/install-libpgosm.sh

echo "DB ready."

tail -f $PGLOGS