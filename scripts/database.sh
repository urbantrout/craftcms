# TODO: Refactor code (not DRY yet)
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
