# Craft CMS Docker Image

Lightweight Craft CMS 3 Image

Comes with Craft 3 and pdo_pgsql for use with PostgreSQL.

Bring your own webserver and database.

## Features

* Automatically requires and removes additional plugins via DEPENDENCIES environment variable
* Automatically restores database backups located under ./backups (See volumes in docker-compose.yml below). To create a database backup, just use the built-in backup tool within the Craft CMS Control Panel.
* pdo_pgsql
* pg_dump for backups
* redis
* imagemagick

## Example Setup

You only need two files:

* docker-compose.yml
* default.conf

### docker-compose

```yml
# docker-compose.yml
version: '2.1'

services:
  nginx:
    image: nginx:alpine
    ports:
      - 80:80
    depends_on:
      - craft
    volumes_from:
      - craft
    volumes:
      - ./default.conf:/etc/nginx/conf.d/default.conf # nginx configuration (see below)
      - ./assets:/var/www/html/web/assets # For static assets (media, js and css). We don't need PHP for them.

  craft:
    image: urbantrout/craftcms
    depends_on:
      - postgres
    volumes:
      - ./backups:/var/www/html/storage/backups # Used for db restore on start.
      - ./templates:/var/www/html/templates # Craft CMS template files
    environment:
      DEPENDENCIES: >- # additional composer packages (must be comma separated)
        craftcms/redactor,
        craftcms/element-api

      REDIS_HOST: redis
      SESSION_DRIVER: redis
      CACHE_DRIVER: redis

      DB_SERVER: postgres
      DB_NAME: craft
      DB_USER: craft
      DB_PASSWORD: secret
      DB_DATABASE: craft
      DB_SCHEMA: public
      DB_DRIVER: pgsql
      DB_PORT: 5432
      DB_TABLE_PREFIX: ut

  postgres:
    image: postgres:10.3-alpine
    environment:
      POSTGRES_ROOT_PASSWORD: root
      POSTGRES_USER: craft
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: craft
    volumes:
      # Persistent data
      - pgdata:/var/lib/postgresql/data

  redis:
    image: redis:4-alpine
    volumes:
      - redisdata:/data

volumes:
  pgdata:
  redisdata:
```

### nginx configuration

Create a file called **default.conf** in to your project directory:

```nginx
# default.conf

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name localhost;

    index index.php index.html;
    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
    root /var/www/html/web;
    charset utf-8;

    # Root directory location handler
    location / {
        try_files $uri/index.html $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        try_files $uri $uri/ /index.php?$query_string;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass craft:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
}
```

## Plugins

Just add your plugins to the environment variable DEPENDENCIES. A script then automatically adds or removes those dependencies when you create the container.

In a docker-compose file:

```yaml
    environment:
      DEPENDENCIES: >- # additional composer packages (must be comma separated)
        craftcms/redactor,
```

If you change your dependencies, just run `docker-compose down && docker-compose up` to remove and recreate your container.

## Finish setup

Run `docker-compose up` and visit http://localhost/admin. Voilà!


## Known Issues

`/run.sh: line 66: .ignore: Permssion denied`
On Linux you need to change the owner and group of the directory ./backups to 82:82, otherwise docker cannot write to the .ignore file. This also applies to any other directory which you mount as volume and docker should be able to write to (e.g. assets/media for Craft CMS Assets). 82 is the UID and GID of www-data inside the docker container.
