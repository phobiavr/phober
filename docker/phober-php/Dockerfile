# syntax=docker/dockerfile:1.7
FROM php:8.2-apache-bookworm

LABEL maintainer="Hikmat Abdukhaligov" \
      org.opencontainers.image.title="phober-php-apache" \
      org.opencontainers.image.description="PHP 8.2 + Apache image for Phober services (MySQL only)" \
      org.opencontainers.image.version="2.1.0"

ARG user=user
ARG uid=1000
ARG gid=1000

ENV DEBIAN_FRONTEND=noninteractive \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_NO_INTERACTION=1 \
    COMPOSER_HOME=/tmp/composer

# ---------------------------------------------------------------------------
# System dependencies + PHP extensions
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        unzip \
        zip \
        libbz2-dev \
        libfreetype6-dev \
        libicu-dev \
        libjpeg-dev \
        libpng-dev \
        libonig-dev \
        libxml2-dev \
        libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
        bcmath \
        bz2 \
        exif \
        gd \
        intl \
        mbstring \
        opcache \
        pcntl \
        pdo_mysql \
        sockets \
        zip \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# PHP runtime configuration
# ---------------------------------------------------------------------------
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# ---------------------------------------------------------------------------
# Apache configuration
# ---------------------------------------------------------------------------
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    && a2enmod rewrite headers expires deflate \
    && { \
        echo "ServerTokens Prod"; \
        echo "ServerSignature Off"; \
        echo "TraceEnable Off"; \
    } > /etc/apache2/conf-available/security-hardening.conf \
    && a2enconf security-hardening

# ---------------------------------------------------------------------------
# Composer
# ---------------------------------------------------------------------------
COPY --from=composer:2.7.7 /usr/bin/composer /usr/bin/composer

# ---------------------------------------------------------------------------
# Non-root user
# ---------------------------------------------------------------------------
RUN groupadd -g ${gid} ${user} \
    && useradd -u ${uid} -g ${gid} -m -s /bin/bash ${user} \
    && install -d -o ${user} -g ${user} /home/${user}/.composer /var/www/html

WORKDIR /var/www/html

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD curl -fsS http://127.0.0.1/ >/dev/null || exit 1

USER ${user}
