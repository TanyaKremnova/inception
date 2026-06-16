#!/bin/bash
set -e

# Create socket directory — MariaDB needs this
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# Read passwords
DB_PASSWORD=${DB_PASSWORD:-$(cat /run/secrets/db_password 2>/dev/null)}
DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD:-$(cat /run/secrets/db_root_password 2>/dev/null)}

if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    mysqld --user=mysql --bootstrap << EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
CREATE USER IF NOT EXISTS '${MYSQL_ADMIN_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_ADMIN_USER}'@'%';
FLUSH PRIVILEGES;
EOF
fi

exec mysqld --user=mysql
