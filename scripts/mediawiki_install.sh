#!/bin/bash

# Update the system and install wget, gnupg, and mariadb-server
sudo dnf update -y
sudo dnf install -y wget gnupg mariadb-server firewalld

# Start MariaDB
sudo systemctl start mariadb

# Set the root password to "root" and run mysql_secure_installation
sudo mysqladmin -u root password 'root'
sudo mysql_secure_installation <<SECURE_INSTALL
root
root
n
n
n
n
n
SECURE_INSTALL

# Log into MySQL client and create wiki user and database
sudo mysql -u root -proot <<MYSQL_SCRIPT
  CREATE USER 'wiki'@'localhost' IDENTIFIED BY 'THISpasswordSHOULDbeCHANGED';
  CREATE DATABASE wikidatabase;
  GRANT ALL PRIVILEGES ON wikidatabase.* TO 'wiki'@'localhost';
  FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Enable autostart for MariaDB
sudo systemctl enable mariadb

# Install required packages
sudo dnf install httpd php php-mysqlnd php-gd php-xml mariadb-server mariadb php-mbstring php-json mod_ssl php-intl php-apcu

# Start MariaDB and Apache on boot
sudo systemctl enable mariadb
sudo systemctl enable httpd

# Download and install MediaWiki
cd /var/www
sudo wget https://releases.wikimedia.org/mediawiki/1.41/mediawiki-1.41.0.tar.gz
sudo wget https://releases.wikimedia.org/mediawiki/1.41/mediawiki-1.41.0.tar.gz.sig
gpg --keyserver hkp://keys.gnupg.net --recv-keys 7D73C8608C64D1DD
gpg --verify mediawiki-1.41.0.tar.gz.sig mediawiki-1.41.0.tar.gz
sudo tar -zxf mediawiki-1.41.0.tar.gz
sudo ln -s mediawiki-1.41.0/ mediawiki
sudo chown -R apache:apache /var/www/mediawiki-1.41.0

# Configure Apache
sudo sed -i 's|DocumentRoot "/var/www/html"|DocumentRoot "/var/www"|' /etc/httpd/conf/httpd.conf
sudo sed -i 's|<Directory "/var/www/html">|<Directory "/var/www">|' /etc/httpd/conf/httpd.conf
sudo sed -i 's|DirectoryIndex index.html| DirectoryIndex index.html index.html.var index.php|' /etc/httpd/conf/httpd.conf

# Restart Apache
sudo systemctl restart httpd

# Firewall configuration using firewalld
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --permanent --zone=public --add-service=http
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo systemctl restart firewalld

# SELinux configuration
sudo restorecon -FR /var/www/mediawiki-1.41.0/  # Check the status of services
echo "Checking MariaDB status:"
sudo systemctl status mariadb

echo "Checking Apache status:"
sudo systemctl status httpd

echo "Checking PHP status:"
php -v

# Display completion message
echo "MediaWiki installation completed. Access your wiki at http://<your-ec2-public-ip>/mediawiki"

