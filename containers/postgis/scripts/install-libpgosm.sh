# !/bin/bash

set -e

echo " * Installing libpgosm extensions..."

psql -U postgres <<- SQL
	CREATE EXTENSION IF NOT EXISTS btree_gist;
	CREATE OR REPLACE FUNCTION maptile_for_point(int8, int8, int4)
		RETURNS int4 AS '$PATH_LIBPGOSM/libpgosm',
		'maptile_for_point' LANGUAGE C STRICT;
	CREATE OR REPLACE FUNCTION tile_for_point(int4, int4)
		RETURNS int8 AS '$PATH_LIBPGOSM/libpgosm',
		'tile_for_point' LANGUAGE C STRICT;
	CREATE OR REPLACE FUNCTION xid_to_int4(xid)
		RETURNS int4 AS '$PATH_LIBPGOSM/libpgosm',
		'xid_to_int4' LANGUAGE C STRICT;
SQL