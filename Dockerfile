FROM php:7.2-fpm-alpine3.7

LABEL maintainer="harald@urbantrout.io"

ENV COMPOSER_NO_INTERACTION=1

RUN set -ex \
    && apk add --update --no-cache \
    freetype \
    libpng \
    libjpeg-turbo \
    freetype-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    libxml2-dev \
    autoconf \
    g++ \
    imagemagick \
    imagemagick-dev \
    libtool \
    make \
    pcre-dev \
    postgresql-dev \
    postgresql \
    libintl \
    icu \
    icu-dev \
    bash \
    jq \
    git \
    gzip \
    && docker-php-ext-configure gd \
    --with-freetype-dir=/usr/include/ \
    --with-png-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd soap zip intl pdo_pgsql \
    && pecl install imagick redis \
    && docker-php-ext-enable imagick redis \
    && rm -rf /tmp/pear \
    && apk del freetype-dev libpng-dev libjpeg-turbo-dev autoconf g++ libtool make pcre-dev

COPY ./php.ini /usr/local/etc/php/

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY ./run.sh /run.sh
RUN chmod +x /run.sh \
    && chown www-data:www-data /run.sh

WORKDIR /var/www/html
RUN chown -R www-data:www-data .
USER www-data

# Install Craft CMS and save original dependencies in file
RUN composer create-project craftcms/craft . \
    && cp composer.json composer.base

VOLUME [ "/var/www/html" ]

ENTRYPOINT [ "/run.sh" ]

CMD [ "docker-php-entrypoint", "php-fpm"]
