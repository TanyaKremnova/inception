#!/bin/bash
set -e

# Read passwords from Docker secrets or env vars
DB_PASSWORD=${DB_PASSWORD:-$(cat /run/secrets/db_password 2>/dev/null)}
DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD:-$(cat /run/secrets/db_root_password 2>/dev/null)}

# Initialize data directory if empty (first run)
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    # Start MariaDB temporarily to run setup
    mysqld --user=mysql --bootstrap << EOF
FLUSH PRIVILEGES;

-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';

-- Create the WordPress database
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

-- Create regular WP user
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

-- Create admin user (name must not contain admin/Admin/administrator)
CREATE USER IF NOT EXISTS '${MYSQL_ADMIN_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_ADMIN_USER}'@'%';

FLUSH PRIVILEGES;
EOF
fi

# Hand off to MariaDB as PID 1 — this is the main process
exec mysqld --user=mysql