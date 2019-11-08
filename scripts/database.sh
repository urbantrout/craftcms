setup_database() {
	declare zip_file
	declare sql_file

	cd /var/www/html/storage

	# Find most recent zip file (mtime)
	zip_file=$(find backups -name "*.zip" -printf "%t %p\n" | sort -n | rev | cut -d' ' -f 1 | rev | tail -n1)

	if [[ "$zip_file" ]]; then
		h2 "Decompressing zip file: ${zip_file}"

		# Unzip file and force overwrite
		unzip -o $zip_file -d backups
	fi

	# Find most recent sql file (mtime)
	sql_file=$(find backups -name "*.sql" -printf "%t %p\n" | sort -n | rev | cut -d' ' -f 1 | rev | tail -n1)

	if [[ "$sql_file" ]]; then
		h2 "Database dump found: ${sql_file}"

		ignore_file="backups/.ignore"

		if [ -f $ignore_file ] && grep -q $1 $ignore_file; then
			h2 "Ignoring file because it is listed in $ignore_file"
		else
			while ! mysqladmin ping -h $DB_SERVER -u $DB_USER --password=$DB_PASSWORD --silent >/dev/null; do
				h2 "Waiting for MySQL server"
				sleep 1
			done

			h2 "Importing database"
			cat "$sql_file" | mysql -h $DB_SERVER -u $DB_USER --password=$DB_PASSWORD $DB_DATABASE && \
            echo "$sql_file" >> $ignore_file
		fi

		if [[ "$zip_file" ]]; then
			h2 "Deleting decompressed SQL file."
			rm $sql_file
		fi
	else
		h2 "Setup Craft CMS"

		while ! mysqladmin ping -h $DB_SERVER -u $DB_USER --password=$DB_PASSWORD --silent >/dev/null; do
			h2 "Waiting for MySQL server"
			sleep 1
		done

		cd /var/www/html &&
			./craft setup/security-key &&
			./craft install \
				--interactive=0 \
				--email="${CRAFTCMS_EMAIL}" \
				--username="${CRAFTCMS_USERNAME:-admin}" \
				--password="${CRAFTCMS_PASSWORD}" \
				--siteName="${CRAFTCMS_SITENAME}" \
				--siteUrl="${CRAFTCMS_SITEURL:-@web}" \
				--language="${CRAFTCMS_LANGUAGE:-en-US}"
	fi
}
