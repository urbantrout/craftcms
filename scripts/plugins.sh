activate_plugins() {
	h2 'Activating Plugins.'

	cd /var/www/html

	dependencies=$(cat composer.json |
		jq '.require' |
		jq --compact-output 'keys' |
		tr -d '[]"' | tr ',' '\n')

	for package in ${dependencies}; do

		vendor=$(awk -F '[\/:]+' '{print $1}' <<<$package)
		packageName=$(awk -F '[\/:]+' '{print $2}' <<<$package)
		isCraftPlugin=$(cat vendor/$vendor/$packageName/composer.json | jq '.type == "craft-plugin"')

		if [ "$isCraftPlugin" = true ]; then
			handle=$(cat vendor/$vendor/$packageName/composer.json | jq -r '.extra.handle')
			./craft install/plugin $handle
		fi
	done
}
