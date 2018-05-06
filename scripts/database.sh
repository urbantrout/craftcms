import_database() {
	declare dump_zip
	declare dump_sql

	cd /var/www/html/storage/backups

	dump_zip=$(find . -name '*.zip' -print)

	if [[ "$dump_zip" ]]; then
		h2 "Database dump found (zip file)"

		if grep -q $dump_zip .ignore; then
			h2 "Ignoring file because it is listed in .ignore"
		else
			while ! mysqladmin ping -h $DB_SERVER -u $DB_USER --password=$DB_PASSWORD --silent >/dev/null; do
				h2 "Waiting for MySQL server"
				sleep 1
			done

			zcat "$dump_zip" | mysql -h $DB_SERVER -u $DB_USER --password=$DB_PASSWORD $DB_DATABSE && echo "$dump_zip" >>.ignore
		fi
	fi

	dump_sql=$(find . -name '*.sql' -print)

	if [[ "$dump_sql" ]]; then
		h2 "Database dump found (sql file)"

		if grep -q $dump_sql .ignore; then
			h2 "Ignoring file because it is listed in .ignore"
		else
			while ! mysqladmin ping -h $DB_SERVER -u $DB_USER --password=$DB_PASSWORD --silent >/dev/null; do
				h2 "Waiting for MySQL server"
				sleep 1
			done

			cat "$dump_sql" | mysql -h $DB_SERVER -u $DB_USER --password=$DB_PASSWORD $DB_DATABASE && echo "$dump_sql" >>.ignore
		fi
	fi
}
