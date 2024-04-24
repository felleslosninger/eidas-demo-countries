
# tomcat options jvm
export CATALINA_OPTS="-Xms512m -Xmx1024m"


# bouncycastle. 
export JAVA_OPTS="$JAVA_OPTS -Djava.security.properties=/opt/java/openjdk/conf/security/java_bc.security"
export JAVA_OPTS="$JAVA_OPTS --module-path /usr/local/lib/bcprov-jdk18on-1.78.jar"
export JAVA_OPTS="$JAVA_OPTS --add-modules org.bouncycastle.provider"


# eidas config
export EIDAS_CONFIG_REPOSITORY=/usr/local/tomcat/eidas-config

export EIDAS_CONNECTOR_CONFIG_REPOSITORY="$EIDAS_CONFIG_REPOSITORY/connector/"
export EIDAS_PROXY_CONFIG_REPOSITORY="$EIDAS_CONFIG_REPOSITORY/proxy/"
export SPECIFIC_CONNECTOR_CONFIG_REPOSITORY="$EIDAS_CONFIG_REPOSITORY/specificConnector/"
export SPECIFIC_PROXY_SERVICE_CONFIG_REPOSITORY="$EIDAS_CONFIG_REPOSITORY/specificProxyService/"
export SP_CONFIG_REPOSITORY="$EIDAS_CONFIG_REPOSITORY/sp/"
export IDP_CONFIG_REPOSITORY="$EIDAS_CONFIG_REPOSITORY/idp/"


# Auditlogs config: -DLOG_HOME="<myDirectoryName>"
export LOG_HOME="/usr/local/tomcat/eidas/logs"
