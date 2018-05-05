#!/bin/bash

set -e

declare DEPENDENCIES=(${DEPENDENCIES//,/ })

update_dependencies() {
	cd /var/www/html/

	# Get base packages which are installed after 'composer create-project craftcms/craft'.
	base=$(cat composer.base |
		jq '.require' |
		jq --compact-output 'keys' |
		tr -d '[]"' | tr ',' '\n')

	# Get all currently installed packages including $base from above.
	current=$(cat composer.json |
		jq '.require' |
		jq --compact-output 'keys' |
		tr -d '[]"' | tr ',' '\n')

	# Exclude $base packages from $current packages.
	additional=($(comm -13 <(printf '%s\n' "${base[@]}" | LC_ALL=C sort) <(printf '%s\n' "${current[@]}" | LC_ALL=C sort)))

	# Get packages from $DEPENDENCIES env var which are not yet installed.
	require=($(comm -13 <(printf '%s\n' "${additional[@]}" | LC_ALL=C sort) <(printf '%s\n' "${DEPENDENCIES[@]}" | LC_ALL=C sort)))

	# Get packages which are installed but not listeed in $DEPENDENCIES var and therefore remove them in the next step.
	removable=($(comm -13 <(printf '%s\n' "${DEPENDENCIES[@]}" | LC_ALL=C sort) <(printf '%s\n' "${additional[@]}" | LC_ALL=C sort)))

	if [ ${#removable[*]} -gt 0 ]; then
		printf '\e[1;33m==>\e[37;1m %s\e[0m\n' "Remove packages"
		echo ${removable[*]}
		composer remove ${removable[*]}
	fi

	if [ ${#require[*]} -gt 0 ]; then
		printf '\e[1;33m==>\e[37;1m %s\e[0m\n' "Install packages"
		echo ${require[*]}
		composer require ${require[*]}
	fi
}

import_database() {
	declare dump_zip
	declare dump_sql

	cd /var/www/html/storage/backups

	dump_zip=$(find . -name '*.zip' -print)

	if [[ "$dump_zip" ]]; then
		printf '\e[1;33m==>\e[37;1m %s\e[0m\n' "Database dump found (zip file)"

		if grep -q $dump_zip .ignore; then
			printf '\e[1;33m==>\e[37;1m %s\e[0m\n' "Ignoring file because it is listed in .ignore"
		else
			while ! mysqladmin ping -h $DB_SERVER -u $DB_USER --password=$DB_PASSWORD --silent >/dev/null; do
				printf '\e[1;33m==>\e[37;1m %s\e[0m\n' "Waiting for MySQL server"
				sleep 1
			done

			zcat "$dump_zip" | mysql -h $DB_SERVER -u $DB_USER --password=$DB_PASSWORD $DB_DATABSE && echo "$dump_zip" >>.ignore
		fi
	fi

	dump_sql=$(find . -name '*.sql' -print)

	if [[ "$dump_sql" ]]; then
		printf '\e[1;33m==>\e[37;1m %s\e[0m\n' "Database dump found (sql file)"

		if grep -q $dump_sql .ignore; then
			printf '\e[1;33m==>\e[37;1m %s\e[0m\n' "Ignoring file because it is listed in .ignore"
		else
			while ! mysqladmin ping -h $DB_SERVER -u $DB_USER --password=$DB_PASSWORD --silent >/dev/null; do
				printf '\e[1;33m==>\e[37;1m %s\e[0m\n' "Waiting for MySQL server"
				sleep 1
			done

			cat "$dump_sql" | mysql -h $DB_SERVER -u $DB_USER --password=$DB_PASSWORD $DB_DATABASE && echo "$dump_sql" >>.ignore
		fi
	fi
}

update_dependencies &

import_database &

# Start php-fpm
exec "$@"
