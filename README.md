# eidas-demo-countries

eIDAS-node demo-countries CA and CB with applications: proxy/connector/demo-sp/demo-idp for testing purposes.

See these documents in https://ec.europa.eu/digital-building-blocks/sites/display/DIGITAL/eIDAS-Node+version+2.7.1:
* eIDAS-Node Installation Quick Start Guide v2.7.pdf
* eIDAS-Node Installation and Configuration Guide v2.7.1.pdf
* eIDAS-Node Demo Tools Installation and Configuration Guide v2.7.pdf


### Run demo country CA and demo country CB as docker-compose on your machine for local testing

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

To test go to: http://eidas-demo-ca:8080/SP
and choose SP Country: CA and Citizen Country: CB.
Then select "Do not request" in section "Requested core attributes" and show natural person and click as optional or mandatory the 4 required attributes. Then next until reach idp.
Users are listed in <tomcat>/eu-config/idp/user.properties folder in the docker container on format <username>=<passord>. You may start with dim=dim. 

Country CA is on port 8080 and Country CB is on port 8081.

To setup more counties duplicate dev.CB.Dockerfile and modifiy to port for a different country, the eu-config package supports 6 countries: CA, CB, CC, CD, CE, CF.
E.g as listed in eidas-config/sp/sp.properties inside the docker container.

### Run for testing environment
TODO

# Sequence diagrams
The background colors indicates namespace in the Cluster, red is eidas-namespace.
## Norwegian citizen
```mermaid  
sequenceDiagram
autonumber
    actor User as Norsk bruker (nettleser)
    participant SP as Utenlandsk tjeneste
    participant UEC as Utenlandsk eIDAS Connector
    box lightpink idporten-eidas
    participant NEP as eidas-proxy
    participant SEP as eidas-idporten-proxy
    end
    box lightyellow ID-porten
    participant IL as idporten-login
    participant C2ID as idporten-c2id
    participant FRGW as F-REG gateway
    end
    participant FR as Folkeregisteret

    User->>SP: Request Access
    SP->>UEC: Request Access
    UEC->>NEP: SAML2
    NEP->>SEP: LightProtocol request
    SEP->>SEP: map to OIDC 
    SEP->>IL: OIDC (acr: idporten-eidas-loa-x(?), scope: eidas:<tbd>)
    Note over IL,C2ID: Autentisering
    IL-->>SEP: code response
    SEP->>C2ID: getToken
    C2ID->>FRGW: hent persondata
    FRGW->>FR: hent persondata
    C2ID-->>SEP: token response
    SEP->>SEP: map to LightProtocol response
    SEP-->>NEP: LightProtocol response
    NEP-->>UEC: SAML2
    UEC-->>SP: Access Granted
    SP-->>User: Access Granted
```    

## Foreign citizen
```mermaid  
sequenceDiagram
autonumber
    actor User as Utenlandsk bruker (Nettle)
    participant SP as Norsk tjeneste
    box lightyellow ID-porten
    participant IL as idporten-login
    participant C2ID as Connect2id
    end
    box lightpink idporten-eidas
        participant EC as eidas-idporten-connector
        participant NEC as eidas-connector
        participant FRGW as F-REG gateway
    end
    participant FR as Folkeregisteret
    participant UPS as Utenlandsk eIDAS proxy
    participant IDP as Utenlandsk eID

    User->>SP: Request Access
    SP->>IL: OIDC (acr: eidas-loa-x)
    IL->>EC: OIDC

    EC->>EC: map to LightProtocol request
    EC->>NEC: LightProtocol request
    NEC->>UPS: SAML2
    UPS->>IDP: autentiser
    IDP-->> UPS: LightProtocol response
    UPS-->>NEC: SAML2
    NEC-->>EC: LightProtocol response
    rect lightblue
        EC->>FRGW: match identity
        FRGW->>FR: match identity
    end
    EC-->>IL: token response
    Note over IL,C2ID: sesjonshåndering
    IL-->>SP: Access Granted
    SP->>User: Access Granted
```    
