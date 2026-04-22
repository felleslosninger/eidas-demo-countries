FROM alpine:latest AS builder

# Install software
RUN apk add --no-cache zip unzip curl

WORKDIR /data

ARG EIDAS_NODE_VERSION=3.0.0
ARG BC_VERSION=1.81
ARG EIDAS_NODE_URL=https://ec.europa.eu/digital-building-blocks/artifact/repository/eid/eu/eIDAS-node/${EIDAS_NODE_VERSION}/eIDAS-node-${EIDAS_NODE_VERSION}.zip

# Download eIDAS-Node Software
RUN curl ${EIDAS_NODE_URL} -o eIDAS-node-dl.zip

# Unzip eIDAS-Node Software
RUN unzip eIDAS-node-dl.zip && \
    unzip EIDAS-Binaries-${EIDAS_NODE_VERSION}.zip

# unzip and add config
RUN unzip EIDAS-Config-Tomcat-${EIDAS_NODE_VERSION}.zip && \
    unzip TOMCAT/config.zip -d /tmp/
ENV config_path=/tmp/tomcat

# Delete files in config for replacement of environment spesific files on start up of Tomcat
# Delete files in proxy and connector
RUN rm $config_path/connector/eidas.xml && rm $config_path/proxy/eidas.xml && rm $config_path/proxy/metadata/MetadataFetcher_Service.properties && rm $config_path/connector/metadata/MetadataFetcher_Connector.properties && rm $config_path/proxy/keystore/eidasKeyStore.p12 && rm $config_path/connector/keystore/eidasKeyStore.p12 && rm $config_path/proxy/keystore/eidasTrustStore.p12 && rm $config_path/connector/keystore/eidasTrustStore.p12
# Delete files to be replaced in spesificConnector, spesificProxy and sp. (No change in idp for systest/test)
RUN rm $config_path/sp/sp.properties && rm $config_path/specificConnector/specificConnector.xml && rm $config_path/specificProxyService/specificProxyService.xml && rm $config_path/idp/user.properties

FROM tomcat:11.0-jre21-temurin

#Fjerner passord fra logger ved oppstart
RUN sed -i -e 's/FINE/WARNING/g' /usr/local/tomcat/conf/logging.properties
# Fjerner default applikasjoner fra tomcat
RUN rm -rf /usr/local/tomcat/webapps.dist

COPY docker/tomcat-config/setenv.sh ${CATALINA_HOME}/bin/
COPY docker/tomcat-config/server.xml ${CATALINA_HOME}/conf/server.xml

#øke stø
RUN sed -i '/maxParameterCount="1000"/ s/$/\n maxHttpHeaderSize="65536"\n/' ${CATALINA_HOME}/conf/server.xml
# Copy setenv.sh to /usr/local/tomcat/bin/

# install bouncycastle
ARG BC_VERSION=1.81
ARG BC_JAR=bcprov-jdk18on-${BC_VERSION}.jar
ARG BC_URL=https://repo1.maven.org/maven2/org/bouncycastle/bcprov-jdk18on/${BC_VERSION}/${BC_JAR}
COPY docker/bouncycastle/java_bc.security /opt/java/openjdk/conf/security/java_bc.security
RUN wget -q ${BC_URL} -O ${CATALINA_HOME}/lib/${BC_JAR}

# copy eidas-config
RUN mkdir -p ${CATALINA_HOME}/eidas-config/
COPY --from=builder /tmp/tomcat/ ${CATALINA_HOME}/eidas-config/
COPY docker/profiles ${CATALINA_HOME}/profiles
RUN chmod 776 ${CATALINA_HOME}/eidas-config && chmod 776 ${CATALINA_HOME}/eidas-config/proxy && chmod 776 ${CATALINA_HOME}/eidas-config/proxy/metadata  && chmod 776 ${CATALINA_HOME}/eidas-config/proxy/keystore && chmod 776 ${CATALINA_HOME}/eidas-config/connector && chmod 776 ${CATALINA_HOME}/eidas-config/connector/metadata && chmod 776 ${CATALINA_HOME}/eidas-config/connector/keystore && chmod 776 ${CATALINA_HOME}/eidas-config/idp && chmod 776 ${CATALINA_HOME}/eidas-config/sp && chmod 776 ${CATALINA_HOME}/eidas-config/specificConnector && chmod 776 ${CATALINA_HOME}/eidas-config/specificProxyService

COPY docker/addEnvironmentSpesificConfigFiles.sh ${CATALINA_HOME}/bin/addEnvironmentSpesificConfigFiles.sh
RUN chmod 755 ${CATALINA_HOME}/bin/addEnvironmentSpesificConfigFiles.sh

# Add war files to webapps: /usr/local/tomcat/webapps
COPY --from=builder /data/WARS/*.war ${CATALINA_HOME}/webapps/
RUN chmod -R 770 ${CATALINA_HOME}/webapps

# Add Cache Ignite work folder
RUN mkdir -p ${CATALINA_HOME}/ignite && chgrp -R 0 ${CATALINA_HOME}/ignite && chmod 770 ${CATALINA_HOME}/ignite

# eIDAS audit log folder
RUN mkdir -p ${CATALINA_HOME}/eidas/logs && chmod 774 ${CATALINA_HOME}/eidas/logs

EXPOSE 8080

CMD ["/bin/bash", "-c", "./bin/addEnvironmentSpesificConfigFiles.sh;catalina.sh run"]

