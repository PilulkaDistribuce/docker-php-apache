# base image for most pilulka.cz web based projects
FROM php:7.1-apache

MAINTAINER martin krizan <martin.krizan@pilulka.cz>

RUN apt-get -y update

RUN apt-get install -y \
    git \
    wget \
    libmcrypt-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libxml2-dev \
    libedit-dev \
    libicu-dev \
    libssl-dev \
    freetds-dev \
    libc-client-dev \
    libkrb5-dev \
    uuid-dev

RUN docker-php-ext-install -j$(nproc) mcrypt \
    && docker-php-ext-configure gd --with-jpeg-dir=/usr/include/ \
        --with-png-dir=/usr/include --with-freetype-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) soap \
    && docker-php-ext-install -j$(nproc) pdo_mysql \
    && docker-php-ext-install -j$(nproc) mysqli \
    && docker-php-ext-install -j$(nproc) intl \
    && docker-php-ext-install -j$(nproc) pcntl \
    && docker-php-ext-install -j$(nproc) zip \
    && docker-php-ext-install -j$(nproc) calendar \
    && docker-php-ext-install -j$(nproc) xmlrpc \
    && docker-php-ext-install -j$(nproc) sysvsem \
    && docker-php-ext-install -j$(nproc) bcmath \
    && docker-php-ext-configure pdo_dblib --with-libdir=/lib/x86_64-linux-gnu \
    && docker-php-ext-install -j$(nproc) pdo_dblib

# Install PHP extensions
RUN docker-php-ext-install zip mbstring opcache && \
    pecl install apcu-5.1.5 && \
    echo extension=apcu.so > /usr/local/etc/php/conf.d/apcu.ini && \
    pecl install uuid && \
    echo extension=uuid.so > /usr/local/etc/php/conf.d/uuid.ini

# Imap
RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap

# ZMQ
RUN apt-get -y install libzmq-dev \
    && pecl install zmq-1.1.3 \
    && docker-php-ext-enable zmq

# RAR
RUN  pecl install rar \
    && docker-php-ext-enable rar

# Redis
RUN pecl install -o -f redis \
    && docker-php-ext-enable redis
# Data Structures
RUN pecl install -o -f ds \
    && docker-php-ext-enable ds

# Blackfire
RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/$version \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp \
    && mv /tmp/blackfire-*.so $(php -r "echo ini_get('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8707\n" > $PHP_INI_DIR/conf.d/blackfire.ini

# XDebug
RUN pecl install xdebug
RUN docker-php-ext-enable xdebug
RUN echo "xdebug.remote_enable=1" >> /usr/local/etc/php/php.ini

# MongoDB
RUN pecl install mongodb
RUN docker-php-ext-enable mongodb

# Supervisor
RUN apt-get install -y supervisor

# Composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# clean for keep up small image
RUN docker-php-source delete \
    && apt-get -y autoclean \
    && apt-get -y autoremove \
    && rm -rf /tmp/* /var/tmp/*

RUN a2enmod rewrite
