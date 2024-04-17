FROM alpine:latest as builder

# Install software
RUN apk add --no-cache zip unzip

# unzip and add config
ADD docker/config/eidas-config-2.7.1.zip /tmp/eidas-config.zip
RUN unzip /tmp/eidas-config.zip -d /tmp/
RUN ls -lt /tmp/*

ENV config_path=/tmp/tomcat
RUN cd /tmp/tomcat
RUN sed -i 's/localhost:8080\/EidasNodeConnector/localhost:8081\/EidasNodeConnector/g' $config_path/connector/eidas.xml
RUN sed -i 's/metadata.node.country">CA/metadata.node.country">CB/g' $config_path/connector/eidas.xml
RUN sed -i 's/localhost:8080/localhost:8081/g' $config_path/proxy/eidas.xml
RUN sed -i 's/metadata.node.country\"\>CA/metadata.node.country\"\>CB/g' $config_path/proxy/eidas.xml
RUN sed -i 's/localhost:8080\/SP/localhost:8081\/SP/g' $config_path/sp/sp.properties
RUN sed -i 's/localhost:8080/localhost:8081/g' $config_path/specificConnector/specificConnector.xml
RUN sed -i 's/localhost:8080/localhost:8081/g' $config_path/specificProxyService/specificProxyService.xml

#RUN sed -i 's/localhost:8080\/EidasNodeConnector\/ServiceProvider/eidas-demo-ca:8080\/EidasNodeConnector\/ServiceProvider/g' $config_path/sp/sp.properties
#RUN sed -i 's/localhost:8081\/EidasNodeConnector\/ServiceProvider/eidas-demo-ca:8081\/EidasNodeConnector\/ServiceProvider/g' $config_path/sp/sp.properties
RUN sed -i 's/localhost:8080\/EidasNodeProxy\/ServiceMetadata/eidas-demo-ca:8080\/EidasNodeProxy\/ServiceMetadata/g' $config_path/connector/eidas.xml
RUN sed -i 's/localhost:8081\/EidasNodeProxy\/ServiceMetadata/eidas-demo-cb:8080\/EidasNodeProxy\/ServiceMetadata/g' $config_path/connector/eidas.xml
RUN sed -i 's/localhost:8081\/EidasNodeProxy\/ServiceMetadata/eidas-demo-cb:8080\/EidasNodeProxy\/ServiceMetadata/g' $config_path/proxy/eidas.xml

COPY docker/config/MetadataFetcher_Connector.properties $config_path/connector/metadata/MetadataFetcher_Connector.properties

FROM tomcat:9.0-jre11-temurin-jammy
# install bouncycastle
##  Add the Bouncy Castle provider jar to the $JAVA_HOME/jre/lib/ext directory
## Create a Bouncy Castle provider entry in the $JAVA_HOME/jre/lib/security/java.security file with correct number N: security.provider.N=org.bouncycastle.jce.provider.BouncyCastleProvider
RUN ls -la /opt/java/openjdk/conf/security/
COPY docker/config/java.security /opt/java/openjdk/conf/security/java.security
COPY docker/config/bcprov-jdk18on-1.78.jar /usr/local/lib/bcprov-jdk18on-1.78.jar

# copy eidas-config
RUN mkdir -p /usr/local/tomcat/eidas-config/
COPY --from=builder /tmp/tomcat/ /usr/local/tomcat/eidas-config/


# Copy setenv.sh to /usr/local/tomcat/bin/
COPY docker/config/setenv.sh /usr/local/tomcat/bin/

# Add war files to webapps: /usr/local/tomcat/webapps
COPY docker/eidas-wars-2.7.1/*.war /usr/local/tomcat/webapps/

EXPOSE 8080
