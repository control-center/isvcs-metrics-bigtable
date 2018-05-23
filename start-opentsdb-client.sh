#!/bin/bash

##
# Start an opentsdb client.
#

# Supervisord restarts processes by sending a SIGTERM (by default).
# Handle signals, and kill subprocesses so we don't have orphaned processes
# proliferating on each restart
trap "kill 0" SIGINT SIGTERM EXIT


mkdir -p /tmp/tsd


true ${OPENTSDB_RESOURCE:=/usr/local/serviced/resources/opentsdb}

# Overwrite the default metric consumer config if available
if [ -e "$OPENTSDB_RESOURCE/metric-consumer-app/configuration.yaml" ]; then
    cp $OPENTSDB_RESOURCE/metric-consumer-app/configuration.yaml /opt/zenoss/etc/metric-consumer-app/configuration.yaml
fi

# Overwrite the default open tsdb config if available
if [ -e "$OPENTSDB_RESOURCE/opentsdb.conf" ]; then
    cp $OPENTSDB_RESOURCE/opentsdb.conf /opt/zenoss/etc/opentsdb/opentsdb.conf
fi

if [ -f "$OPENTSDB_RESOURCE/otsdb.env" ]; then
    . "$OPENTSDB_RESOURCE/otsdb.env"
fi


# start opentsdb
export JVMARGS="${TSDB_JAVA_MEM_MB} -XX:+ExitOnOutOfMemoryError -enableassertions -enablesystemassertions"

exec /opt/opentsdb/build/tsdb tsd --config /opt/zenoss/etc/opentsdb/opentsdb.conf
