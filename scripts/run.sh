#!/bin/bash

set -e

source /scripts/helpers.sh

source /scripts/database.sh && check_database &

source /scripts/dependencies.sh && update_dependencies &

wait

h2 "✅  Visit http://localhost or http://<docker-machine-ip> to start using Craft CMS."

# Start php-fpm
exec "$@"
