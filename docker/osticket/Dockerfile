FROM php:8.3-apache

ARG OSTICKET_VERSION=v1.18.4

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libzip-dev \
    libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        mysqli \
        pdo_mysql \
        gd \
        intl \
        zip \
        opcache \
    && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

RUN curl -L \
    https://github.com/osTicket/osTicket/archive/refs/tags/${OSTICKET_VERSION}.tar.gz \
    -o /tmp/osticket.tar.gz \
    && tar -xzf /tmp/osticket.tar.gz \
    --strip-components=1 \
    -C /var/www/html \
    && rm /tmp/osticket.tar.gz

RUN cp include/ost-sampleconfig.php include/ost-config.php \
    && chown -R www-data:www-data /var/www/html \
    && chmod 0660 include/ost-config.php

COPY php.ini /usr/local/etc/php/conf.d/osticket.ini

EXPOSE 80

CMD []
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]