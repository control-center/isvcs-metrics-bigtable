FROM openjdk:8-jdk

RUN apt-get update && apt-get install -y autoconf make unzip gnuplot curl git && \
    curl -f http://storage.googleapis.com/cloud-bigtable/hbase-dist/hbase-1.2.1/hbase-1.2.1-bin.tar.gz | tar zxf -  && \
    mkdir -p hbase-1.2.1/lib/bigtable && \
    curl http://repo1.maven.org/maven2/com/google/cloud/bigtable/bigtable-hbase-1.2/0.9.5.1/bigtable-hbase-1.2-0.9.5.1.jar \
      -f -o hbase-1.2.1/lib/bigtable/bigtable-hbase-1.2-0.9.5.1.jar && \
    curl http://repo1.maven.org/maven2/io/netty/netty-tcnative-boringssl-static/1.1.33.Fork19/netty-tcnative-boringssl-static-1.1.33.Fork19.jar \
      -f -o hbase-1.2.1/lib/netty-tcnative-boringssl-static-1.1.33.Fork19.jar && \
    echo 'export HBASE_CLASSPATH="$HBASE_HOME/lib/bigtable/bigtable-hbase-1.2-0.9.5.1.jar:$HBASE_HOME/lib/netty-tcnative-boringssl-static-1.1.33.Fork19.jar"' >> /hbase-1.2.1/conf/hbase-env.sh && \
    echo 'export HBASE_OPTS="${HBASE_OPTS} -Xms1024m -Xmx2048m"' >> /hbase-1.2.1/conf/hbase-env.sh

RUN git clone --depth 1 --single-branch --branch v2.3.0 https://github.com/OpenTSDB/opentsdb.git && \
    rm -rf /opentsdb/tools/docker && \
    mkdir -p /opentsdb/build/ && \
    echo "updating to use 0.3.0 of asyncbigtable" && \
    echo "4384ac07967ee99f54d4c29f9806d7e7" > /opentsdb/third_party/asyncbigtable/asyncbigtable-0.3.0-jar-with-dependencies.jar.md5 && \
    sed -i 's/0.2.1-20160228.235952-3/0.3.0/g' /opentsdb/third_party/asyncbigtable/include.mk && \
    sed -i 's|snapshots/com/pythian/opentsdb/asyncbigtable/0.2.1-SNAPSHOT/|releases/com/pythian/opentsdb/asyncbigtable/0.3.0/|g' /opentsdb/third_party/asyncbigtable/include.mk && \
    cp -r /opentsdb/third_party /opentsdb/build/third_party && \
    cd opentsdb && \
    sh build-bigtable.sh install

# END Base image to copy the bigtable hbase and opentsdb directories from
FROM zenoss/centos-base:1.1.5-java
MAINTAINER  Zenoss <dev@zenoss.com>

ENV HBASE_HOME /opt/hbase

COPY --from=0 /hbase-1.2.1 /hbase-1.2.1
COPY --from=0 /opentsdb /opentsdb

RUN ln -s /hbase-1.2.1 /opt/hbase && ln -s /opentsdb /opt/opentsdb && \
    mkdir -p /opt/zenoss/var /opt/zenoss/log /opt/zenoss/etc/opentsdb && \
    yum -y --setopt=tsflags="nodocs" install make && /sbin/scrub.sh

COPY supervisor.conf /opt/zenoss/etc/supervisor.conf
COPY start-opentsdb-client.sh /opt/zenoss/
COPY modify-consumer-config.sh modify-query-config.sh /var/

# Add central query and metric-consumer to supervisord
# Install metric consumer
ENV CONSUMER_VERSION 0.1.7
COPY modify-consumer-config.sh /var/modify-consumer-config.sh
RUN mkdir -p /opt/zenoss/log /opt/zenoss/etc/supervisor /opt/zenoss/var \
    && wget -qO- https://zenoss-pip.s3.amazonaws.com/packages/metric-consumer-app-${CONSUMER_VERSION}-zapp.tar.gz | tar -C /opt/zenoss -xz \
    && chmod a+x /opt/zenoss/bin/metric-consumer-app.sh \
    && ln -s /opt/zenoss/etc/metric-consumer-app/metric-consumer-app_supervisor.conf /opt/zenoss/etc/supervisor \
    && /var/modify-consumer-config.sh /opt/zenoss/etc/metric-consumer-app/configuration.yaml \
    && /sbin/scrub.sh

# Install query service
ENV QUERY_VERSION 0.1.30
RUN mkdir -p /opt/zenoss/log /opt/zenoss/etc/supervisor /opt/zenoss/var \
    && wget -qO- https://zenoss-pip.s3.amazonaws.com/packages/central-query-${QUERY_VERSION}-zapp.tar.gz | tar -C /opt/zenoss -xz \
    && chmod a+x /opt/zenoss/bin/central-query.sh \
    && ln -s /opt/zenoss/etc/central-query/central-query_supervisor.conf /opt/zenoss/etc/supervisor \
    && /var/modify-query-config.sh /opt/zenoss/etc/central-query/configuration.yaml \
    && /sbin/scrub.sh


