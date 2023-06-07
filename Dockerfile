FROM php:7.1-fpm-alpine3.10
LABEL maintainer="Darsey Litzenberger <dlitz@dlitz.net>"
LABEL org.opencontainers.image.source https://github.com/dlitz/docker-partkeepr

ENV PARTKEEPR_VERSION=1.4.0 APP_HOME=/partkeepr
WORKDIR $APP_HOME

RUN \
    apk update && \
    apk add --no-cache \
        nginx \
        nano \
        sudo \
        zip \
        unzip \
        libpng-dev \
        libmcrypt-dev \
        libpq \
        zlib-dev \
        icu-dev \
        curl-dev \
        gnutls-dev \
        libxml2-dev \
        postgresql-dev \
        ldb-dev \
        openldap-dev \
        freetype-dev \
        jpeg-dev \
        libjpeg \
        libldap && \
    \
    docker-php-ext-configure ldap && \
    docker-php-ext-configure bcmath && \ 
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --enable-gd-native-ttf && \
    docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd && \
    docker-php-ext-install -j "$(nproc)" \
        ldap \
        gd \
        intl \
        bcmath \
        mbstring \
        mcrypt \
        pcntl \
        dom \
        pdo \
        pdo_mysql \
        pdo_pgsql \
        pgsql \
        zip \
        opcache && \
    \
    mkdir -p $APP_HOME /run/nginx/ && \
    sed -E \
        's|;date.timezone =|date.timezone = UTC|; \
         s|max_execution_time = .*|max_execution_time = 72000|; \
         s|memory_limit = .*|memory_limit = 512M|' \
     /usr/local/etc/php/php.ini-production > /usr/local/etc/php/php.ini && \
    curl \
        -o /tmp/partkeepr.tbz2 \
        -L https://downloads.partkeepr.org/partkeepr-${PARTKEEPR_VERSION}.tbz2 && \
    chown -R www-data:www-data $APP_HOME /tmp/partkeepr.tbz2

RUN apk add --update --no-cache --virtual .build-dependencies $PHPIZE_DEPS \
        && pecl install apcu apcu_bc \
        && docker-php-ext-enable --ini-name 0-apc.ini apcu apc \
        && pecl clear-cache \
        && apk del .build-dependencies

COPY config/nginx.conf /etc/nginx/conf.d/default.conf
COPY config/crontab /etc/partkeepr.cron
COPY php /usr/local/etc/php
COPY scripts /usr/local/bin

EXPOSE 80
