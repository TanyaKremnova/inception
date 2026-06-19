#!/bin/bash
set -e

DB_PASSWORD=${DB_PASSWORD}
WP_DIR="/var/www/html"

if [ ! -f "${WP_DIR}/wp-login.php" ]; then
    echo ">>> Downloading WordPress..."
    wp core download \
        --path="${WP_DIR}" \
        --allow-root
fi

if [ ! -f "${WP_DIR}/wp-config.php" ]; then

    echo ">>> Creating wp-config.php..."
    wp config create \
        --path="${WP_DIR}" \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost="mariadb:3306" \
        --skip-check \
        --allow-root

    wp config set WP_HOME "https://tkremnov.42.fr:8443" --path=/var/www/html --allow-root
    wp config set WP_SITEURL "https://tkremnov.42.fr:8443" --path=/var/www/html --allow-root

    echo ">>> Waiting for MariaDB to be ready..."
    until mysqladmin ping -h mariadb -u"${MYSQL_USER}" -p"${DB_PASSWORD}" --silent 2>/dev/null; do
        echo "    Not ready, retrying in 2s..."
        sleep 2
    done

    echo ">>> Installing WordPress..."
    wp core install \
        --path="${WP_DIR}" \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="${MYSQL_ADMIN_USER}" \
        --admin_password="${DB_PASSWORD}" \
        --admin_email="admin@${DOMAIN_NAME}" \
        --allow-root

    echo ">>> Creating regular user..."
    wp user create \
        "${MYSQL_USER}" \
        "user@${DOMAIN_NAME}" \
        --role=author \
        --user_pass="${DB_PASSWORD}" \
        --path="${WP_DIR}" \
        --allow-root

    chown -R www-data:www-data "${WP_DIR}"

fi

echo ">>> Starting php-fpm..."
exec /usr/sbin/php-fpm8.2 --nodaemonize