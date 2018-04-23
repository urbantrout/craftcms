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

update_dependencies &

# Start php-fpm
exec "$@"
