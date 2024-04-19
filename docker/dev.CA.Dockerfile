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
#ADD docker/config/eidas-config-2.7.1.zip /tmp/eidas-config.zip
#RUN unzip /tmp/eidas-config.zip -d /tmp/
RUN unzip /data/TOMCAT/config.zip -d /tmp/
ENV config_path=/tmp/tomcat
RUN cd $config_path

RUN sed -i 's/localhost:8080\/EidasNodeConnector/eidas-demo-ca:8080\/EidasNodeConnector/g' $config_path/connector/eidas.xml
RUN sed -i 's/localhost:8080\/SpecificConnector/eidas-demo-ca:8080\/SpecificConnector/g' $config_path/connector/eidas.xml
RUN sed -i 's/localhost:8080/eidas-demo-ca:8080/g' $config_path/proxy/eidas.xml
RUN sed -i 's/localhost:8080\/SP/eidas-demo-ca:8080\/SP/g' $config_path/sp/sp.properties
RUN sed -i 's/localhost:8080/eidas-demo-ca:8080/g' $config_path/specificConnector/specificConnector.xml
RUN sed -i 's/localhost:8080/eidas-demo-ca:8080/g' $config_path/specificProxyService/specificProxyService.xml



RUN sed -i 's/localhost:8080\/EidasNodeConnector\/ServiceProvider/eidas-demo-ca:8080\/EidasNodeConnector\/ServiceProvider/g' $config_path/sp/sp.properties
RUN sed -i 's/localhost:8081\/EidasNodeConnector\/ServiceProvider/eidas-demo-cb:8081\/EidasNodeConnector\/ServiceProvider/g' $config_path/sp/sp.properties
RUN sed -i 's/localhost:8080\/EidasNodeProxy\/ServiceMetadata/eidas-demo-ca:8080\/EidasNodeProxy\/ServiceMetadata/g' $config_path/connector/eidas.xml
RUN sed -i 's/localhost:8081\/EidasNodeProxy\/ServiceMetadata/eidas-demo-cb:8081\/EidasNodeProxy\/ServiceMetadata/g' $config_path/connector/eidas.xml
RUN sed -i 's/localhost:8080\/EidasNodeProxy\/ServiceMetadata/eidas-demo-cb:8081\/EidasNodeProxy\/ServiceMetadata/g' $config_path/proxy/eidas.xml

#metadata add new urls : not working yet
#RUN sed '1{s/$/-;http:\/\/eidas-demo-ca:8080\/EidasNodeProxy\/ServiceMetadata;http:\/\/eidas-demo-cb:8081\/EidasNodeProxy\/ServiceMetadata/}' $config_path/connector/metadata/MetadataFetcher_Connector.properties
#RUN sed '18{s/$/-;http:\/\/eidas-demo-ca:8080\/EidasNodeConnector\/ConnectorMetadata;http:\/\/eidas-demo-cb:8081\/EidasNodeConnector\/ConnectorMetadata/}' $config_path//proxy/metadata/MetadataFetcher_Service.properties
COPY docker/config/MetadataFetcher_Connector.properties $config_path/connector/metadata/MetadataFetcher_Connector.properties
COPY docker/config/MetadataFetcher_Service.properties $config_path/proxy/metadata/MetadataFetcher_Service.properties

FROM tomcat:9.0-jre11-temurin-jammy

ENV TOMCAT_HOME /usr/local/tomcat

# install bouncycastle
##  Add the Bouncy Castle provider jar to the $JAVA_HOME/jre/lib/ext directory
## Create a Bouncy Castle provider entry in the $JAVA_HOME/jre/lib/security/java.security file with correct number N: security.provider.N=org.bouncycastle.jce.provider.BouncyCastleProvider
# Copy customized java security properties file
COPY docker/config/java_bc.security /opt/java/openjdk/conf/security/java_bc.security
#COPY docker/config/java.security /opt/java/openjdk/conf/security/java.security
COPY docker/config/bcprov-jdk18on-1.78.jar /usr/local/lib/bcprov-jdk18on-1.78.jar

# copy eidas-config
RUN mkdir -p /usr/local/tomcat/eidas-config/
COPY --from=builder /tmp/tomcat/ ${TOMCAT_HOME}/eidas-config/

# Copy setenv.sh to /usr/local/tomcat/bin/
COPY docker/config/setenv.sh ${TOMCAT_HOME}/bin/

# Add war files to webapps: /usr/local/tomcat/webapps
COPY --from=builder /data/TOMCAT/*.war ${TOMCAT_HOME}/webapps/

# eIDAS audit log folder
RUN mkdir -p ${TOMCAT_HOME}/eidas/logs

EXPOSE 8080
