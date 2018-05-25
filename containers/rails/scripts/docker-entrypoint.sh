# !/bin/bash

echo "Waiting for database connection..."

# Wait for the postgres server to spin up.
until PGPASSWORD=$DB_PASS psql -h $DB_HOST -U \
      $DB_USER -d development -c "SHOW data_directory;"
do
	sleep ${POLL_TIMER:=15}
done

rails db:migrate
rails s -p 3000 -b 0.0.0.0