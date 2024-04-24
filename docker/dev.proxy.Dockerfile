FROM maven:3.9-eclipse-temurin-11 as builder

WORKDIR /data

# Download EU-eidas software
ARG EIDAS_NODE_VERSION=2.7.1
RUN git clone --depth 1 --branch eidasnode-${EIDAS_NODE_VERSION} https://ec.europa.eu/digital-building-blocks/code/scm/eid/eidasnode-pub.git

RUN cd eidasnode-pub && mvn clean install --file EIDAS-Parent/pom.xml -P NodeOnly -P nodeJcacheIgnite -P specificCommunicationJcacheIgnite

RUN mkdir -p eidas-proxy-config/
COPY docker/proxy/config/ eidas-proxy-config

# Replace base URLs in eidas.xml and metadata (whitelist).
RUN sed -i 's/EU-PROXY-URL/http:\/\/eu-eidas-proxy:8082/g' eidas-proxy-config/eidas.xml
RUN sed -i 's/EIDAS-PROXY-URL/http:\/\/eidas-proxy:8081/g' eidas-proxy-config/eidas.xml
RUN sed -i 's/DEMOLAND-CA-URL/http:\/\/eidas-demo-ca:8080/g' eidas-proxy-config/metadata/MetadataFetcher_Service.properties
RUN sed -i 's/NO-EU-EIDAS-CONNECTOR-URL/http:\/\/eu-eidas-connector:8083/g' eidas-proxy-config/metadata/MetadataFetcher_Service.properties

# Only for local development
RUN sed -i 's/metadata.restrict.http">true/metadata.restrict.http">false/g' eidas-proxy-config/eidas.xml

FROM tomcat:9.0-jre11-temurin-jammy

COPY docker/bouncycastle/java_bc.security /opt/java/openjdk/conf/security/java_bc.security
COPY docker/bouncycastle/bcprov-jdk18on-1.78.jar /usr/local/lib/bcprov-jdk18on-1.78.jar

# change tomcat port
RUN sed -i 's/port="8080"/port="8082"/' ${CATALINA_HOME}/conf/server.xml

COPY docker/proxy/tomcat-setenv.sh ${CATALINA_HOME}/bin/setenv.sh

RUN mkdir -p $CATALINA_HOME/eidas-proxy-config/
COPY --from=builder /data/eidas-proxy-config/ $CATALINA_HOME/eidas-proxy-config

# Add war files to webapps: /usr/local/tomcat/webapps
COPY --from=builder /data/eidasnode-pub/EIDAS-Node-Proxy/target/EidasNodeProxy.war ${CATALINA_HOME}/webapps/

# eIDAS audit log folder
RUN mkdir -p ${CATALINA_HOME}/eidas/logs && chmod 744 ${CATALINA_HOME}/eidas/logs

EXPOSE 8082
