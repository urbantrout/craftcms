import_database() {
	if grep -q $1 .ignore; then
		h2 "Ignoring file because it is listed in .ignore"
	else
		while ! mysqladmin ping -h $DB_SERVER -u $DB_USER --password=$DB_PASSWORD --silent >/dev/null; do
			h2 "Waiting for MySQL server"
			sleep 1
		done

		cat "$1" | mysql -h $DB_SERVER -u $DB_USER --password=$DB_PASSWORD $DB_DATABASE && echo "$1" >>.ignore
	fi
}

check_database() {
	declare zip_file
	declare sql_file

	cd /var/www/html/storage/backups

	# Find most recent zip file (mtime)
	zip_file=$(find . -name "*.zip" -printf "%t %p\n" | sort -n | cut -d' ' -f 6- | tail -n1)

	if [[ "$zip_file" ]]; then
		h2 "Decompressing zip file: ${zip_file}"

		# Unzip file and force overwrite
		unzip -o $zip_file
	fi

	# Find most recent sql file (mtime)
	sql_file=$(find . -name "*.sql" -printf "%t %p\n" | sort -n | cut -d' ' -f 6- | tail -n1)

	if [[ "$sql_file" ]]; then
		h2 "Database dump found: ${sql_file}"

		import_database $sql_file
	fi
}
