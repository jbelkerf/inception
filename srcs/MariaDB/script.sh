#!/bin/bash

# Ensure directory exists and has right permissions
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# Start MariaDB in background to allow configuration
# --skip-networking allows us to login without passwords initially
mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &

# Wait for MariaDB to be ready (The "Chicken and Egg" fix)
while ! mariadb-admin ping --silent; do
    sleep 1
done

# Run the SQL commands
# In a real project, use variables like $MYSQL_USER from your .env file
mariadb -e "CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;"
mariadb -e "CREATE USER IF NOT EXISTS \`${SQL_USER}\`@'%' IDENTIFIED BY '${SQL_PASSWORD}';"
mariadb -e "GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO \`${SQL_USER}\`@'%';"
mariadb -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';"
mariadb -e "FLUSH PRIVILEGES;"

# Shutdown the background process safely
mysqladmin -u root -p${SQL_ROOT_PASSWORD} shutdown

# Final step: Start MariaDB in the foreground (PID 1)
# This keeps the container alive
exec mysqld --user=mysql --datadir=/var/lib/mysql