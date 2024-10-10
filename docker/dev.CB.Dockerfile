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
RUN unzip /data/TOMCAT/config.zip -d /tmp/

ENV config_path=/tmp/tomcat

# Delete files in config for replacement of environment spesific files on start up of Tomcat
# Delete files in proxy and connector
RUN rm $config_path/connector/eidas.xml && rm $config_path/proxy/eidas.xml && rm $config_path/proxy/metadata/MetadataFetcher_Service.properties && rm $config_path/connector/metadata/MetadataFetcher_Connector.properties && rm $config_path/proxy/keystore/eidasKeyStore.p12 && rm $config_path/connector/keystore/eidasKeyStore.p12
# Delete files to be replaced in spesificConnector, spesificProxy, idp and sp
RUN rm $config_path/sp/sp.properties && rm $config_path/specificConnector/specificConnector.xml && rm $config_path/specificProxyService/specificProxyService.xml && rm $config_path/idp/idp.properties


FROM tomcat:11.0-jre11-temurin-jammy

#Fjerner passord fra logger ved oppstart
RUN sed -i -e 's/FINE/WARNING/g' /usr/local/tomcat/conf/logging.properties
# Fjerner default applikasjoner fra tomcat
RUN rm -rf /usr/local/tomcat/webapps.dist

COPY docker/tomcat-config/setenv.sh ${CATALINA_HOME}/bin/
COPY docker/tomcat-config/server.xml ${CATALINA_HOME}/conf/server.xml

# change tomcat port
RUN sed -i 's/port="8080"/port="8081"/' ${CATALINA_HOME}/conf/server.xml

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

# eIDAS audit log folder
RUN mkdir -p ${CATALINA_HOME}/eidas/logs && chmod 744 ${CATALINA_HOME}/eidas/logs

EXPOSE 8081
