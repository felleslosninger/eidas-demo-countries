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
RUN cd /tmp/tomcat

# This is demo-country CB
RUN sed -i 's/localhost:8080\/EidasNodeConnector/eidas-demo-cb:8081\/EidasNodeConnector/g' $config_path/connector/eidas.xml
RUN sed -i 's/localhost:8080\/SpecificConnector/eidas-demo-cb:8081\/SpecificConnector/g' $config_path/connector/eidas.xml
RUN sed -i 's/metadata.node.country">CA/metadata.node.country">CB/g' $config_path/connector/eidas.xml
RUN sed -i 's/metadata.node.country">CA/metadata.node.country">CB/g' $config_path/proxy/eidas.xml
RUN sed -i 's/service.countrycode">CA/service.countrycode">CB/g' $config_path/proxy/eidas.xml
RUN sed -i 's/localhost:8080/eidas-demo-cb:8081/g' $config_path/proxy/eidas.xml
RUN sed -i 's/localhost:8080\/SP/eidas-demo-cb:8081\/SP/g' $config_path/sp/sp.properties
RUN sed -i 's/localhost:8080/eidas-demo-cb:8081/g' $config_path/specificConnector/specificConnector.xml
RUN sed -i 's/localhost:8080/eidas-demo-cb:8081/g' $config_path/specificProxyService/specificProxyService.xml
RUN sed -i 's/DEMO-IDP/DEMO-IDP-CB/g' $config_path/idp/idp.properties

RUN sed -i 's/localhost:8081\/EidasNodeConnector\/ServiceProvider/eidas-demo-cb:8081\/EidasNodeConnector\/ServiceProvider/g' $config_path/sp/sp.properties
RUN sed -i 's/localhost:8081\/EidasNodeProxy\/ServiceMetadata/eidas-demo-cb:8081\/EidasNodeProxy\/ServiceMetadata/g' $config_path/connector/eidas.xml
RUN sed -i 's/localhost:8081\/EidasNodeProxy\/ServiceMetadata/eidas-demo-cb:8081\/EidasNodeProxy\/ServiceMetadata/g' $config_path/proxy/eidas.xml

# Modififed for demo-country CA:
RUN sed -i 's/localhost:8080\/EidasNodeConnector\/ServiceProvider/eidas-demo-ca:8080\/EidasNodeConnector\/ServiceProvider/g' $config_path/sp/sp.properties
RUN sed -i 's/localhost:8080\/EidasNodeProxy\/ServiceMetadata/eidas-demo-ca:8080\/EidasNodeProxy\/ServiceMetadata/g' $config_path/connector/eidas.xml

# Add Norway (NO) as country 6
RUN sed -i 's/country6.name=CF/country6.name=NO/g' $config_path/sp/sp.properties
RUN sed -i 's/country6.url=http:\/\/localhost:9080/country6.url=http:\/\/eu-eidas-connector:8083/g' $config_path/sp/sp.properties

RUN sed -i 's/service6.id">CF/service6.id">NO/g' $config_path/connector/eidas.xml
RUN sed -i 's/service6.name">LOCAL-EIDAS-CF/service6.name">LOCAL-EIDAS-NO/g' $config_path/connector/eidas.xml
RUN sed -i 's/service6.metadata.url">http:\/\/localhost:9080/service6.metadata.url">http:\/\/eu-eidas-proxy:8082/g' $config_path/connector/eidas.xml

#Metadata with-listing
COPY docker/demo-config/MetadataFetcher_Connector.properties $config_path/connector/metadata/MetadataFetcher_Connector.properties
COPY docker/demo-config/MetadataFetcher_Service.properties $config_path/proxy/metadata/MetadataFetcher_Service.properties

FROM tomcat:9.0-jre11-temurin-jammy

ENV TOMCAT_HOME /usr/local/tomcat

# change tomcat port
RUN sed -i 's/port="8080"/port="8081"/' ${TOMCAT_HOME}/conf/server.xml

# install bouncycastle
##  Add the Bouncy Castle provider jar to the $JAVA_HOME/jre/lib/ext directory
## Create a Bouncy Castle provider entry in the $JAVA_HOME/jre/lib/security/java.security file with correct number N: security.provider.N=org.bouncycastle.jce.provider.BouncyCastleProvider
# Copy customized java security properties file
COPY docker/bouncycastle/java_bc.security /opt/java/openjdk/conf/security/java_bc.security
#COPY docker/bouncycastle/java.security /opt/java/openjdk/conf/security/java.security
COPY docker/bouncycastle/bcprov-jdk18on-1.78.jar /usr/local/lib/bcprov-jdk18on-1.78.jar

# copy eidas-config
RUN mkdir -p ${TOMCAT_HOME}/eidas-config/
COPY --from=builder /tmp/tomcat/ ${TOMCAT_HOME}/eidas-config/


# Copy setenv.sh to /usr/local/tomcat/bin/
COPY docker/demo-config/setenv.sh ${TOMCAT_HOME}/bin/

# Add war files to webapps: /usr/local/tomcat/webapps
COPY --from=builder /data/TOMCAT/*.war ${TOMCAT_HOME}/webapps/

# eIDAS audit log folder
RUN mkdir -p ${TOMCAT_HOME}/eidas/logs

EXPOSE 8081
