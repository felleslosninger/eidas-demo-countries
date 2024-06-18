#!/bin/bash

# NB: ${ENVIRONMENT} must be configured in idporten-cd in container.env
# Copy environment specific config to default config
ENV_CONFIG=${CATALINA_HOME}/profiles/${ENVIRONMENT}/
DEFAULT_CONFIG=${CATALINA_HOME}/eidas-config/
if [ -d "$ENV_CONFIG" ]; then
    echo "Copy files for environment ${ENVIRONMENT} from $ENV_CONFIG" && ls -lt "$ENV_CONFIG"
    cp -r "$ENV_CONFIG"** "$DEFAULT_CONFIG"
fi
