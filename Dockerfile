# =============================================================================
# LAMP Stack - Custom UnRAID Docker Image
# Maintainer: Edd Case <github.com/EddCase>
# =============================================================================

# Base image: Official PHP 8.3 with Apache bundled
# https://hub.docker.com/_/php
FROM php:8.3-apache

# Image metadata labels
LABEL maintainer="EddCase <https://github.com/EddCase>" \
      version="1.0.1" \
      description="Custom LAMP stack for local WordPress/CMS development"

# =============================================================================
# SYSTEM PACKAGES
# =============================================================================

RUN apt-get update && apt-get install -y \
    # Zip libraries - needed for WordPress theme/plugin installs
    libzip-dev \
    zip \
    unzip \
    # Image handling - needed for WordPress media uploads
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    # Required by intl PHP extension
    libicu-dev \
    # Required by xml/soap PHP extensions
    libxml2-dev \
    # Required by mbstring PHP extension
    libonig-dev \
    # Required by curl PHP extension
    libcurl4-openssl-dev \
    # Used by Composer and various PHP packages
    git \
    curl \
    # Text editor - much more friendly than vi/vim!
    nano \
    # Midnight Commander - visual file manager for working inside the container
    mc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# PHP EXTENSIONS
# =============================================================================

RUN docker-php-ext-configure gd \
        --with-jpeg \
        --with-webp \
    && docker-php-ext-install -j$(nproc) \
        # GD - image processing (WordPress media handling)
        gd \
        # PDO and mysqli - database connectivity to MariaDB
        pdo \
        pdo_mysql \
        mysqli \
        # ZIP - needed for WordPress theme/plugin installs
        zip \
        # EXIF - reads image metadata (used by WordPress media library)
        exif \
        # OPcache - PHP bytecode caching, improves performance
        opcache \
        # intl - internationalisation support (needed by some CMSs)
        intl \
        # bcmath - arbitrary precision maths (needed by some plugins)
        bcmath \
        # soap - web services protocol, needed by some plugins/payment gateways
        soap \
        # xml - XML processing, needed by various CMSs
        xml \
        # mbstring - multi-byte string handling for non-English characters
        mbstring \
        # curl - PHP curl extension wrapper, needed by almost everything
        curl

# Install PECL extensions
RUN apt-get update && apt-get install -y \
        # Required by imagick for image processing
        libmagickwand-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    # imagick - more powerful image processing than GD
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    # redis - PHP extension for Redis connectivity (ready for future use)
    && pecl install redis \
    && docker-php-ext-enable redis \
    # xdebug - PHP debugger for development troubleshooting
    && pecl install xdebug \
    && docker-php-ext-enable xdebug

# =============================================================================
# COMPOSER
# =============================================================================

RUN curl -sS https://getcomposer.org/installer | php -- \
        --install-dir=/usr/local/bin \
        --filename=composer \
    && composer --version

# =============================================================================
# APACHE MODULES
# =============================================================================

RUN a2enmod rewrite \
    && a2enmod headers \
    && a2enmod ssl \
    && a2enmod vhost_alias

RUN echo "IncludeOptional /etc/apache2/sites-available/vhosts/*.conf" \
    >> /etc/apache2/apache2.conf

# =============================================================================
# UNRAID PERMISSIONS
# =============================================================================

ARG PUID=99
ARG PGID=100

ENV PUID=${PUID}
ENV PGID=${PGID}

RUN usermod -u ${PUID} www-data \
    # GID 100 already exists in Debian as 'users' group
    # Add www-data to that group rather than trying to create/modify it
    && (groupmod -g ${PGID} www-data 2>/dev/null || usermod -g ${PGID} www-data) \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# =============================================================================
# WEBROOT SETUP
# =============================================================================

WORKDIR /var/www/html

RUN mkdir -p \
        /var/www/html \
        /etc/apache2/sites-available/vhosts \
        /var/log/apache2 \
        /var/log/php \
    && chown -R www-data:www-data \
        /var/www/html \
        /etc/apache2/sites-available/vhosts \
        /var/log/apache2 \
        /var/log/php

# =============================================================================
# CONFIGURATION FILES
# =============================================================================

# Copy default website files into the image
# Stored at /var/www/defaults/ so entrypoint.sh can copy them
# into the webroot on first run without overwriting existing user files
COPY websites/default/ /var/www/defaults/

COPY config/php/php.ini /usr/local/etc/php/conf.d/custom.ini
COPY config/apache/httpd.conf /etc/apache2/conf-available/custom.conf
RUN a2enconf custom
COPY config/apache/vhosts/default.conf /etc/apache2/sites-available/vhosts/default.conf
RUN a2dissite 000-default.conf

# =============================================================================
# FINAL SETUP
# =============================================================================

ENV APACHE_DOCUMENT_ROOT=/var/www/html

EXPOSE 80
EXPOSE 443

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
