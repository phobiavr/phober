FROM php:8.1.0RC1-apache

LABEL maintainer="Hikmat Abdukhaligov"

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
    sudo \
    unzip \
    zip \
 && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd opcache sockets \
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

# Create a system user to run Composer and Artisan Commands
RUN mkdir -p /home/www-data/.composer \
 && chown -R www-data:www-data /home/www-data

# Set working directory
WORKDIR /var/www/html

# Change ownership of the working directory to www-data
RUN chown -R www-data:www-data /var/www/html

# Switch to the www-data user
USER www-data