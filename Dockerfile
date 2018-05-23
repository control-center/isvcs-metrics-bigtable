FROM gcr.io/zing-registry-188222/otsdb-bigtable:v1

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


