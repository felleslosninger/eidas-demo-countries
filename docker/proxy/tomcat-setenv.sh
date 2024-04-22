
# tomcat options jvm
export CATALINA_OPTS="-Xms512m -Xmx1024m"


# bouncycastle. 
export JAVA_OPTS="$JAVA_OPTS -Djava.security.properties=/opt/java/openjdk/conf/security/java_bc.security"
export JAVA_OPTS="$JAVA_OPTS --module-path /usr/local/lib/bcprov-jdk18on-1.78.jar"
export JAVA_OPTS="$JAVA_OPTS --add-modules org.bouncycastle.provider"

# eidas config
export EIDAS_PROXY_CONFIG_REPOSITORY="/usr/local/tomcat/eidas-proxy-config/"

# Auditlogs config: -DLOG_HOME="<myDirectoryName>"
export LOG_HOME="/usr/local/tomcat/eidas/logs"
