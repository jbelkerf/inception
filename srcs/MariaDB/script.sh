#!/bin/bash

# 1. Setup directories
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

# 2. Check if the database is already initialized
if [ ! -d "/var/lib/mysql/mysql" ]; then

    echo "First time setup: Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

    # 3. Create a temporary SQL file with all your commands
    # We use 'EOF' to handle multiple lines easily
    cat << EOF > /tmp/setup.sql
USE mysql;
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;
CREATE USER IF NOT EXISTS \`${SQL_USER}\`@'%' IDENTIFIED BY '${SQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO \`${SQL_USER}\`@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    # 4. THE MAGIC STEP: Run MariaDB in bootstrap mode
    # This reads the SQL file, applies it to the data files, and exits immediately.
    echo "Applying configuration via bootstrap..."
    mysqld --user=mysql --datadir=/var/lib/mysql --bootstrap < /tmp/setup.sql
    
    rm -f /tmp/setup.sql
fi

# 5. Final step: Start MariaDB normally in the foreground
echo "Starting MariaDB normally..."
exec mysqld --user=mysql --datadir=/var/lib/mysql