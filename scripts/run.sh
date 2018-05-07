#!/bin/bash

set -e

source /scripts/helpers.sh

source /scripts/dependencies.sh && update_dependencies &

source /scripts/database.sh && import_database &

h2 "✅ All set. Visit http://localhost or http://<docker-machine-ip> to start using Craft CMS."

# Start php-fpm
exec "$@"
