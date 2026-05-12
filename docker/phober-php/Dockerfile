# syntax=docker/dockerfile:1.7
FROM php:8.2-apache-bookworm

LABEL maintainer="Hikmat Abdukhaligov" \
      org.opencontainers.image.title="phober-php-apache" \
      org.opencontainers.image.description="PHP 8.2 + Apache image for Phober services (MySQL only)" \
      org.opencontainers.image.version="2.0.0"

# Default non-root user
ARG user=user
ARG uid=1000
ARG gid=1000

# Pinned Composer version for reproducible builds
ARG composer_version=2.7.7

# Build-time tuning
ENV DEBIAN_FRONTEND=noninteractive \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_NO_INTERACTION=1 \
    COMPOSER_HOME=/tmp/composer \
    PHP_MEMORY_LIMIT=512M \
    PHP_OPCACHE_MEMORY_CONSUMPTION=192 \
    PHP_OPCACHE_MAX_ACCELERATED_FILES=20000 \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS=0

# ---------------------------------------------------------------------------
# System dependencies + PHP extensions
# ---------------------------------------------------------------------------
# Split into build-deps (purged after compile) and run-deps (kept) to shrink
# the final image. BuildKit cache mounts speed up repeated builds.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -eux; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
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
        libzip-dev; \
    \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-configure opcache --enable-opcache; \
    docker-php-ext-install -j"$(nproc)" \
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
        zip; \
    \
    # Re-mark only what is actually needed at runtime, then purge build-deps.
    apt-mark auto '.*' > /dev/null; \
    [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; \
    find /usr/local/lib/php/extensions -type f -name '*.so' -exec \
        ldd '{}' ';' \
        | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); print so }' \
        | sort -u \
        | xargs -r dpkg-query --search 2>/dev/null \
        | cut -d: -f1 \
        | sort -u \
        | xargs -r apt-mark manual; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# PHP runtime configuration
# ---------------------------------------------------------------------------
RUN set -eux; \
    mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"; \
    { \
        echo "memory_limit=\${PHP_MEMORY_LIMIT}"; \
        echo "expose_php=Off"; \
        echo "upload_max_filesize=64M"; \
        echo "post_max_size=64M"; \
        echo "date.timezone=UTC"; \
    } > "$PHP_INI_DIR/conf.d/zz-phober.ini"; \
    { \
        echo "opcache.enable=1"; \
        echo "opcache.enable_cli=1"; \
        echo "opcache.memory_consumption=\${PHP_OPCACHE_MEMORY_CONSUMPTION}"; \
        echo "opcache.interned_strings_buffer=16"; \
        echo "opcache.max_accelerated_files=\${PHP_OPCACHE_MAX_ACCELERATED_FILES}"; \
        echo "opcache.validate_timestamps=\${PHP_OPCACHE_VALIDATE_TIMESTAMPS}"; \
        echo "opcache.revalidate_freq=2"; \
        echo "opcache.jit_buffer_size=64M"; \
        echo "opcache.jit=tracing"; \
    } > "$PHP_INI_DIR/conf.d/zz-opcache.ini"

# ---------------------------------------------------------------------------
# Apache configuration
# ---------------------------------------------------------------------------
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN set -eux; \
    sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf; \
    sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf; \
    a2enmod rewrite headers expires deflate; \
    { \
        echo "ServerTokens Prod"; \
        echo "ServerSignature Off"; \
        echo "TraceEnable Off"; \
    } > /etc/apache2/conf-available/security-hardening.conf; \
    a2enconf security-hardening

# ---------------------------------------------------------------------------
# Composer
# ---------------------------------------------------------------------------
COPY --from=composer:2.7.7 /usr/bin/composer /usr/bin/composer

# ---------------------------------------------------------------------------
# Non-root user
# ---------------------------------------------------------------------------
RUN set -eux; \
    groupadd -g ${gid} ${user}; \
    useradd -u ${uid} -g ${gid} -m -s /bin/bash ${user}; \
    install -d -o ${user} -g ${user} /home/${user}/.composer /var/www/html

WORKDIR /var/www/html

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD curl -fsS http://127.0.0.1/ >/dev/null || exit 1

USER ${user}
