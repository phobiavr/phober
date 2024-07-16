FROM php:8.1.0RC1-apache

LABEL maintainer="Hikmat Abdukhaligov"

# Arguments defined in docker-compose.yml
ARG user
ARG uid

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
RUN mkdir -p /home/$user/.composer \
 && chown -R $user:$user /home/$user

# Set working directory
WORKDIR /var/www/html

# Change ownership of the working directory to $user
RUN chown -R $user:$user /var/www/html

# Switch to the $user user
USER $user