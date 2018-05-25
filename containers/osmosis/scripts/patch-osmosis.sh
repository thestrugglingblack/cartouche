#!/bin/bash

###
# Clone the osmosis repository and patch it with an ON CONFLICT DO NOTHING
# clause to INSERT statements so that an import can be resumed without a
# fatal error.
#
# The alternative approach would be truncating a DenseNodes block from the
# PBF binary format.  DenseNodes are delta encoded and made up of packed
# varint fields so it'd be an annoying exercise.
#
# With this, we can just rerun the entire last block and have Postgres skip
# any nodes that have already been processed.
###

BUILD_PATH=$(cd $OSMOSIS_PATH && cd ../ && pwd)
OSMOSIS_SRC=/usr/local/src/osmosis

APIDBWRITER=osmosis-apidb/src/main/java/org/openstreetmap/osmosis/apidb/v0_6/ApidbWriter.java

# --
# Git checkout is commented out because we're using more explicit submodules for
# this release.
# --
#
#git clone https://github.com/openstreetmap/osmosis.git $OSMOSIS_SRC
#(cd $OSMOSIS_SRC && git checkout 2219470cef1f73f5d1319c57149c84b398e767c)

patch $OSMOSIS_SRC/$APIDBWRITER -i $SCRIPT_PATH/osmosis_ApidbWriter_patch.diff

echo "Patched $OSMOSIS_SRC/$APIDBWRITER"

echo "Rebuilding osmosis..."

(cd $OSMOSIS_SRC && $OSMOSIS_SRC/gradlew assemble)

mkdir -p $BUILD_PATH

TARBALL=osmosis--SNAPSHOT.tgz

cp $OSMOSIS_SRC/package/build/distribution/$TARBALL $BUILD_PATH
(cd $BUILD_PATH && tar -xvf $TARBALL && rm $TARBALL)