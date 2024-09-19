#!/bin/sh

# Run the artisan command with the container name
php /var/www/html/artisan hostname:update "$1"

# Start Apache in the foreground
apache2 -D FOREGROUND

