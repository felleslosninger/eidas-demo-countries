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

# Replace Demo-country CA localhost URLs with eidas-demo-ca.idporten.dev (for systest for now)
RUN sed -i 's/http:\/\/localhost:8080\/EidasNodeConnector/https:\/\/eidas-demo-ca.idporten.dev\/EidasNodeConnector/g' $config_path/connector/eidas.xml
RUN sed -i 's/http:\/\/localhost:8080\/SpecificConnector/https:\/\/eidas-demo-ca.idporten.dev\/SpecificConnector/g' $config_path/connector/eidas.xml
RUN sed -i 's/http:\/\/localhost:8080/https:\/\/eidas-demo-ca.idporten.dev/g' $config_path/proxy/eidas.xml
RUN sed -i 's/http:\/\/localhost:8080\/SP/https:\/\/eidas-demo-ca.idporten.dev\/SP/g' $config_path/sp/sp.properties
RUN sed -i 's/http:\/\/localhost:8080/https:\/\/eidas-demo-ca.idporten.dev/g' $config_path/specificConnector/specificConnector.xml
RUN sed -i 's/http:\/\/localhost:8080/https:\/\/eidas-demo-ca.idporten.dev/g' $config_path/specificProxyService/specificProxyService.xml

RUN sed -i 's/http:\/\/localhost:8080\/EidasNodeConnector\/ServiceProvider/https:\/\/eidas-demo-ca.idporten.dev\/EidasNodeConnector\/ServiceProvider/g' $config_path/sp/sp.properties
RUN sed -i 's/http:\/\/localhost:8080\/EidasNodeProxy\/ServiceMetadata/https:\/\/eidas-demo-ca.idporten.dev\/EidasNodeProxy\/ServiceMetadata/g' $config_path/connector/eidas.xml

# Add Norway (NO) as country 6
RUN sed -i 's/country6.name=CF/country6.name=NO/g' $config_path/sp/sp.properties
RUN sed -i 's/country6.url=http:\/\/localhost:9080/country6.url=https:\/\/eu-eidas-connector.idporten.dev/g' $config_path/sp/sp.properties

RUN sed -i 's/service6.id">CF/service6.id">NO/g' $config_path/connector/eidas.xml
RUN sed -i 's/service6.name">LOCAL-EIDAS-CF/service6.name">EIDAS-NO/g' $config_path/connector/eidas.xml
RUN sed -i 's/service6.metadata.url">http:\/\/localhost:9080/service6.metadata.url">https:\/\/eu-eidas-proxy.idporten.dev/g' $config_path/connector/eidas.xml


# Only allow https in proxy and connector
RUN sed -i 's/metadata.restrict.http">false/metadata.restrict.http">true/g' $config_path/proxy/eidas.xml
RUN sed -i 's/metadata.restrict.http">false/metadata.restrict.http">true/g' $config_path/connector/eidas.xml

# White-lists for connector and proxy
COPY docker/demo-config/MetadataFetcher_Connector.properties $config_path/connector/metadata/MetadataFetcher_Connector.properties
COPY docker/demo-config/MetadataFetcher_Service.properties $config_path/proxy/metadata/MetadataFetcher_Service.properties

FROM tomcat:9.0-jre11-temurin-jammy

# Copy setenv.sh to /usr/local/tomcat/bin/
COPY docker/demo-config/setenv.sh ${CATALINA_HOME}/bin/

# install bouncycastle
COPY docker/bouncycastle/java_bc.security /opt/java/openjdk/conf/security/java_bc.security
COPY docker/bouncycastle/bcprov-jdk18on-1.78.jar /usr/local/lib/bcprov-jdk18on-1.78.jar

# copy eidas-config
RUN mkdir -p /usr/local/tomcat/eidas-config/
COPY --from=builder /tmp/tomcat/ ${CATALINA_HOME}/eidas-config/

# Add war files to webapps: /usr/local/tomcat/webapps
COPY --from=builder /data/TOMCAT/*.war ${CATALINA_HOME}/webapps/
RUN chmod -R 770 ${CATALINA_HOME}/webapps

# Add Cache Ignite work folder
RUN mkdir -p ${CATALINA_HOME}/ignite && chgrp -R 0 ${CATALINA_HOME}/ignite && chmod 770 ${CATALINA_HOME}/ignite

# eIDAS audit log folder
RUN mkdir -p ${CATALINA_HOME}/eidas/logs && chmod 774 ${CATALINA_HOME}/eidas/logs

EXPOSE 8080

CMD ["/bin/bash", "-c", "catalina.sh run"]
