#!/bin/bash

# 1. Setup directories and permissions
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

# 2. Only initialize if this is a fresh volume
if [ ! -d "/var/lib/mysql/${SQL_DATABASE}" ]; then

    echo "First time setup: Initializing MariaDB data directory..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null

    # 3. Start MariaDB temporarily (no networking, local socket only)
    echo "Starting MariaDB temporarily for setup..."
    mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
    MYSQL_PID=$!

    # 4. Wait until MariaDB is ready
    echo "Waiting for MariaDB to be ready..."
    while ! mariadb-admin ping --silent 2>/dev/null; do
        sleep 1
    done

    # 5. Run setup SQL
    echo "Applying configuration..."
    mariadb -u root << SQLEOF
USE mysql;
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${SQL_USER}'@'%' IDENTIFIED BY '${SQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO '${SQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
SQLEOF

    # 6. Cleanly shut down the temporary instance
    echo "Shutting down temporary MariaDB..."
    mysqladmin -u root shutdown
    wait $MYSQL_PID
    echo "Setup complete."
fi

# 7. Start MariaDB normally as PID 1
echo "Starting MariaDB normally..."
exec mysqld --user=mysql --datadir=/var/lib/mysql
