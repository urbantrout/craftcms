#!/bin/bash

set -e

source /scripts/helpers.sh

source /scripts/dependencies.sh && update_dependencies &

source /scripts/database.sh && import_database &

# Start php-fpm
exec "$@"
