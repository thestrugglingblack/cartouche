# !/bin/bash

# Wait until postgis is ready before trying to import things.
while [ -z "$(nmap -p 5432 postgis | grep "open")" ]; do
	sleep 1
done

# Then just hang out as a utility container.
# Minutely replication used to live here but has been disabled for this
# release.
tail -f /dev/null