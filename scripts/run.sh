#!/bin/bash

set -e

source /scripts/helpers.sh
source /scripts/database.sh
source /scripts/composer.sh
source /scripts/plugins.sh

setup_database &
SETUP_PID=$!
update_dependencies &
DEPENDENDIES_PID=$!

wait $SETUP_PID
wait $DEPENDENCIES_PID
activate_plugins

wait

h2 "✅  Visit http://localhost or http://<docker-machine-ip> to start using Craft CMS."

# Start php-fpm
exec "$@"
