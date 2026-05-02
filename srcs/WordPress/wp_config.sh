#!/bin/bash

# This is the "Patience" loop
while ! mariadb-admin ping -h"mariadb" -uroot -p"${SQL_ROOT_PASSWORD}" --silent; do
    echo "WordPress waiting for MariaDB to wake up..."
    sleep 2
done

echo "MariaDB is up! Configuring WordPress..."
cd /var/www/html

if [ ! -f /var/www/html/wp_config.php ]; then
    # 1. Download WordPress
    
    wp core download --allow-root

    # 2. Create wp-config.php
    # WORDPRESS_DB_HOST should be the name of your mariadb service in docker-compose
    wp config create --allow-root \
        --dbname=$SQL_DATABASE \
        --dbuser=$SQL_USER \
        --dbpass=$SQL_PASSWORD \
        --dbhost=mariadb:3306 --path='/var/www/html'

    # 3. Install WordPress (Creates the Admin user)
    wp core install --allow-root \
        --url=$DOMAIN_NAME \
        --title=$SITE_TITLE \
        --admin_user=$ADMIN_USER \
        --admin_password=$ADMIN_PASSWORD \
        --admin_email=$ADMIN_EMAIL

    # 4. Create the mandatory regular user
    wp user create --allow-root \
        $USER_LOGIN $USER_EMAIL --role=author --user_pass=$USER_PASSWORD
    
fi

# Ensure the directory is owned by www-data
chown -R www-data:www-data /var/www/html

# Create the PID directory for PHP
mkdir -p /run/php

# Start PHP-FPM in foreground
echo "WordPress started on port 9000"
exec /usr/sbin/php-fpm8.2 -F