FROM php:7.2-fpm-alpine

LABEL maintainer="harald@urbantrout.io"

ENV COMPOSER_NO_INTERACTION=1

RUN set -ex \
    && apk add --update --no-cache freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev autoconf g++ imagemagick-dev libtool make pcre-dev postgresql-dev libintl icu icu-dev \
    && docker-php-ext-configure gd \
    --with-gd \
    --with-freetype-dir=/usr/include/ \
    --with-png-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd zip intl pdo_pgsql \
    && pecl install imagick redis \
    && docker-php-ext-enable imagick redis \
    && rm -rf /tmp/pear \
    && apk del freetype-dev libpng-dev libjpeg-turbo-dev autoconf g++ libtool make pcre-dev
COPY php.ini /usr/local/etc/php/
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN chown -R www-data:www-data /var/www/html/
USER www-data
RUN composer create-project craftcms/craft /var/www/html
