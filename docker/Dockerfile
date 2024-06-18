FROM alpine:latest as builder

# Install software
RUN apk add --no-cache zip unzip curl

WORKDIR /data

ARG EIDAS_NODE_VERSION=2.7.1
ARG EIDAS_NODE_URL=https://ec.europa.eu/digital-building-blocks/artifact/repository/eid/eu/eIDAS-node/${EIDAS_NODE_VERSION}/eIDAS-node-${EIDAS_NODE_VERSION}.zip

# Download eIDAS-Node Software
RUN curl ${EIDAS_NODE_URL} -o eIDAS-node-dl.zip

# Unzip eIDAS-Node Software
RUN unzip eIDAS-node-dl.zip && \
    unzip EIDAS-Binaries-Tomcat-*.zip


# unzip and add config
RUN unzip /data/TOMCAT/config.zip -d /tmp/
ENV config_path=/tmp/tomcat

# Delete files in config for replacement of environment spesific files on start up of Tomcat
# Delete files in proxy and connector
RUN rm $config_path/connector/eidas.xml && rm $config_path/proxy/eidas.xml && rm $config_path/proxy/metadata/MetadataFetcher_Service.properties && rm $config_path/connector/metadata/MetadataFetcher_Connector.properties && rm $config_path/connector/keystore/eidasKeyStore.p12
# Delete files to be replaced in spesificConnector, spesificProxy and sp. (No change in idp for systest/test)
RUN rm $config_path/sp/sp.properties && rm $config_path/specificConnector/specificConnector.xml && rm $config_path/specificProxyService/specificProxyService.xml

FROM tomcat:9.0-jre11-temurin-jammy

#øke stø
RUN sed -i '/maxParameterCount="1000"/ s/$/\n maxHttpHeaderSize="65536"\n/' ${CATALINA_HOME}/conf/server.xml
# Copy setenv.sh to /usr/local/tomcat/bin/
COPY docker/tomcat-config/setenv.sh ${CATALINA_HOME}/bin/

# install bouncycastle
COPY docker/bouncycastle/java_bc.security /opt/java/openjdk/conf/security/java_bc.security
COPY docker/bouncycastle/bcprov-jdk18on-1.78.jar /usr/local/lib/bcprov-jdk18on-1.78.jar

# copy eidas-config
RUN mkdir -p ${CATALINA_HOME}/eidas-config/
COPY --from=builder /tmp/tomcat/ ${CATALINA_HOME}/eidas-config/
COPY docker/profiles ${CATALINA_HOME}/profiles
RUN chmod 776 ${CATALINA_HOME}/eidas-config

COPY docker/addEnvironmentSpesificConfigFiles.sh ${CATALINA_HOME}/bin/addEnvironmentSpesificConfigFiles.sh
RUN chmod 755 ${CATALINA_HOME}/bin/addEnvironmentSpesificConfigFiles.sh

# Add war files to webapps: /usr/local/tomcat/webapps
COPY --from=builder /data/TOMCAT/*.war ${CATALINA_HOME}/webapps/
RUN chmod -R 770 ${CATALINA_HOME}/webapps

# Add Cache Ignite work folder
RUN mkdir -p ${CATALINA_HOME}/ignite && chgrp -R 0 ${CATALINA_HOME}/ignite && chmod 770 ${CATALINA_HOME}/ignite

# eIDAS audit log folder
RUN mkdir -p ${CATALINA_HOME}/eidas/logs && chmod 774 ${CATALINA_HOME}/eidas/logs

EXPOSE 8080

CMD ["/bin/bash", "-c", "./bin/addEnvironmentSpesificConfigFiles.sh;catalina.sh run"]

