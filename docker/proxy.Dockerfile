FROM maven:3.9-eclipse-temurin-11 as builder

WORKDIR /data

# Download EU-eidas software
RUN git clone https://ec.europa.eu/digital-building-blocks/code/scm/eid/eidasnode-pub.git

RUN cd eidasnode-pub && mvn clean install --file EIDAS-Parent/pom.xml -P NodeOnly -P nodeJcacheIgnite -P specificCommunicationJcacheIgnite

FROM tomcat:9.0-jre11-temurin-jammy

COPY docker/bouncycastle/java_bc.security /opt/java/openjdk/conf/security/java_bc.security
COPY docker/bouncycastle/bcprov-jdk18on-1.78.jar /usr/local/lib/bcprov-jdk18on-1.78.jar

ENV TOMCAT_HOME /usr/local/tomcat

RUN mkdir -p $TOMCAT_HOME/eidas-proxy-config/
COPY docker/proxy/config/ $TOMCAT_HOME/eidas-proxy-config

# Replace base URLs in eidas.xml and metadata (whitelist). TODO: move to environment specific k8 config
RUN sed -i 's/EU-PROXY-URL/https:\/\/eu-eidas-proxy.idporten.dev/g' $TOMCAT_HOME/eidas-proxy-config/eidas.xml
RUN sed -i 's/EIDAS-PROXY-URL/https:\/\/eidas-proxy.idporten.dev/g' $TOMCAT_HOME/eidas-proxy-config/eidas.xml
RUN sed -i 's/DEMOLAND-CA-URL/https:\/\/eidas-demo-ca.idporten.dev/g' $TOMCAT_HOME/eidas-proxy-config/metadata/MetadataFetcher_Service.properties

COPY docker/proxy/tomcat-setenv.sh ${TOMCAT_HOME}/bin/setenv.sh

# Add war files to webapps: /usr/local/tomcat/webapps
COPY --from=builder /data/eidasnode-pub/EIDAS-Node-Proxy/target/EidasNodeProxy.war ${TOMCAT_HOME}/webapps/

# eIDAS audit log folder
RUN mkdir -p ${TOMCAT_HOME}/eidas/logs

EXPOSE 8080
