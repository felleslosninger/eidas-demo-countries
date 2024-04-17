FROM alpine:latest as builder

# Install software
RUN apk add --no-cache zip unzip

# unzip and add config
ADD docker/config/eidas-config-2.7.1.zip /tmp/eidas-config.zip
RUN unzip /tmp/eidas-config.zip -d /tmp/
RUN ls -lt /tmp/*

RUN cd /tmp/tomcat
RUN cd /tmp/tomcat/sp

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
RUN ls -la /usr/local/tomcat/eidas-config/*

# Copy setenv.sh to /usr/local/tomcat/bin/
COPY docker/config/setenv.sh /usr/local/tomcat/bin/

# Add war files to webapps: /usr/local/tomcat/webapps
COPY docker/wars-2.7.1/*.war /usr/local/tomcat/webapps/

EXPOSE 8080
