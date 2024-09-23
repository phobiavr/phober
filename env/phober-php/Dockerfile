FROM php:8.2-apache

LABEL maintainer="Hikmat Abdukhaligov"

# Default user and group
ARG user=user
ARG uid=1000
ARG gid=1000

# Oracle Instant Client Download links
ENV INSTANTCLIENT "https://download.oracle.com/otn_software/linux/instantclient/2112000/instantclient-basic-linux.x64-21.12.0.0.0dbru.zip"
ENV INSTANTCLIENT_SDK "https://download.oracle.com/otn_software/linux/instantclient/2112000/instantclient-sdk-linux.x64-21.12.0.0.0dbru.zip"
ENV SQLPLUS "https://download.oracle.com/otn_software/linux/instantclient/2112000/instantclient-sqlplus-linux.x64-21.12.0.0.0dbru.zip"

# Oracle Instant Client ENV Variables
ENV LD_LIBRARY_PATH "/opt/oracle/instantclient"
ENV PATH "$PATH:$LD_LIBRARY_PATH"

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    curl \
    g++ \
    git \
    libbz2-dev \
    libfreetype6-dev \
    libicu-dev \
    libjpeg-dev \
    libmcrypt-dev \
    libpng-dev \
    libreadline-dev \
    libonig-dev \
    libxml2-dev \
    libpq-dev \
    libaio1 \
    sudo \
    unzip \
    zip \
    gnupg2 \
    apt-transport-https \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update && ACCEPT_EULA=Y apt-get install -y \
        msodbcsql17 \
        unixodbc-dev \
        libgssapi-krb5-2 \
    && pecl install sqlsrv pdo_sqlsrv \
    && docker-php-ext-enable sqlsrv pdo_sqlsrv \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql mbstring exif pcntl bcmath gd opcache sockets \
    && curl -L $INSTANTCLIENT -o /tmp/instantclient-basic.zip \
    && curl -L $INSTANTCLIENT_SDK -o /tmp/instantclient-sdk.zip \
    && curl -L $SQLPLUS -o /tmp/instantclient-sqlplus.zip \
    && mkdir -p /opt/oracle \
    && unzip /tmp/instantclient-basic.zip -d /opt/oracle/ \
    && unzip /tmp/instantclient-sdk.zip -d /opt/oracle/ \
    && unzip /tmp/instantclient-sqlplus.zip -d /opt/oracle/ \
    && rm /tmp/instantclient-*.zip \
    && mv /opt/oracle/instantclient_* /opt/oracle/instantclient \
    && echo /opt/oracle/instantclient > /etc/ld.so.conf.d/oracleinstantclient.conf \
    && ldconfig \
    && echo 'instantclient,/opt/oracle/instantclient' | pecl install oci8 \
    && docker-php-ext-enable oci8 \
    && rm -rf /var/lib/apt/lists/*

# Configure Apache Document Root
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Enable Apache mod_rewrite and mod_headers
RUN a2enmod rewrite headers

# Use the default development configuration
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create a system group and user to run Composer and Artisan Commands
RUN groupadd -g ${gid} ${user} \
    && useradd -u ${uid} -g ${gid} -m -s /bin/bash ${user} \
    && mkdir -p /home/${user}/.composer \
    && chown -R ${user}:${user} /home/${user}

# Set working directory
WORKDIR /var/www/html

# Change ownership of the working directory to user
RUN chown -R ${user}:${user} /var/www/html

# Switch to the user
USER ${user}
