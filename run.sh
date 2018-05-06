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
		h2 "Remove packages"
		echo ${removable[*]}
		composer remove ${removable[*]}
	fi

 	# Regex pattern to match VCS dependencies (Git repos)
  # external dependencies have to look like this pattern 
  #   - [vendor/package-name:branch-name]https://url-to-the-git-repo.git
  #   - [vendor/package-name:version]/path/to/volume
  # If dependency is not registerd by composer
  regexHttp="(\[(.*?):(.*?)\])([http].*)" 
  regexLocal="(\[(.*?):(.*?)\])([^http].*)"

  h2 'Start adding all dependencies'

  for package in ${require[@]}; do

      if [[ $package =~ $regexHttp ]]; then
        name="${BASH_REMATCH[2]}"
        version="${BASH_REMATCH[3]}"
        url="${BASH_REMATCH[4]}"
        printf "Found \e[0;32m vcs-composer package:\e[0m for: \e[0;36m ${url}\e[0m \n"
        composer config repositories.${name} '{"type": "vcs", "url": "'${url}'", "no-api": true }'
        composer require ${name}:${version}
      elif [[ $package =~ $regexLocal ]]; then
        name="${BASH_REMATCH[2]}"
        version="${BASH_REMATCH[3]}"
        url="${BASH_REMATCH[4]}"
        printf "Found \e[0;32m local composer package:\e[0m for: \e[0;36m ${url}\e[0m \n"
        composer config repositories.${name} '{"type": "path", "url": "'${url}'", "options": {"symlink": true}}'
        composer require ${name}:${version}
      else
        printf "Require \e[0;32m composer package:\e[0m for: \e[0;36m${package}\e[0m\n"
				composer require ${package}
      fi

  done

  printf '✅ 📌 all dependencies where required '
}

import_database() {
	declare dump_zip
	declare dump_sql

	cd /var/www/html/storage/backups

	echo $DB_SERVER:$DB_PORT:$DB_DATABASE:$DB_USER:$DB_PASSWORD >~/.pgpass
	chmod 600 ~/.pgpass

	dump_zip=$(find . -name '*.zip' -print)

	if [[ "$dump_zip" ]]; then
		h2 "Database dump found (zip file)"

		if grep -q $dump_zip .ignore; then
			h2 "Ignoring file because it is listed in .ignore"
		else
			while ! pg_isready -h $DB_SERVER; do
				h2 "Waiting for PostreSQL server"
				sleep 1
			done

			zcat "$dump_zip" | psql -h $DB_SERVER -U $DB_USER && echo "$dump_zip" >>.ignore
		fi
	fi

	dump_sql=$(find . -name '*.sql' -print)

	if [[ "$dump_sql" ]]; then
		h2 "Database dump found (sql file)"

		if grep -q $dump_sql .ignore; then
			h2 "Ignoring file because it is listed in .ignore"
		else
			while ! pg_isready -h $DB_SERVER; do
				h2 "Waiting for PostreSQL server"
				sleep 1
			done

			cat "$dump_sql" | psql -h $DB_SERVER -U $DB_USER && echo "$dump_sql" >>.ignore
		fi
	fi
}

# --------------------------------------------
# Helpers
# --------------------------------------------

h2() {
    printf '\e[1;33m==>\e[37;1m %s\e[0m\n' "$*"
}

update_dependencies &

import_database &

# Start php-fpm
exec "$@"
