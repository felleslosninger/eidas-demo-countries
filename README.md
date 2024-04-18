# eidas-node
eIDAS-node with demo-country (eIDAS-proxy/connector/demo-sp/demo-idp)

# Sequence diagrams
## Norwegian citizen
```mermaid  
sequenceDiagram
autonumber
    actor User as Norsk bruker (nettleser)
    participant SP as Utenlands tjeneste
    participant UEC as Utenlandsk eIDAS Connector
    box lightpink Eidas namespace
    participant NEP as Norsk eIDAS Proxy Service
    participant SEP as Specific eIDAS Proxy
    end
    box lightyellow ID-porten
    participant IL as idporten-login
    participant C2ID as idporten-c2id
    end
    participant FR as Folkeregisteret

    User->>SP: Request Access
    SP->>UEC: Request Access
    UEC->>NEP: SAML2
    NEP->>SEP: LightProtocol request
    SEP->>SEP: map to OIDC 
    SEP->>IL: OIDC (acr: eidas-loa-X, scope: eidas:mds?)
    Note over IL,C2ID: Autentisering
    C2ID->>FR: hent persondata
    C2ID-->>IL: auth code response
    IL-->>SEP: code response
    SEP->>C2ID: getToken
    SEP->>SEP: map to LightProtocol response
    SEP-->>NEP: LightProtocol response
    NEP-->>UEC: SAML2
    UEC-->>SP: Access Granted
    SP->>User: Access Granted
```    

## Foreign citizen
```mermaid  
sequenceDiagram
autonumber
    participant User as Utenlandsk bruker (browser)
    participant SP as Norsk tjeneste
    participant Idporten as ID-porten
    participant NEN as Norwegian eIDAS Node
    participant SEN as Utenlandsk eIDAS Node
    participant IDP as Identity Provider (Utenlands eID)

    User->>SP: Request Access
    SP->>Idporten: Request Access
    Idporten->>NEN: Redirect for eID
    NEN->>SEN: Request Identity Verification
    SEN->>IDP: Verify with BankID
    IDP->>SEN: Verification Result
    SEN->>NEN: Send Verification
    NEN->>Idporten: Grant Access
    Idporten->>SP: Grant Access
    SP->>User: Access Granted
```    
