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
RUN cd $config_path

# This is demo-country CA
RUN sed -i 's/localhost:8080\/EidasNodeConnector/eidas-demo-ca:8080\/EidasNodeConnector/g' $config_path/connector/eidas.xml
RUN sed -i 's/localhost:8080\/SpecificConnector/eidas-demo-ca:8080\/SpecificConnector/g' $config_path/connector/eidas.xml
RUN sed -i 's/localhost:8080/eidas-demo-ca:8080/g' $config_path/proxy/eidas.xml
RUN sed -i 's/localhost:8080\/SP/eidas-demo-ca:8080\/SP/g' $config_path/sp/sp.properties
RUN sed -i 's/localhost:8080/eidas-demo-ca:8080/g' $config_path/specificConnector/specificConnector.xml
RUN sed -i 's/localhost:8080/eidas-demo-ca:8080/g' $config_path/specificProxyService/specificProxyService.xml
RUN sed -i '/<\/properties/i \
     <entry key="disallow.self.signed.certificate">false</entry> ' $config_path/connector/eidas.xml
RUN sed -i '/<\/properties/i \
     <entry key="disallow.self.signed.certificate">false</entry> ' $config_path/proxy/eidas.xml

RUN sed -i 's/localhost:8080\/EidasNodeConnector\/ServiceProvider/eidas-demo-ca:8080\/EidasNodeConnector\/ServiceProvider/g' $config_path/sp/sp.properties
RUN sed -i 's/localhost:8080\/EidasNodeProxy\/ServiceMetadata/eidas-demo-ca:8080\/EidasNodeProxy\/ServiceMetadata/g' $config_path/connector/eidas.xml

# Modififed for demo-country CB:
RUN sed -i 's/localhost:8081\/EidasNodeConnector\/ServiceProvider/eidas-demo-cb:8081\/EidasNodeConnector\/ServiceProvider/g' $config_path/sp/sp.properties
RUN sed -i 's/localhost:8081\/EidasNodeProxy\/ServiceMetadata/eidas-demo-cb:8081\/EidasNodeProxy\/ServiceMetadata/g' $config_path/connector/eidas.xml
RUN sed -i 's/localhost:8080\/EidasNodeProxy\/ServiceMetadata/eidas-demo-cb:8081\/EidasNodeProxy\/ServiceMetadata/g' $config_path/proxy/eidas.xml

# Add Norway (NO) as country 6
RUN sed -i 's/country6.name=CF/country6.name=NO/g' $config_path/sp/sp.properties
RUN sed -i 's/country6.url=http:\/\/localhost:9080/country6.url=http:\/\/eidas-connector:8083/g' $config_path/sp/sp.properties

RUN sed -i 's/service6.id">CF/service6.id">NO/g' $config_path/connector/eidas.xml
RUN sed -i 's/service6.name">LOCAL-EIDAS-CF/service6.name">LOCAL-EIDAS-NO/g' $config_path/connector/eidas.xml
RUN sed -i 's/service6.metadata.url">http:\/\/localhost:9080\/EidasNodeProxy/service6.metadata.url">http:\/\/eidas-proxy:8082/g' $config_path/connector/eidas.xml

#Metadata with-listing
COPY docker/demo-config/MetadataFetcher_Connector.properties $config_path/connector/metadata/MetadataFetcher_Connector.properties
COPY docker/demo-config/MetadataFetcher_Service.properties $config_path/proxy/metadata/MetadataFetcher_Service.properties

# copy keystore with trusted norwegian certificate
COPY docker/demo-config/connector-eidasKeyStore.p12 $config_path/connector/keystore/eidasKeyStore.p12

# Test users
COPY docker/demo-config/user.properties $config_path/idp/user.properties

FROM tomcat:9.0-jre11-temurin-jammy

RUN sed -i '/maxParameterCount="1000"/ s/$/\n maxHttpHeaderSize="65536"\n/' ${CATALINA_HOME}/conf/server.xml

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

# eIDAS audit log folder
RUN mkdir -p ${CATALINA_HOME}/eidas/logs && chmod 744 ${CATALINA_HOME}/eidas/logs

EXPOSE 8080
