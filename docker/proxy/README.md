# EU-eIDAS-proxy Configuration

Folder `config` contains the configuration files for the EU-eIDAS-proxy.

## URLs
Placeholders to change:
* `EU-PROXY-URL` - URL of this application (eu-eidas-proxy) used in eidas.xml
* `EIDAS-PROXY-URL` - URL to eidas-proxy (SpecificProxyService) used in eidas.xml
* `DEMOLAND-CA-URL` - URL of the CA of the DEMOLAND country whitelisted in metadata/ folder. Also add foreign countries EidasNodeConnector to this list.
* `NO-EU-EIDAS-CONNECTOR-URL` - URL of Norway NO country whitelisted in metadata/ folder. Also add foreign countries EidasNodeConnector to this list.

NB: might be changed to reflect correct context-paths and api.

These must be altered in dockerfile or in config outside of K8 container.

## Keystores
TODO: replace with our versions, should use HMS in test/production.

