#!/bin/bash

# Check if the required environment variables are set
if  [ -z "$SQL_ROOT_PASSWORD" ] || [ -z "$SQL_USER" ] || [ -z "$SQL_PASSWORD" ] || [ -z "$SQL_DATABASE" ]; then
	echo "Missing environment variables";
	exit 1;
fi

# Initialize the MySQL data directory and create the system tables
# --user : The user that will own the data directory
# --datadir : The directory where the data will be stored
mysql_install_db --user=mysql --datadir=/var/lib/mysql

mkdir -p /run/mysqld /var/lib/mysql
mkdir -p /run/mysql
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

# Start the MySQL server
mysqld --user=mysql --datadir=/var/lib/mysql &
# Get the pid of the MySQL server
pid=$!

# Wait for the database to start
until mysqladmin ping -u root -p${SQL_ROOT_PASSWORD} >/dev/null 2>&1; do
	echo "Waiting for MariaDB to start...";
	sleep 1;
done

# Create the database and user
mysql -u root -p${SQL_ROOT_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;"
mysql -u root -p${SQL_ROOT_PASSWORD} -e "CREATE USER IF NOT EXISTS '${SQL_USER}' IDENTIFIED BY '${SQL_PASSWORD}';"
mysql -u root -p${SQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON *.* TO '${SQL_USER}';"
# Activate the changes
mysql -u root -p${SQL_ROOT_PASSWORD} -e "FLUSH PRIVILEGES;"
# Set the root password
mysql -u root -p${SQL_ROOT_PASSWORD} -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';"

# Shutdown the database and restart it on foreground
kill "$pid"
wait "$pid"
exec mysqld --user=mysql
