FROM maven:3.9-eclipse-temurin-11 as builder

WORKDIR /data

# Download EU-eidas software
ARG EIDAS_NODE_VERSION=2.7.1
RUN git clone --depth 1 --branch eidasnode-${EIDAS_NODE_VERSION} https://ec.europa.eu/digital-building-blocks/code/scm/eid/eidasnode-pub.git

RUN cd eidasnode-pub && mvn clean install --file EIDAS-Parent/pom.xml -P NodeOnly -P nodeJcacheIgnite -P specificCommunicationJcacheIgnite

RUN mkdir -p eidas-proxy-config/
COPY docker/proxy/config/ eidas-proxy-config

# Replace base URLs in eidas.xml and metadata (whitelist). TODO: move to environment specific k8 config
RUN sed -i 's/EU-PROXY-URL/https:\/\/eu-eidas-proxy.idporten.dev/g' eidas-proxy-config/eidas.xml
RUN sed -i 's/EIDAS-PROXY-URL/https:\/\/eidas-proxy.idporten.dev/g' eidas-proxy-config/eidas.xml
RUN sed -i 's/DEMOLAND-CA-URL/https:\/\/eidas-demo-ca.idporten.dev/g' eidas-proxy-config/metadata/MetadataFetcher_Service.properties
RUN sed -i 's/NO-EU-EIDAS-CONNECTOR-URL/https:\/\/eu-eidas-connector.idporten.dev/g' eidas-proxy-config/metadata/MetadataFetcher_Service.properties



FROM tomcat:9.0-jre11-temurin-jammy

COPY docker/bouncycastle/java_bc.security /opt/java/openjdk/conf/security/java_bc.security
COPY docker/bouncycastle/bcprov-jdk18on-1.78.jar /usr/local/lib/bcprov-jdk18on-1.78.jar

COPY docker/proxy/tomcat-setenv.sh ${CATALINA_HOME}/bin/setenv.sh

RUN mkdir -p $CATALINA_HOME/eidas-proxy-config/
COPY --from=builder /data/eidas-proxy-config/ $CATALINA_HOME/eidas-proxy-config

# Add war files to webapps: /usr/local/tomcat/webapps
COPY --from=builder /data/eidasnode-pub/EIDAS-Node-Proxy/target/EidasNodeProxy.war ${CATALINA_HOME}/webapps/
RUN chmod -R 770 ${CATALINA_HOME}/webapps

# Add Cache Ignite work folder. TODO: Remove when switch to Redis.
RUN mkdir -p ${CATALINA_HOME}/ignite && chgrp -R 0 ${CATALINA_HOME}/ignite && chmod 770 ${CATALINA_HOME}/ignite

# eIDAS audit log folder
RUN mkdir -p ${CATALINA_HOME}/eidas/logs && chmod 774 ${CATALINA_HOME}/eidas/logs

EXPOSE 8080

CMD ["/bin/bash", "-c", "catalina.sh run"]
