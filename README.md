# eidas-node
eIDAS-node for Norway with demo-country (eIDAS-proxy/connector/demo-sp/demo-idp) for testing purposes.

See these documents in https://ec.europa.eu/digital-building-blocks/sites/display/DIGITAL/eIDAS-Node+version+2.7.1:
* eIDAS-Node Installation Quick Start Guide v2.7.pdf
* eIDAS-Node Installation and Configuration Guide v2.7.1.pdf
* eIDAS-Node Installation Quick Start Guide v2.7.pdf

# Run demo country CA and demo country CB as docker-compose on your machine for local testing

Add the following to your /etc/hosts file:
```
# eIDAS local dev
127.0.0.1 eidas-demo-ca
127.0.0.1 eidas-demo-cb
```
Start docker containers:
```
docker-compose up --build
```
This will run two docker services each with a tomcat instance with all the six EU-war files deployed for running demo country.

To test go to: http://localhost:8080/SP
and choose SP Country: CA and Citizen Country: CB. 
Users are listed in <tomcat>/eu-config/idp/user.properties folder in the docker container on format <username>=<passord>. You may start with dim=dim. 

Country CA is on port 8080 and Country CB is on port 8081.

To setup more counties duplicate dev.CB.Dockerfile and modifiy to port for a different country, the eu-config package supports 6 countries: CA, CB, CC, CD, CE, CF.
E.g as listed in eidas-config/sp/sp.properties inside the docker container.

# TODO run for testing environment