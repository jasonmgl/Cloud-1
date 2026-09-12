#!/bin/bash

set -euo pipefail

mkdir -p /var/www/html
cd /var/www/html

wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

sleep 10

if [ ! -e /var/www/html/.wp_init_done ]; then
        [ -e wp-load.php ] || wp core download --allow-root

        [ -e wp-config.php ] || wp core config \
            --dbname="${SQL_DATABASE}" \
            --dbuser="${SQL_USER}" \
            --dbpass="${SQL_PASSWORD}" \
            --dbhost='mariadb:3306' \
            --allow-root

        wp core is-installed --allow-root || wp core install \
            --url="https://${DOMAIN_NAME}" \
            --title="${SITE_TITLE}" \
            --admin_user="${WP_ADMIN}" \
            --admin_password="${WP_ADMIN_PASSWORD}" \
            --admin_email="${WP_ADMIN_EMAIL}" \
            --allow-root

        wp user get "${WP_USER}" --allow-root >/dev/null 2>&1 || wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
            --role=author \
            --user_pass="${WP_USER_PASSWORD}" \
            --allow-root

        wp theme install "${WP_THEME}" --activate --allow-root

        touch /var/www/html/.wp_init_done
fi

# Keep mutable WordPress settings in sync on every boot; never fail startup over these
if wp core is-installed --allow-root; then
    current_title="$(wp option get blogname --allow-root 2>/dev/null || true)"
    if [ "${current_title}" != "${SITE_TITLE}" ]; then
        wp option update blogname "${SITE_TITLE}" --allow-root || echo "Warning: failed to update site title"
    fi

    current_theme="$(wp theme list --status=active --field=name --allow-root 2>/dev/null || true)"
    if [ "${current_theme}" != "${WP_THEME}" ]; then
        wp theme install "${WP_THEME}" --activate --allow-root || echo "Warning: failed to set theme"
    fi
fi


# Set ownership and permissions
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;
# Set wp-content to writable (for redis cache)
chown -R www-data:www-data /var/www/html/wp-content
chmod -R 775 /var/www/html/wp-content

mkdir -p /run/php
chown www-data:www-data /run/php
chmod 755 /run/php

exec /usr/sbin/php-fpm8.4 -F
